#!/usr/bin/env python3
"""Download and inventory a ZIP without displaying or executing its contents."""
import hashlib
import html
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import urllib.request
import zipfile

QUICK_KEY = "hm5cmxmbwhgtdec"
FILENAME = "8Ball-Pool-Android-V2-5.zip"
EXPECTED_SIZE = 360808535
EXPECTED_SHA256 = "a99e4cc9133ce386c14506962d5145bdad778e93b2eb8a3094849470e84d6576"
PAGE_URL = f"https://www.mediafire.com/download/{QUICK_KEY}/{FILENAME}"
USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/131.0.0.0 Safari/537.36"


def get(url):
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    return urllib.request.urlopen(request, timeout=180)


def main():
    with get(PAGE_URL) as response:
        page = response.read(4_000_000).decode("utf-8", errors="replace")
    links = re.findall(r'https://download[^\s"<>]*\.mediafire\.com/[^\s"<>]+', page)
    if not links:
        match = re.search(r'id=["\']downloadButton["\'][^>]*href=["\']([^"\']+)', page)
        if match:
            links = [match.group(1)]
    if not links:
        raise RuntimeError("MediaFire did not expose a download link to the runner.")
    download_url = html.unescape(links[0])
    destination = Path(os.environ["RUNNER_TEMP"]) / FILENAME
    digest = hashlib.sha256()
    size = 0
    with get(download_url) as response, destination.open("wb") as output:
        while True:
            block = response.read(4 * 1024 * 1024)
            if not block:
                break
            size += len(block)
            if size > EXPECTED_SIZE:
                raise RuntimeError("Download exceeds the size published by MediaFire.")
            digest.update(block)
            output.write(block)
    if size != EXPECTED_SIZE or digest.hexdigest() != EXPECTED_SHA256:
        raise RuntimeError(f"ZIP integrity mismatch: size={size}, sha256={digest.hexdigest()}")

    entries = []
    with zipfile.ZipFile(destination) as archive:
        for info in archive.infolist():
            path = PurePosixPath(info.filename.replace("\\", "/"))
            mode = info.external_attr >> 16
            entries.append({
                "path": info.filename,
                "size": info.file_size,
                "compressed_size": info.compress_size,
                "directory": info.is_dir(),
                "symlink": stat.S_ISLNK(mode),
                "unsafe_path": path.is_absolute() or ".." in path.parts,
            })

    file_entries = [entry for entry in entries if not entry["directory"]]
    build_markers = [entry["path"] for entry in file_entries
                     if PurePosixPath(entry["path"]).name in
                     {"gradlew", "gradlew.bat", "settings.gradle", "settings.gradle.kts",
                      "build.gradle", "build.gradle.kts", "AndroidManifest.xml", "CMakeLists.txt"}]
    manifest = {
        "filename": FILENAME,
        "size": size,
        "sha256": digest.hexdigest(),
        "entry_count": len(entries),
        "file_count": len(file_entries),
        "uncompressed_size": sum(entry["size"] for entry in file_entries),
        "build_markers": build_markers,
        "apk_files": [entry for entry in file_entries if entry["path"].lower().endswith(".apk")],
        "largest_files": sorted(file_entries, key=lambda entry: entry["size"], reverse=True)[:100],
        "entries": entries,
    }
    output_path = Path(".github/import-manifest.json")
    output_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({key: value for key, value in manifest.items()
                      if key not in {"entries", "largest_files"}}, indent=2))
    print(f"Verified ZIP inventory written to {output_path}; no source code was printed or executed.")


if __name__ == "__main__":
    main()
