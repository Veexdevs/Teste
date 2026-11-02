#!/usr/bin/env bash
# Install and launch APKs on an emulator, capturing only runtime logs/metadata.
set -uo pipefail

PKG="com.miniclip.eightballpool"
ACTIVITY="com.miniclip.eightballpool.EightBallPoolActivity"
REPORT="emulator-report"
mkdir -p "$REPORT"

adb shell settings put global package_verifier_enable 0 || true
adb shell settings put global verifier_verify_adb_installs 0 || true
adb shell getconf PAGE_SIZE > "$REPORT/page-size.txt" 2>&1 || true
adb shell getprop ro.build.version.release > "$REPORT/android-release.txt" 2>&1 || true
adb shell getprop ro.build.version.sdk > "$REPORT/android-sdk.txt" 2>&1 || true
adb shell getprop ro.build.version.security_patch > "$REPORT/security-patch.txt" 2>&1 || true
adb shell getprop ro.product.model > "$REPORT/emulator-model.txt" 2>&1 || true
adb shell getprop ro.product.cpu.abilist > "$REPORT/abilist.txt" 2>&1 || true
adb shell getprop ro.dalvik.vm.native.bridge > "$REPORT/native-bridge.txt" 2>&1 || true
adb shell cat /proc/cpuinfo > "$REPORT/cpuinfo.txt" 2>&1 || true

capture() {
  local label="$1"
  adb shell pidof "$PKG" > "$REPORT/$label-pid.txt" 2>&1 || true
  adb logcat -b crash -d > "$REPORT/$label-crash-buffer.txt" 2>&1 || true
  adb shell dumpsys activity exit-info "$PKG" > "$REPORT/$label-exit-info.txt" 2>&1 || true
  adb logcat -b all -d > "$REPORT/$label-logcat.txt" 2>&1 || true
  adb shell dumpsys package "$PKG" > "$REPORT/$label-package.txt" 2>&1 || true
  adb exec-out screencap -p > "$REPORT/$label-screen.png" 2>/dev/null || true
}

test_apk() {
  local label="$1"
  local apk="$2"
  echo "=== Testing $label: $apk ==="
  adb uninstall "$PKG" > "$REPORT/$label-uninstall.txt" 2>&1 || true
  adb logcat -b all -c || true
  if ! adb install -g -t "$apk" > "$REPORT/$label-install.txt" 2>&1; then
    echo "Install failed for $label"
    capture "$label"
    return 0
  fi
  adb shell am start -W -n "$PKG/$ACTIVITY" > "$REPORT/$label-start.txt" 2>&1 || \
    adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 > "$REPORT/$label-start.txt" 2>&1 || true

  local alive="unknown"
  for i in $(seq 1 12); do
    sleep 5
    if adb shell pidof "$PKG" >/dev/null 2>&1; then
      alive="yes"
    else
      alive="no"
      break
    fi
  done
  echo "$alive" > "$REPORT/$label-alive.txt"
  capture "$label"
  adb shell am force-stop "$PKG" >/dev/null 2>&1 || true
}

test_apk "original" "assets/SignatureKiller/origin.apk"
test_apk "release-test" "dist/8Ball-Pool-Android-V2-5-release-test.apk"

python3 - <<'PY'
from pathlib import Path
import re
report = Path('emulator-report')
strict = re.compile(
    r'FATAL EXCEPTION|AndroidRuntime|Fatal signal|signal \d+ \(SIG|'
    r'Process: com\.miniclip\.eightballpool|com\.miniclip\.eightballpool.*(?:died|killed|crash)|'
    r'dlopen failed|UnsatisfiedLinkError|SignatureKiller|libSignatureKiller|KillerApplication|'
    r'java\.lang\.(?:Error|Exception|RuntimeException)|art::Runtime::Abort|DEBUG\s*:|tombstone',
    re.I,
)
lines_out = ['# Emulator crash test summary', '']
for name in ['page-size.txt', 'android-release.txt', 'android-sdk.txt', 'security-patch.txt', 'emulator-model.txt', 'abilist.txt', 'native-bridge.txt']:
    path = report / name
    if path.exists():
        lines_out.append(f'- {name}: `{path.read_text(errors="replace").strip()}`')
for label in ['original', 'release-test']:
    lines_out.append(f'\n## {label}')
    for name in [f'{label}-install.txt', f'{label}-start.txt', f'{label}-alive.txt', f'{label}-pid.txt']:
        path = report / name
        if path.exists():
            text = path.read_text(errors='replace').strip()
            lines_out.append(f'- {name}: `{text[:500]}`')
    exit_path = report / f'{label}-exit-info.txt'
    if exit_path.exists():
        lines_out.append('\n### exit-info\n```text')
        lines_out.extend(exit_path.read_text(errors='replace').splitlines()[:80])
        lines_out.append('```')
    crash_path = report / f'{label}-crash-buffer.txt'
    if crash_path.exists():
        lines_out.append('\n### crash buffer\n```text')
        lines_out.extend(crash_path.read_text(errors='replace').splitlines()[:200])
        lines_out.append('```')
    hits = []
    app_rows = []
    custom_rows = []
    log_path = report / f'{label}-logcat.txt'
    if log_path.exists():
        rows = log_path.read_text(errors='replace').splitlines()
        app_pids = set()
        for row in rows:
            for pattern in (
                r'Start proc (\d+):com\.miniclip\.eightballpool',
                r'am_proc_start: \[\d+,(\d+),',
                r'Process com\.miniclip\.eightballpool \(pid (\d+)\)',
            ):
                match = re.search(pattern, row)
                if match:
                    app_pids.add(match.group(1))
        custom = re.compile(
            r'loader|samurai|PwfNative|SignatureKiller|KillerApplication|HiddenApiBypass|'
            r'EightBallPool|eightballpool|isVerified|installer|verification|license|'
            r'killProcess|SIGKILL|dlopen|UnsatisfiedLinkError|System\.loadLibrary',
            re.I,
        )
        seen = set()
        for i, row in enumerate(rows):
            parts = row.split(None, 5)
            pid = parts[2] if len(parts) > 2 else ''
            if app_pids and pid in app_pids and row not in seen:
                app_rows.append(row)
                seen.add(row)
            if custom.search(row) and row not in seen:
                custom_rows.append(row)
                seen.add(row)
            if strict.search(row):
                start = max(0, i - 2)
                end = min(len(rows), i + 12)
                for candidate in rows[start:end]:
                    if candidate not in seen:
                        hits.append(candidate)
                        seen.add(candidate)
                if len(hits) > 200:
                    break
    if app_rows:
        lines_out.append('\n### app process logs\n```text')
        lines_out.extend(app_rows[:300])
        lines_out.append('```')
    if custom_rows:
        lines_out.append('\n### loader / signature / mod logs\n```text')
        lines_out.extend(custom_rows[:200])
        lines_out.append('```')
    if hits:
        lines_out.append('\n### logcat highlights\n```text')
        lines_out.extend(hits[:200])
        lines_out.append('```')
    elif not app_rows and not custom_rows:
        lines_out.append('\nNo fatal/crash/native-load keywords found in captured logcat.')
summary = '\n'.join(lines_out) + '\n'
(report / 'summary.md').write_text(summary, encoding='utf-8')
print(summary)
PY
