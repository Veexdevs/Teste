# builds/

Os binários nativos do SENTINELA são gerados aqui e **ignorados pelo Git**
(ver `.gitignore`) porque somam ~500 MB. Estão disponíveis de duas formas:

1. **GitHub Release `v1.0.0`** — `SENTINELA.apk`, `SENTINELA.exe`,
   `SENTINELA.x86_64`, `SENTINELA_macos.zip`, `SENTINELA_ios_xcode.zip`
   (e `SENTINELA_ios_unsigned.ipa` quando a workflow macOS corre).
2. **Artefactos** das Actions** `build-native` / `build-ios`.

Para gerar localmente: `GODOT_BIN=/caminho/godot bash tools/build_all.sh`.

| Ficheiro | Alvo | Notas |
| --- | --- | --- |
| `SENTINELA.apk` | Android | Assinado (v2+v3) com `certs/debug.keystore`. |
| `SENTINELA.exe` | Windows x86_64 | PCK embutido, ficheiro único. |
| `SENTINELA.x86_64` | Linux x86_64 | PCK embutido, executável único. |
| `SENTINELA_macos.zip` | macOS universal | `.app` com assinatura ad-hoc. |
| `SENTINELA_ios_xcode.zip` | iOS | Projecto Xcode; `.ipa` assinado exige macOS + conta Apple. |
