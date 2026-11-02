#!/usr/bin/env bash
# SENTINELA - compilação de todos os alvos nativos.
# Uso:  GODOT_BIN=/caminho/godot bash tools/build_all.sh
#       SKIP_ASSETS=1 bash tools/build_all.sh   (usa os modelos já presentes)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p builds

GODOT_BIN="${GODOT_BIN:-godot}"
if ! command -v "$GODOT_BIN" >/dev/null 2>&1 && [ ! -x "$GODOT_BIN" ]; then
    echo "ERRO: Godot 4.5 nao encontrado. Defina GODOT_BIN=/caminho/para/godot" >&2
    exit 1
fi
echo "=== Godot: $($GODOT_BIN --headless --version) ==="

if [ "${SKIP_ASSETS:-0}" != "1" ] && command -v python3 >/dev/null 2>&1; then
    python3 tools/fetch_assets.py || echo "AVISO: modelos incompletos; serao usados fallbacks procedurais"
    python3 tools/make_icon.py
fi

echo "=== selftest headless ==="
"$GODOT_BIN" --headless --fixed-fps 60 --path . --quit-after 900 -- --selftest 2>&1 | tee /tmp/sentinela-selftest.log
grep -q SELFTEST_PASS /tmp/sentinela-selftest.log

# --- Android: exige JDK + Android SDK -------------------------------------
ANDROID_OK=0
JAVA_SDK="${JAVA_HOME:-}"
if [ -z "$JAVA_SDK" ] && command -v java >/dev/null 2>&1; then
    JAVA_SDK="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
fi
ANDROID_SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [ -n "$JAVA_SDK" ] && [ -x "$JAVA_SDK/bin/java" ] && [ -x "$JAVA_SDK/bin/keytool" ] \
   && [ -n "$ANDROID_SDK" ] && [ -f "$ANDROID_SDK/platform-tools/adb" ] \
   && [ -d "$ANDROID_SDK/build-tools" ]; then
    ANDROID_OK=1
    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/godot"
    CFG="${XDG_CONFIG_HOME:-$HOME/.config}/godot/editor_settings-4.5.tres"
    cat > "$CFG" <<EOF
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/java_sdk_path = "$JAVA_SDK"
export/android/android_sdk_path = "$ANDROID_SDK"
export/android/debug_keystore = "$ROOT/certs/debug.keystore"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
EOF
    echo "=== Android: JDK=$JAVA_SDK SDK=$ANDROID_SDK ==="
fi

echo "=== exportações ==="
if [ "$ANDROID_OK" = "1" ]; then
    "$GODOT_BIN" --headless --path . --export-debug   "Android"         builds/SENTINELA.apk
else
    echo "AVISO: sem JDK/Android SDK - a saltar o APK. Veja README.md."
fi
"$GODOT_BIN" --headless --path . --export-release "Windows Desktop" builds/SENTINELA.exe
"$GODOT_BIN" --headless --path . --export-release "Linux"           builds/SENTINELA.x86_64
"$GODOT_BIN" --headless --path . --export-release "macOS"           builds/SENTINELA_macos.zip
"$GODOT_BIN" --headless --path . --export-release "iOS"             builds/SENTINELA_ios.ipa

echo "=== empacotar projecto Xcode de iOS ==="
rm -f builds/SENTINELA_ios_xcode.zip
( cd builds && zip -q -r -y SENTINELA_ios_xcode.zip \
    SENTINELA_ios SENTINELA_ios.pck SENTINELA_ios.xcodeproj \
    SENTINELA_ios.xcframework MoltenVK.xcframework PrivacyInfo.xcprivacy )

echo "=== verificação final ==="
if [ -f builds/SENTINELA.apk ]; then
    unzip -l builds/SENTINELA.apk | grep -c 'assets/game/assets/models' \
        | xargs -I{} echo "APK: {} modelos glTF incluidos"
fi
chmod +x builds/SENTINELA.x86_64
./builds/SENTINELA.x86_64 --headless --fixed-fps 60 --quit-after 900 -- --selftest 2>&1 \
    | tee /tmp/sentinela-linux-selftest.log
grep -q SELFTEST_PASS /tmp/sentinela-linux-selftest.log
ls -lh builds/
echo "BUILD_OK"
