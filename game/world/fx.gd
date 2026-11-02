extends Node3D
## Efeitos visuais leves (tracadores, impactos, sangue, claroes).

func _mat(c: Color, e: float = 1.6, alpha: float = 1.0) -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = Color(c.r, c.g, c.b, alpha)
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.emission_enabled = true
    m.emission = c
    m.emission_energy_multiplier = e
    if alpha < 1.0:
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return m

func _kill(node: Node3D, delay: float) -> void:
    var tw = create_tween()
    tw.tween_property(node, "scale", Vector3(0.001, 0.001, 0.001), delay)
    tw.tween_callback(node.queue_free)

func _ball(pos: Vector3, radius: float, color: Color, life: float, vel: Vector3 = Vector3.ZERO) -> void:
    var sm = SphereMesh.new()
    sm.radius = radius
    sm.height = radius * 2.0
    sm.radial_segments = 6
    sm.rings = 3
    var mi = MeshInstance3D.new()
    mi.mesh = sm
    mi.material_override = _mat(color)
    add_child(mi)
    mi.position = pos
    if vel != Vector3.ZERO:
        var tw = create_tween()
        tw.tween_property(mi, "position", pos + vel * life + Vector3(0, -1.4 * life * life, 0), life)
    _kill(mi, life)

func tracer(from: Vector3, to: Vector3, color: Color = Color(1.0, 0.82, 0.42)) -> void:
    var d = to - from
    var length = d.length()
    if length < 0.05:
        return
    var bm = BoxMesh.new()
    bm.size = Vector3(0.013, 0.013, length)
    var mi = MeshInstance3D.new()
    mi.mesh = bm
    mi.material_override = _mat(color, 2.2, 0.85)
    add_child(mi)
    mi.position = from + d * 0.5
    mi.look_at(to, Vector3.UP)
    _kill(mi, 0.075)

func impact(pos: Vector3, normal: Vector3, kind: String = "concrete") -> void:
    var c = Color(0.85, 0.80, 0.62)
    if kind == "metal":
        c = Color(1.0, 0.72, 0.30)
    elif kind == "body":
        c = Color(0.62, 0.06, 0.06)
    elif kind == "wood":
        c = Color(0.62, 0.45, 0.25)
    for i in range(3):
        _ball(pos + normal * 0.02, 0.018 + randf() * 0.022, c, 0.18 + randf() * 0.2,
              normal * G.rng_range(0.6, 2.2) + Vector3(G.rng_range(-1, 1), G.rng_range(0.2, 1.6), G.rng_range(-1, 1)))
    var bm = BoxMesh.new()
    bm.size = Vector3(0.10, 0.10, 0.008)
    var mark = MeshInstance3D.new()
    mark.mesh = bm
    var dark = StandardMaterial3D.new()
    dark.albedo_color = Color(0.08, 0.08, 0.08, 0.85)
    dark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mark.material_override = dark
    add_child(mark)
    mark.position = pos + normal * 0.012
    if normal.length() > 0.001:
        mark.look_at(pos + normal, Vector3.UP if absf(normal.y) < 0.9 else Vector3.FORWARD)
    var tw = create_tween()
    tw.tween_interval(6.0)
    tw.tween_callback(mark.queue_free)

func blood(pos: Vector3) -> void:
    for i in range(5):
        _ball(pos, 0.022 + randf() * 0.025, Color(0.55, 0.03, 0.03), 0.25 + randf() * 0.25,
              Vector3(G.rng_range(-1.6, 1.6), G.rng_range(0.3, 2.0), G.rng_range(-1.6, 1.6)))

func muzzle(pos: Vector3, dir: Vector3) -> void:
    _ball(pos, 0.085, Color(1.0, 0.83, 0.42), 0.055)
    var bm = BoxMesh.new()
    bm.size = Vector3(0.05, 0.05, 0.24)
    var mi = MeshInstance3D.new()
    mi.mesh = bm
    mi.material_override = _mat(Color(1.0, 0.72, 0.25), 2.4, 0.75)
    add_child(mi)
    mi.position = pos + dir * 0.12
    mi.look_at(pos + dir, Vector3.UP)
    _kill(mi, 0.06)
    var l = OmniLight3D.new()
    l.light_color = Color(1.0, 0.72, 0.35)
    l.light_energy = 3.0
    l.omni_range = 6.0
    add_child(l)
    l.position = pos
    var tw = create_tween()
    tw.tween_property(l, "light_energy", 0.0, 0.07)
    tw.tween_callback(l.queue_free)

func shell(pos: Vector3) -> void:
    var cm = CylinderMesh.new()
    cm.top_radius = 0.011
    cm.bottom_radius = 0.011
    cm.height = 0.035
    cm.radial_segments = 6
    var mi = MeshInstance3D.new()
    mi.mesh = cm
    mi.material_override = G.materials.flat(Color(0.78, 0.58, 0.20), 0.3, 0.85)
    add_child(mi)
    mi.position = pos
    var tw = create_tween()
    tw.tween_property(mi, "position", pos + Vector3(G.rng_range(0.4, 1.2), -0.9, G.rng_range(-0.5, 0.5)), 0.55)
    tw.tween_callback(mi.queue_free)

func explosion(pos: Vector3) -> void:
    for i in range(22):
        _ball(pos + Vector3(G.rng_range(-0.5, 0.5), G.rng_range(0, 0.8), G.rng_range(-0.5, 0.5)),
              0.10 + randf() * 0.28, Color(1.0, G.rng_range(0.35, 0.75), 0.15),
              0.35 + randf() * 0.6, Vector3(G.rng_range(-5, 5), G.rng_range(1, 7), G.rng_range(-5, 5)))
    var l = OmniLight3D.new()
    l.light_color = Color(1.0, 0.62, 0.22)
    l.light_energy = 22.0
    l.omni_range = 30.0
    add_child(l)
    l.position = pos + Vector3(0, 0.6, 0)
    var tw = create_tween()
    tw.tween_property(l, "light_energy", 0.0, 0.55)
    tw.tween_callback(l.queue_free)
