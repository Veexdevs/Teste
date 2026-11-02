#!/usr/bin/env python3
"""Repackage binary APK entries and optionally preserve existing JAR signatures.

This script does not decompile, print, or modify application source code. It only
copies already-extracted binary entries into APK containers and reports metadata.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import zlib
import zipfile

ROOT_PREFIX = "8Ball-Pool-Android-V2-5/"
SIGNATURE_SUFFIXES = {".rsa", ".dsa", ".ec", ".sf"}
DEFAULT_STORED_SUFFIXES = {
    ".arsc", ".so", ".apk", ".zip", ".gz", ".png", ".jpg", ".jpeg", ".webp",
    ".mp3", ".ogg", ".mp4", ".woff", ".woff2",
}


def is_signature_entry(relative: str) -> bool:
    path = PurePosixPath(relative)
    return (
        len(path.parts) == 2
        and path.parts[0] == "META-INF"
        and (path.suffix.lower() in SIGNATURE_SUFFIXES or path.name.upper() == "MANIFEST.MF")
    )


def file_crc_and_sha256(path: Path):
    crc = 0
    digest = hashlib.sha256()
    size = 0
    with path.open("rb") as stream:
        while True:
            block = stream.read(4 * 1024 * 1024)
            if not block:
                break
            size += len(block)
            crc = zlib.crc32(block, crc)
            digest.update(block)
    return size, crc & 0xFFFFFFFF, digest.hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--preserve-v1", action="store_true")
    parser.add_argument("--source-code-modified", action="store_true")
    parser.add_argument("--output", required=True)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()

    repo = Path.cwd()
    manifest = json.loads((repo / ".github/import-manifest.json").read_text(encoding="utf-8"))
    origin_path = repo / "assets/SignatureKiller/origin.apk"
    output = Path(args.output)
    report_path = Path(args.report)
    output.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    entries = []
    for entry in manifest["entries"]:
        if entry["directory"]:
            continue
        normalized = entry["path"].replace("\\", "/")
        if not normalized.startswith(ROOT_PREFIX):
            raise RuntimeError("Unexpected path in verified inventory.")
        relative = normalized[len(ROOT_PREFIX):]
        path = PurePosixPath(relative)
        if path.is_absolute() or ".." in path.parts:
            raise RuntimeError("Unsafe APK entry path.")
        if not args.preserve_v1 and is_signature_entry(relative):
            continue
        entries.append((relative, entry))

    origin_infos = {}
    origin_order = []
    if origin_path.exists() and origin_path.stat().st_size > 1000:
        with zipfile.ZipFile(origin_path) as origin:
            for info in origin.infolist():
                if info.is_dir():
                    continue
                origin_infos[info.filename] = info
                origin_order.append(info.filename)
    else:
        raise RuntimeError("Original APK asset is missing or is an LFS pointer.")

    entry_map = {relative: entry for relative, entry in entries}
    ordered = [name for name in origin_order if name in entry_map]
    ordered_set = set(ordered)
    ordered.extend(relative for relative, _ in entries if relative not in ordered_set)

    included = 0
    total = 0
    same_crc = []
    changed_crc = []
    added = []
    removed = []
    output_hashes = {}
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6, allowZip64=True) as apk:
        for relative in ordered:
            entry = entry_map[relative]
            source = repo / relative
            size, crc, sha256 = file_crc_and_sha256(source)
            if size != entry["size"]:
                raise RuntimeError(f"File size differs from verified ZIP: {relative}")
            origin_info = origin_infos.get(relative)
            if origin_info is None:
                added.append(relative)
                method = zipfile.ZIP_STORED if PurePosixPath(relative).suffix.lower() in DEFAULT_STORED_SUFFIXES else zipfile.ZIP_DEFLATED
                date_time = (1980, 1, 1, 0, 0, 0)
            else:
                if origin_info.CRC == crc and origin_info.file_size == size:
                    same_crc.append(relative)
                else:
                    changed_crc.append(relative)
                method = origin_info.compress_type
                date_time = origin_info.date_time
            info = zipfile.ZipInfo(relative, date_time=date_time)
            info.compress_type = method
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            # writestr writes complete local-header CRC/size fields and avoids
            # ZIP data descriptors (flag bit 3), which some native APK/ZIP
            # readers used by signature/integrity hooks do not handle.
            apk.writestr(info, source.read_bytes())
            output_hashes[relative] = sha256
            included += 1
            total += size

    for name in origin_infos:
        if name not in entry_map and not is_signature_entry(name):
            removed.append(name)

    if included < 5000:
        raise RuntimeError("APK packaging inventory verification failed.")

    with output.open("rb") as stream:
        output_digest = hashlib.file_digest(stream, "sha256").hexdigest()
    origin_size, origin_crc, origin_sha256 = file_crc_and_sha256(origin_path)
    with zipfile.ZipFile(output) as check:
        data_descriptor_count = sum(1 for i in check.infolist() if i.flag_bits & 0x8)
    with zipfile.ZipFile(origin_path) as check:
        origin_data_descriptor_count = sum(1 for i in check.infolist() if i.flag_bits & 0x8)

    report = {
        "mode": "preserve-v1" if args.preserve_v1 else "release-unsigned",
        "source_code_modified": bool(args.source_code_modified),
        "files_packaged": included,
        "source_bytes_packaged": total,
        "output_bytes": output.stat().st_size,
        "output_sha256": output_digest,
        "zip_data_descriptor_entries": data_descriptor_count,
        "original_asset_zip_data_descriptor_entries": origin_data_descriptor_count,
        "original_asset": {
            "path": "assets/SignatureKiller/origin.apk",
            "size": origin_size,
            "sha256": origin_sha256,
        },
        "comparison_to_original_asset": {
            "same_crc_count": len(same_crc),
            "changed_crc_count": len(changed_crc),
            "added_count": len(added),
            "removed_count": len(removed),
            "changed_paths_sample": changed_crc[:200],
            "added_paths_sample": added[:200],
            "removed_paths_sample": removed[:200],
        },
    }
    report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in report.items() if k != "comparison_to_original_asset"}, indent=2))
    print(f"Comparison: same={len(same_crc)} changed={len(changed_crc)} added={len(added)} removed={len(removed)}")
    print(f"APK written to {output}")


if __name__ == "__main__":
    main()
