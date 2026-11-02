#!/usr/bin/env python3
"""Import the verified ZIP byte-for-byte without displaying or executing source code."""
import hashlib
import os
from pathlib import Path, PurePosixPath
import shutil
import stat
import urllib.request
import html
import re
import zipfile

from inspect_mediafire_zip import EXPECTED_SHA256, EXPECTED_SIZE, FILENAME, PAGE_URL, USER_AGENT
from inspect_mediafire_zip import get

ROOT_PREFIX = "8Ball-Pool-Android-V2-5/"


def digest_file(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main():
    with get(PAGE_URL) as response:
        page = response.read(4_000_000).decode("utf-8", errors="replace")
    links = re.findall(r'https://download[^\s"<>]*\.mediafire\.com/[^\s"<>]+', page)
    if not links:
        raise RuntimeError("MediaFire did not expose a download link.")
    archive_path = Path(os.environ["RUNNER_TEMP"]) / FILENAME
    size = 0
    digest = hashlib.sha256()
    with get(html.unescape(links[0])) as response, archive_path.open("wb") as output:
        while True:
            block = response.read(4 * 1024 * 1024)
            if not block:
                break
            size += len(block)
            if size > EXPECTED_SIZE:
                raise RuntimeError("Unexpected download size.")
            digest.update(block)
            output.write(block)
    if size != EXPECTED_SIZE or digest.hexdigest() != EXPECTED_SHA256:
        raise RuntimeError("MediaFire SHA-256/size verification failed.")

    repo = Path.cwd().resolve()
    with zipfile.ZipFile(archive_path) as archive:
        entries = archive.infolist()
        if len(entries) > 10000 or sum(info.file_size for info in entries) > 1_000_000_000:
            raise RuntimeError("Archive exceeds the import safety limits.")
        names = set()
        files = []
        for info in entries:
            normalized = info.filename.replace("\\", "/")
            path = PurePosixPath(normalized)
            mode = info.external_attr >> 16
            if path.is_absolute() or ".." in path.parts or not normalized.startswith(ROOT_PREFIX):
                raise RuntimeError(f"Unsafe archive path: {info.filename}")
            if stat.S_ISLNK(mode) or (mode and not (stat.S_ISREG(mode) or stat.S_ISDIR(mode))):
                raise RuntimeError(f"Unsupported archive entry type: {info.filename}")
            relative = normalized[len(ROOT_PREFIX):].rstrip("/")
            if not relative:
                continue
            key = relative.casefold()
            if key in names:
                raise RuntimeError(f"Duplicate archive path: {relative}")
            names.add(key)
            if ".git" in PurePosixPath(relative).parts or relative.startswith(".github/"):
                raise RuntimeError("Archive unexpectedly contains Git/CI metadata.")
            if not info.is_dir():
                files.append((info, relative))

        for info, relative in files:
            target = repo / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            with archive.open(info) as source, target.open("wb") as output:
                shutil.copyfileobj(source, output, 4 * 1024 * 1024)
            if target.stat().st_size != info.file_size:
                raise RuntimeError(f"Extracted size mismatch: {relative}")

    large_asset = repo / "assets/SignatureKiller/origin.apk"
    if large_asset.stat().st_size != 173845758:
        raise RuntimeError("The required large APK asset has an unexpected size.")
    attributes = repo / ".gitattributes"
    attributes.write_text(
        "/assets/SignatureKiller/origin.apk filter=lfs diff=lfs merge=lfs -text\n",
        encoding="utf-8",
    )
    print(f"Imported {len(files)} files without displaying or executing their source code.")
    print("The original 173,845,758-byte APK asset will be stored using Git LFS.")


if __name__ == "__main__":
    main()
