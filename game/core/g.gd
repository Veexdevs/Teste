extends Node
## Registo global (autoload "G"). Sem class_name: o projecto e construido
## inteiramente em runtime e nao depende do cache de classes do editor.

var main: Node3D
var world: Node3D
var match_mgr: Node
var hud: CanvasLayer
var menu: Control
var audio: Node
var materials: Node
var fx: Node3D
var models: Node
var controls: Node
var touch: CanvasLayer
var player: Node3D
var selftest = false
var log_lines: Array = []

const TEAM_ATTACK = 0
const TEAM_DEFEND = 1
const L_WORLD = 1
const L_CHARACTER = 2
const L_FORT = 4
const L_PROP = 8

var tuning = {
    "gravity": 20.0, "walk_speed": 4.3, "sprint_speed": 6.5, "crouch_speed": 2.1,
    "accel": 28.0, "air_accel": 4.0, "friction": 11.0, "jump_speed": 6.2,
    "stamina_max": 100.0, "stamina_drain": 13.0, "stamina_regen": 9.5,
    "eye_height": 1.62, "crouch_eye": 1.05, "zone_head": 1.48, "zone_legs": 0.85,
    "dmg_head": 4.0, "dmg_chest": 1.0, "dmg_stomach": 1.15, "dmg_limb": 0.72,
    "armor_torso": 0.52, "fall_safe": 8.0, "fall_damage": 9.0,
    "round_time": 150.0, "buy_time": 12.0, "bomb_time": 38.0,
    "plant_time": 4.2, "defuse_time": 7.5, "rounds_to_win": 6, "start_money": 800,
}

var weapons = {
    "m4a1": {"name": "M4A1 CARBINE", "cal": "5.56x45 NATO", "rpm": 700, "damage": 33.0,
        "mag": 30, "reserve": 120, "reload": 2.35, "spread": 0.85, "move_spread": 2.6,
        "recoil": 0.62, "muzzle": 880.0, "auto": true, "ads_spread": 0.34,
        "price": 3100, "model": "rifle", "sound": "rifle", "penetration": 0.62},
    "ak47": {"name": "AK-47", "cal": "7.62x39", "rpm": 600, "damage": 39.0,
        "mag": 30, "reserve": 90, "reload": 2.7, "spread": 1.15, "move_spread": 3.1,
        "recoil": 0.95, "muzzle": 715.0, "auto": true, "ads_spread": 0.42,
        "price": 2700, "model": "rifle", "sound": "rifle_heavy", "penetration": 0.78},
    "mp5": {"name": "H&K MP5A3", "cal": "9x19 Parabellum", "rpm": 800, "damage": 25.0,
        "mag": 30, "reserve": 120, "reload": 2.1, "spread": 1.0, "move_spread": 2.2,
        "recoil": 0.42, "muzzle": 400.0, "auto": true, "ads_spread": 0.48,
        "price": 1500, "model": "smg", "sound": "smg", "penetration": 0.38},
    "sniper": {"name": "M24 SWS", "cal": "7.62x51 NATO", "rpm": 48, "damage": 108.0,
        "mag": 5, "reserve": 25, "reload": 3.4, "spread": 0.55, "move_spread": 5.0,
        "recoil": 1.9, "muzzle": 850.0, "auto": false, "ads_spread": 0.06,
        "price": 4750, "model": "sniper", "sound": "sniper", "penetration": 0.92, "bolt": true},
    "pistol": {"name": "M9 SIDEARM", "cal": "9x19 Parabellum", "rpm": 420, "damage": 31.0,
        "mag": 15, "reserve": 60, "reload": 1.65, "spread": 1.25, "move_spread": 2.4,
        "recoil": 0.72, "muzzle": 380.0, "auto": false, "ads_spread": 0.45,
        "price": 0, "model": "pistol", "sound": "pistol", "penetration": 0.32},
}

var fortifications = {
    "sandbag": {"name": "SACOS DE AREIA", "hp": 260.0, "charges": 1, "build": 1.15,
        "size": Vector3(2.1, 0.95, 0.62), "penetrate": 0.55, "slow": 0.0,
        "desc": "Cobertura baixa. Absorve fogo, permite atirar por cima."},
    "hesco": {"name": "BARREIRA HESCO", "hp": 700.0, "charges": 2, "build": 2.15,
        "size": Vector3(2.2, 1.85, 0.85), "penetrate": 0.16, "slow": 0.0,
        "desc": "Cobertura alta e pesada."},
    "wire": {"name": "ARAME FARPADO", "hp": 130.0, "charges": 1, "build": 0.95,
        "size": Vector3(2.6, 0.85, 0.5), "penetrate": 1.0, "slow": 0.42,
        "desc": "Atrasa o avanco inimigo."},
    "shield": {"name": "ESCUDO BALISTICO", "hp": 420.0, "charges": 2, "build": 1.7,
        "size": Vector3(1.0, 1.75, 0.22), "penetrate": 0.22, "slow": 0.0,
        "desc": "Proteccao frontal para pontos de passagem."},
}

var buy_items = [
    {"key": "m4a1", "label": "M4A1 CARBINE", "price": 3100, "kind": "primary"},
    {"key": "ak47", "label": "AK-47", "price": 2700, "kind": "primary"},
    {"key": "mp5", "label": "H&K MP5A3", "price": 1500, "kind": "primary"},
    {"key": "sniper", "label": "M24 SWS", "price": 4750, "kind": "primary"},
    {"key": "armor", "label": "COLETE + CAPACETE", "price": 1000, "kind": "armor"},
    {"key": "ammo", "label": "MUNICAO COMPLETA", "price": 400, "kind": "ammo"},
    {"key": "sandbag", "label": "+2x SACOS DE AREIA", "price": 600, "kind": "charge"},
    {"key": "hesco", "label": "+1x BARREIRA HESCO", "price": 900, "kind": "charge"},
    {"key": "wire", "label": "+2x ARAME FARPADO", "price": 500, "kind": "charge"},
    {"key": "shield", "label": "+1x ESCUDO BALISTICO", "price": 800, "kind": "charge"},
]

func _ready() -> void:
    for a in OS.get_cmdline_user_args():
        if a == "--selftest":
            selftest = true

func note(s: String) -> void:
    log_lines.append(s)
    print("[SENTINELA] ", s)

func rng_range(a: float, b: float) -> float:
    return a + randf() * (b - a)

func is_mobile() -> bool:
    return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
