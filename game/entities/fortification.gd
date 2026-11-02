extends StaticBody3D
## Fortificacao de campo destrutivel (cobertura militar, nao construcao arcade).

var kind = "sandbag"
var hp = 260.0
var max_hp = 260.0
var penetrate = 0.55
var slow = 0.0
var team = 0
var size = Vector3(2.1, 0.95, 0.62)

func init(p_kind: String, pos: Vector3, yaw: float, p_team: int) -> void:
    kind = p_kind
    team = p_team
    var cfg: Dictionary = G.fortifications[p_kind]
    hp = float(cfg.hp)
    max_hp = hp
    penetrate = float(cfg.penetrate)
    slow = float(cfg.slow)
    size = cfg.size
    collision_layer = G.L_FORT
    collision_mask = 0
    global_position = pos
    rotation.y = yaw
    var cs = CollisionShape3D.new()
    var bs = BoxShape3D.new()
    bs.size = size
    cs.shape = bs
    cs.position = Vector3(0, size.y * 0.5, 0)
    add_child(cs)
    _visual()
    set_meta("surface", "wood")
    set_meta("fortification", true)

func _visual() -> void:
    var holder = Node3D.new()
    add_child(holder)
    match kind:
        "sandbag":
            var m = G.materials.get_mat("fabric", Color(0.74, 0.68, 0.49), 1.0)
            var cols = int(size.x / 0.70)
            for layer in range(3):
                for i in range(cols - (layer % 2)):
                    var x = -size.x * 0.5 + 0.36 + i * 0.70 + (layer % 2) * 0.35
                    var b = G.models.box(holder, Vector3(0.68, 0.29, size.z), Vector3(x, 0.15 + layer * 0.29, 0), m)
                    b.rotation.y = G.rng_range(-0.05, 0.05)
        "hesco":
            var m = G.materials.get_mat("fabric", Color(0.66, 0.61, 0.46), 1.4)
            G.models.box(holder, Vector3(size.x, size.y, size.z), Vector3(0, size.y * 0.5, 0), m)
            var wire = G.materials.flat(Color(0.30, 0.32, 0.29), 0.5, 0.65)
            for i in range(7):
                G.models.box(holder, Vector3(0.025, size.y, size.z + 0.02),
                    Vector3(-size.x * 0.5 + 0.16 + i * (size.x / 6.0), size.y * 0.5, 0), wire)
        "wire":
            var wire = G.materials.flat(Color(0.42, 0.44, 0.41), 0.42, 0.8)
            for i in range(4):
                var c = G.models.cyl(holder, 0.34, 0.055,
                    Vector3(-size.x * 0.4 + i * size.x * 0.27, 0.28 + (i % 2) * 0.28, 0),
                    wire, Vector3(PI * 0.5, 0, 0))
                c.rotation.z = G.rng_range(-0.3, 0.3)
            G.models.box(holder, Vector3(size.x, 0.05, 0.05), Vector3(0, 0.52, 0), wire)
        "shield":
            var steel = G.materials.flat(Color(0.20, 0.23, 0.21), 0.55, 0.72)
            G.models.box(holder, Vector3(size.x, size.y, size.z), Vector3(0, size.y * 0.5, 0), steel)
            G.models.box(holder, Vector3(0.28, 0.09, 0.03), Vector3(0, size.y * 0.78, size.z * 0.52),
                G.materials.glass(Color(0.25, 0.38, 0.45)))
            G.models.box(holder, Vector3(size.x * 1.15, 0.09, 0.28), Vector3(0, 0.045, 0), steel)

func take_damage(d: float) -> void:
    if hp <= 0.0:
        return
    hp -= d
    var f = clampf(hp / max_hp, 0.0, 1.0)
    for c in get_children():
        if c is Node3D:
            c.scale = Vector3(1.0, maxf(0.45, f), 1.0)
    if hp <= 0.0:
        G.fx.impact(global_position + Vector3(0, size.y * 0.5, 0), Vector3.UP, "wood")
        G.audio.play_at("impact", global_position, -6.0)
        queue_free()
