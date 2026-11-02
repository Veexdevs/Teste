#!/usr/bin/env python3
"""Make the bundled signature-compatibility shim fail soft on newer Android.

The supplied classes18.dex contains bin.mt.signature.KillerApplication. Its
killPM() method replaces PackageInfo.CREATOR, then clears several internal
Android caches. In this build all cache-clearing failures are routed to a
handler that throws RuntimeException from a static initializer, which kills
the process before the game can start. Newer Android/MIUI builds can reject
those hidden-field/cache operations even though the public creator hook was
already installed.

This patch changes only that fatal catch handler to return-void. It does not
change the game, the certificate data, the native libraries, or the rest of
the shim. DEX size is preserved; the DEX SHA-1 and Adler-32 are recomputed.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import struct
import zlib

from androguard.core.dex import DEX
from loguru import logger

logger.remove()

EXPECTED_SHA256 = "b97059a26a1116d2d6ec878285feed179f16944690d88eaecd4e71709d3709ac"
CLASS_NAME = "Lbin/mt/signature/KillerApplication;"
METHOD_NAME = "killPM"
METHOD_DESC = "(Ljava/lang/String;Ljava/lang/String;)V"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def fix_dex_checksums(data: bytearray) -> None:
    signature = hashlib.sha1(data[32:]).digest()
    data[12:32] = signature
    checksum = zlib.adler32(data[12:]) & 0xFFFFFFFF
    struct.pack_into("<I", data, 8, checksum)


def instruction_offsets(code):
    # code_item: registers/ins/outs/tries (4xu16), debug_info_off (u32),
    # insns_size (u32), then the 16-bit instruction stream.
    offset = code.get_off() + 16
    for instruction in code.get_bc().get_instructions():
        yield offset, instruction
        # Androguard reports instruction lengths in bytes, not 16-bit units.
        offset += instruction.get_length()


def find_method(dex: DEX):
    for cls in dex.get_classes():
        if cls.get_name() != CLASS_NAME:
            continue
        for method in cls.get_methods():
            if method.get_name() == METHOD_NAME and method.get_descriptor().replace(" ", "") == METHOD_DESC:
                return method
    raise RuntimeError(f"Method not found: {CLASS_NAME}->{METHOD_NAME}{METHOD_DESC}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dex", default="classes18.dex")
    parser.add_argument("--report", required=True)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    path = Path(args.dex)
    original = path.read_bytes()
    before = sha256(original)
    dex = DEX(original)
    method = find_method(dex)
    code = method.get_code()
    if code is None:
        raise RuntimeError("killPM has no code item")

    instructions = list(instruction_offsets(code))
    target = None
    for index in range(len(instructions) - 2):
        off0, ins0 = instructions[index]
        off1, ins1 = instructions[index + 1]
        off2, ins2 = instructions[index + 2]
        if (
            ins0.get_name() == "new-instance"
            and "Ljava/lang/RuntimeException;" in ins0.get_output()
            and ins1.get_name() == "invoke-direct"
            and "Ljava/lang/RuntimeException;-><init>(Ljava/lang/Throwable;)V" in ins1.get_output()
            and ins2.get_name() == "throw"
        ):
            target = (off0, off2 + ins2.get_length())
            break
    if target is None:
        raise RuntimeError("Expected fatal RuntimeException handler was not found")

    start, end = target
    patched = bytearray(original)
    size = end - start
    if size < 2 or size % 2:
        raise RuntimeError(f"Unexpected handler size: {size}")
    patched[start:end] = b"\x0e\x00" + b"\x00\x00" * ((size - 2) // 2)
    fix_dex_checksums(patched)

    if patched[start : start + 2] != b"\x0e\x00":
        raise RuntimeError("Patched handler does not start with return-void")
    if any(byte != 0 for byte in patched[start + 2 : end]):
        raise RuntimeError("Patched handler padding is not NOP")
    expected_signature = hashlib.sha1(patched[32:]).digest()
    expected_checksum = zlib.adler32(patched[12:]) & 0xFFFFFFFF
    if bytes(patched[12:32]) != expected_signature or struct.unpack_from("<I", patched, 8)[0] != expected_checksum:
        raise RuntimeError("DEX checksum/signature verification failed")
    if len(patched) != len(original):
        raise RuntimeError("DEX size changed unexpectedly")

    report = {
        "file": str(path),
        "class": CLASS_NAME,
        "method": METHOD_NAME + METHOD_DESC,
        "reason": "Do not turn optional Android internal cache-clearing failures into a fatal static-initializer exception.",
        "before_sha256": before,
        "after_sha256": sha256(bytes(patched)),
        "expected_input_sha256": EXPECTED_SHA256,
        "input_hash_matched": before == EXPECTED_SHA256,
        "patch_offset": start,
        "patch_bytes": size,
        "replacement": "return-void followed by NOP padding",
        "size_before": len(original),
        "size_after": len(patched),
        "dry_run": args.dry_run,
    }
    report_path = Path(args.report)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    if before != EXPECTED_SHA256:
        raise RuntimeError("Input classes18.dex hash differs; refusing to patch an unexpected build")
    if not args.dry_run:
        path.write_bytes(patched)


if __name__ == "__main__":
    main()
