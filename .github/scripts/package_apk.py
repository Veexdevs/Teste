#!/usr/bin/env python3
"""Repackage the imported binary APK resources without decompiling or editing code."""
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import zipfile

ROOT_PREFIX = "8Ball-Pool-Android-V2-5/"
STORED_SUFFIXES = {
    ".arsc", ".so", ".apk", ".zip", ".gz", ".png", ".jpg", ".jpeg", ".webp",
    ".mp3", ".ogg", ".mp4", ".woff", ".woff2",
}
SIGNATURE_SUFFIXES = {".rsa", ".dsa", ".ec", ".sf"}


def main():
    repo = Path.cwd()
    manifest = json.loads((repo / ".github/import-manifest.json").read_text(encoding="utf-8"))
    output = Path(os.environ["RUNNER_TEMP"]) / "8Ball-Pool-Android-V2-5-unsigned.apk"
    included = 0
    skipped_signatures = []
    total = 0
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6, allowZip64=True) as apk:
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
            if (len(path.parts) == 2 and path.parts[0] == "META-INF"
                    and (path.suffix.lower() in SIGNATURE_SUFFIXES or path.name.upper() == "MANIFEST.MF")):
                skipped_signatures.append(relative)
                continue
            source = repo / relative
            if source.stat().st_size != entry["size"]:
                raise RuntimeError(f"File size differs from verified ZIP: {relative}")
            method = zipfile.ZIP_STORED if path.suffix.lower() in STORED_SUFFIXES else zipfile.ZIP_DEFLATED
            info = zipfile.ZipInfo(relative, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = method
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            with source.open("rb") as stream, apk.open(info, "w") as target:
                while True:
                    block = stream.read(4 * 1024 * 1024)
                    if not block:
                        break
                    target.write(block)
            included += 1
            total += entry["size"]
    if included < 5000 or total != manifest["uncompressed_size"] - sum(
            entry["size"] for entry in manifest["entries"]
            if not entry["directory"] and entry["path"].removeprefix(ROOT_PREFIX) in skipped_signatures):
        raise RuntimeError("APK packaging inventory verification failed.")
    with output.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    print(json.dumps({
        "files_packaged": included,
        "original_signature_entries_excluded_from_output_only": skipped_signatures,
        "source_bytes_packaged": total,
        "unsigned_apk_bytes": output.stat().st_size,
        "unsigned_sha256": digest,
        "source_code_modified": False,
    }, indent=2))
    print(f"Unsigned APK: {output}")


if __name__ == "__main__":
    main()
