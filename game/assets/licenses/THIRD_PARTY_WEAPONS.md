# Modelos de terceiros (armas)

Os seis GLB em `game/assets/models/weapons/` foram obtidos pela workflow de CI
`.github/workflows/fetch-models.yml` a partir de repositorios publicos de
demonstracao de jogos/visores glTF. Sao usados apenas como malha de viewmodel
e de arma em terceira pessoa, sem qualquer associacao comercial.

| Ficheiro | Repositorio de origem | Ficheiro de origem |
| --- | --- | --- |
| `m4a1.bin` | `JoseRamonRenteroJimenez/DVI_G8` | `assets/glb/M4A1.glb` |
| `ak47.bin` | `loingtan/fps-threejs-game` | `src/assets/guns/ak47/ak47.glb` |
| `vm_mp5.bin` | `shadow-kernel/Vortex-Engine-Horror-Template` | `Assets/Models/Viewmodel/vm_mp5.glb` |
| `arms_m4a1.bin` | `skyelynwaddell/vector0-godot` | `blender/arms_m4a1.glb` |
| `assault_rifle.bin` | `habibmukhlis/3D-shooter-game` | `public/assets/models/assault_rifle.glb` |
| `ak47_low.bin` | `aminere/powerplay-threejs` | `game/public/models/resources/ak47.glb` |

Os repositorios de origem nao acompanham uma declaracao de licenca explicita
para estas malhas de demonstracao. Se e autor de algum destes modelos e
pretender a sua remocao ou um credito especifico, abra uma issue no
repositorio do projecto. O jogo funciona na integra sem estes ficheiros:
`game/core/models.gd` gera armas procedurais como fallback automatico.
