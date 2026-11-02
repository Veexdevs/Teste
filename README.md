# SENTINELA — Operação Cerrado

Um shooter táctico 3D **nativo**, sério e militar, feito em **Godot 4.5**.
Mistura a estrutura de rondas/economia/objectivo de *Counter-Strike* com a
construção de cobertura e mobilidade de *Fortnite*, mas com tom realista:
balística com queda e penetração, zonas de dano, colete e capacete,
stamina, inclinação, recuo, dispersão por movimento, IA com percepção por
linha de visão e cobertura de campo destrutível.

> **Não é HTML nem jogo de navegador.** Não existe preset Web/HTML5. Todos os
> alvos são binários nativos: Android (`.apk`), Windows (`.exe`), Linux,
> macOS (`.app`) e iOS (projecto Xcode / `.ipa`).
>
> **Visual:** câmara em terceira pessoa por cima do ombro (ADS passa a
> primeira pessoa), cidade em ruínas com texturas PBR fotorrealistas,
> entulho, viaturas queimadas, fumo, névoa e paleta dessaturada; HUD
> minimalista com minimapa circular A/B, placar `5 | 1:42 | 5`, silhueta da
> arma com `30 / 90`, vida/colete e mira discreta.

---

## Jogar agora

| Plataforma | Ficheiro | Como instalar |
| --- | --- | --- |
| **Android** | `builds/SENTINELA.apk` | Transferir, activar «Instalar de fontes desconhecidas» e abrir o APK. Já vem **assinado** (v2 + v3) com a chave de debug em `certs/debug.keystore`. Requer Android 8+ / OpenGL ES 3. |
| **Windows** | `builds/SENTINELA.exe` | Duplo clique. O PCK está embutido — é um único ficheiro. |
| **Linux** | `builds/SENTINELA.x86_64` | `chmod +x SENTINELA.x86_64 && ./SENTINELA.x86_64`. PCK embutido. |
| **macOS** | `builds/SENTINELA_macos.zip` | Descompactar e abrir o `.app`. Assinatura ad-hoc: pode ser necessário `xattr -cr "SENTINELA - Operacao Cerrado.app"` ou «Abrir mesmo assim». |
| **iOS** | `builds/SENTINELA_ios_xcode.zip` | Ver a secção iOS abaixo. |

Os mesmos ficheiros são publicados automaticamente no **GitHub Release
`v1.0.0`** e como artefactos das *Actions* `build-native` e `build-ios`.

---

## Jogo

- **Modo:** assalto (4 operadores) contra defesa (5 sentinelas), melhor de 11
  rondas. Fase de planeamento/compras de 12 s, ronda de 150 s.
- **Objectivo:** plantar a carga em **A** ou **B** (manter `F` durante 4,2 s).
  A defesa tem 38 s para a desactivar (manter `F` durante 7,5 s). Eliminar
  a equipa adversária também decide a ronda.
- **Economia:** créditos por ronda, eliminação, plantação e desactivação.
  Armaria com M4A1, AK-47, MP5, M24, colete+capacete, munição e cargas de
  fortificação.
- **Fortificações:** sacos de areia, barreira HESCO, arame farpado e escudo
  balístico. Tempo de montagem, validação de espaço, rotação, HP e
  destruição por fogo. Não é construção «arcade» instantânea.
- **Balística:** projéctil simulado em passos com gravidade, `muzzle velocity`
  por arma, perda de dano com distância, penetração reduzida em cobertura
  e zonas de dano (cabeça 4×, peito, abdómen, membros).
- **Áudio:** 19 amostras PCM sintetizadas em runtime (disparos, recarga,
  passos, impactos, rádio, vento, carga, explosão) — sem ficheiros externos.
- **Modelos 3D prontos:** soldado rigado (Mixamo/three.js) com capacete,
  colete, mochila e equipamento táctico procedurais; espingarda e seis armas
  glTF em viewmodel, carregados em runtime via `GLTFDocument`. Se faltar
  algum ficheiro, o jogo gera armas e corpos procedurais automaticamente.
- **Texturas fotorrealistas:** `game/assets/textures/concrete_ruin.*` e
  `asphalt_rubble.*` (betão destruído e asfalto com entulho) são lidas como
  PNG em runtime e aplicadas como albedo PBR com normais procedurais.

### Controlos (desktop)

| Tecla | Acção |
| --- | --- |
| `W A S D` | mover |
| Rato | olhar |
| Botão esquerdo | disparar |
| Botão direito | mirar (ADS — passa a primeira pessoa) |
| `Shift` | correr (gasta fôlego) |
| `Ctrl` / `C` | agachar |
| `Espaço` | saltar |
| `Q` / `E` | inclinar-se |
| `R` | recarregar |
| `1` / `2` | arma primária / secundária |
| `F` (manter) | plantar / desactivar carga |
| `B` | modo fortificação |
| `V` / `T` | alternar / rodar fortificação |
| `Tab` | placar |
| `Esc` | pausa · `F1` | ajuda |

No **Android/iOS** há joystick virtual à esquerda, arrastar à direita para
olhar e botões de fogo, mira, recarga, salto, agachar, usar, construir,
trocar e rodar. Gamepad também é suportado.

---

## Compilar

Pré-requisitos: Godot **4.5-stable** (editor) + os *export templates* dessa
versão em `~/.local/share/godot/export_templates/4.5.stable/` (macOS:
`~/Library/Application Support/Godot/export_templates/4.5.stable/`).

```bash
python3 tools/make_icon.py            # icon.png (opcional, já versionado)
python3 tools/fetch_assets.py         # modelos glTF + creditos
bash tools/build_all.sh               # selftest + os 5 alvos nativos
```

`GODOT_BIN=/caminho/para/godot bash tools/build_all.sh` permite apontar a
outro editor. Para Android são necessários JDK 17 e Android SDK, e o script
gera `~/.config/godot/editor_settings-4.5.tres` com os caminhos — ver
`tools/build_all.sh` e `.github/workflows/build-native.yml`, que faz exactamente
o mesmo em CI.

Verificação rápida sem abrir janela:

```bash
godot --headless --fixed-fps 60 --path . --quit-after 900 -- --selftest
# termina com SELFTEST_PASS
```

O `export_presets.cfg` usa `include_filter="*.bin"` em **todos** os presets:
os GLB estão guardados com essa extensão para serem copiados como bytes
puros para dentro do PCK (o importador do editor não é usado).

---

## iOS: o que é possível aqui

O código de exportação da Godot 4.5 para Apple usa `xcodebuild archive`,
`xcodebuild -exportArchive`, `codesign` e `xcrun`. Em Linux a própria engine
avisa: *«.ipa can only be built on macOS. Leaving Xcode project without
building the package.»*

Por isso este repositório entrega:

1. `builds/SENTINELA_ios_xcode.zip` — projecto Xcode completo
   (`SENTINELA_ios.xcodeproj`, `SENTINELA_ios.xcframework`,
   `MoltenVK.xcframework`, `PrivacyInfo.xcprivacy`, `SENTINELA_ios.pck`,
   ícones, storyboard, `export_options.plist`).
2. A workflow `.github/workflows/build-ios.yml` corre num runner `macos-14`,
   compila o `.app` com assinatura desligada e empacota
   `SENTINELA_ios_unsigned.ipa`.

Um `.ipa` **instalável num iPhone real** exige Xcode num macOS, uma conta
Apple Developer, um *Team ID* real e um perfil de provisionamento. Substitua
`application/app_store_team_id` e `application/bundle_identifier` no preset
iOS, ligue `application/export_project_only=false` e exporte a partir de macOS
com as identidades de assinatura correctas. Sem isso, qualquer `.ipa` gerado
aqui é não assinado (útil para simulador / inspecção, não para instalação).

---

## Estrutura

```
project.godot            configuração nativa (gl_compatibility, ETC2/ASTC)
export_presets.cfg       Android, Windows, Linux, macOS, iOS
game/core/               G (tuning), controlos, materiais, áudio, modelos
game/world/              mapa "CERRADO" procedural + efeitos
game/entities/           soldado, jogador, IA, armas, fortificações
game/match/              rondas, economia, carga/desactivação
game/ui/                 HUD, menu, minimapa, controlos tácteis
game/assets/models/      GLB prontos (9 ficheiros .bin)
game/assets/textures/    albedos PBR fotorrealistas (.png + .bin)
game/assets/licenses/    créditos e licenças de terceiros
tools/                   fetch_assets.py, make_icon.py, build_all.sh
certs/debug.keystore     chave de debug Android (alias androiddebugkey / android)
builds/                  binários gerados (ignorados pelo Git)
```

Os binários em `builds/` são **artefactos**, não código: estão no
`.gitignore` para não inflar o repositório. O Release do GitHub é a forma
oficial de os distribuir.

---

## Nota

Simulação táctica **ficcional**. Os nomes de armas e equipamento são usados
apenas como referência de calibre/ergonomia num jogo; o projecto não está
associado a fabricantes, forças armadas ou operações reais. Consultar
`game/assets/licenses/` para os créditos dos modelos 3D.
