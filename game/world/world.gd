extends Node3D
## Instalacao militar "CERRADO" construida proceduralmente.

var root: Node3D
var env_node: WorldEnvironment
var sun: DirectionalLight3D
var sites = []
var spawns = {0: [], 1: []}
var cover_points: Array = []
var props = []
var lamps = []
var time = 0.0

func build() -> void:
    root = Node3D.new()
    root.name = "Geometry"
    add_child(root)
    _environment()
    _ground()
    _perimeter()
    _compound()
    _sites()
    _containers()
    _field_fortifications()
    _towers()
    _clutter()
    _lights()
    _spawns()
    G.note("mundo: %d props, %d pontos de cobertura, 2 objectivos" % [props.size(), cover_points.size()])

func _mat(kind: String, tint: Color = Color(1, 1, 1, 1), tile: float = 1.0) -> Material:
    return G.materials.get_mat(kind, tint, tile)

func _flat(c: Color, r: float = 0.8, m: float = 0.0, e: float = 0.0) -> Material:
    return G.materials.flat(c, r, m, e)

func solid_box(size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, layer: int = 1, parent: Node3D = null) -> StaticBody3D:
    var host: Node3D = parent if parent != null else root
    var sb = StaticBody3D.new()
    sb.collision_layer = layer
    sb.collision_mask = 0
    sb.position = pos
    sb.rotation = rot
    var cs = CollisionShape3D.new()
    var bs = BoxShape3D.new()
    bs.size = size
    cs.shape = bs
    sb.add_child(cs)
    var bm = BoxMesh.new()
    bm.size = size
    var mi = MeshInstance3D.new()
    mi.mesh = bm
    mi.material_override = mat
    sb.add_child(mi)
    host.add_child(sb)
    props.append(sb)
    return sb

func visual_box(size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
    var host: Node3D = parent if parent != null else root
    var bm = BoxMesh.new()
    bm.size = size
    var mi = MeshInstance3D.new()
    mi.mesh = bm
    mi.material_override = mat
    mi.position = pos
    mi.rotation = rot
    host.add_child(mi)
    return mi

func visual_cyl(radius: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
    var host: Node3D = parent if parent != null else root
    var cm = CylinderMesh.new()
    cm.top_radius = radius
    cm.bottom_radius = radius
    cm.height = height
    cm.radial_segments = 14
    var mi = MeshInstance3D.new()
    mi.mesh = cm
    mi.material_override = mat
    mi.position = pos
    mi.rotation = rot
    host.add_child(mi)
    return mi

func _environment() -> void:
    env_node = WorldEnvironment.new()
    var e = Environment.new()
    e.background_mode = Environment.BG_SKY
    var sky = Sky.new()
    var psm = ProceduralSkyMaterial.new()
    psm.sky_top_color = Color(0.19, 0.30, 0.45)
    psm.sky_horizon_color = Color(0.66, 0.68, 0.64)
    psm.ground_bottom_color = Color(0.28, 0.27, 0.22)
    psm.ground_horizon_color = Color(0.55, 0.53, 0.45)
    psm.sun_angle_max = 22.0
    psm.sun_curve = 0.12
    sky.sky_material = psm
    e.sky = sky
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_energy = 0.75
    e.tonemap_mode = Environment.TONE_MAPPER_ACES
    e.tonemap_exposure = 1.05
    e.fog_enabled = true
    e.fog_light_color = Color(0.62, 0.64, 0.59)
    e.fog_density = 0.0042
    e.fog_sky_affect = 0.35
    e.glow_enabled = true
    e.glow_intensity = 0.25
    e.glow_bloom = 0.08
    e.glow_hdr_threshold = 1.15
    env_node.environment = e
    add_child(env_node)
    sun = DirectionalLight3D.new()
    sun.light_energy = 1.45
    sun.light_color = Color(1.0, 0.93, 0.80)
    sun.rotation = Vector3(deg_to_rad(-48.0), deg_to_rad(38.0), deg_to_rad(-15.0))
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 95.0
    sun.shadow_bias = 0.03
    sun.shadow_normal_bias = 0.6
    add_child(sun)

func _ground() -> void:
    solid_box(Vector3(116, 1, 116), Vector3(0, -0.5, 0), _mat("asphalt", Color(0.85, 0.86, 0.82), 34.0))
    var dirt = _mat("sand", Color(0.92, 0.90, 0.83), 6.0)
    var conc = _mat("concrete", Color(0.95, 0.95, 0.93), 8.0)
    for i in range(16):
        visual_box(Vector3(G.rng_range(4.0, 12.0), 0.012, G.rng_range(4.0, 12.0)),
            Vector3(G.rng_range(-48, 48), 0.008, G.rng_range(-48, 48)), dirt)
    solid_box(Vector3(8, 0.06, 100), Vector3(0, 0.02, 0), conc)
    solid_box(Vector3(100, 0.06, 8), Vector3(0, 0.025, 0), conc)
    var paint = _flat(Color(0.72, 0.68, 0.40), 0.95)
    for i in range(9):
        visual_box(Vector3(0.18, 0.012, 3.4), Vector3(-6.0, 0.058, -40.0 + i * 10.0), paint)
        visual_box(Vector3(0.18, 0.012, 3.4), Vector3(6.0, 0.058, -40.0 + i * 10.0), paint)

func _perimeter() -> void:
    var wall = _mat("concrete", Color(0.83, 0.83, 0.80), 4.0)
    var h = 5.2
    solid_box(Vector3(112, h, 1.2), Vector3(0, h * 0.5, -56), wall)
    solid_box(Vector3(112, h, 1.2), Vector3(0, h * 0.5, 56), wall)
    solid_box(Vector3(1.2, h, 112), Vector3(-56, h * 0.5, 0), wall)
    solid_box(Vector3(1.2, h, 112), Vector3(56, h * 0.5, 0), wall)
    var wire = _flat(Color(0.30, 0.31, 0.29), 0.5, 0.7)
    for i in range(28):
        var x = -54.0 + i * 4.0
        visual_cyl(0.035, 1.1, Vector3(x, h + 0.5, -56), wire, Vector3(0, 0, PI * 0.5))
        visual_cyl(0.035, 1.1, Vector3(x, h + 0.5, 56), wire, Vector3(0, 0, PI * 0.5))
    visual_box(Vector3(112, 0.05, 0.05), Vector3(0, h + 1.0, -56), wire)
    visual_box(Vector3(112, 0.05, 0.05), Vector3(0, h + 1.0, 56), wire)

func _wall_with_door(cx: float, cz: float, w: float, d: float, height: float, mat: Material, axis: String) -> void:
    var gap = 1.6
    var seg = (w - gap) * 0.5
    if axis == "x":
        solid_box(Vector3(seg, height, d), Vector3(cx - gap * 0.5 - seg * 0.5, height * 0.5, cz), mat)
        solid_box(Vector3(seg, height, d), Vector3(cx + gap * 0.5 + seg * 0.5, height * 0.5, cz), mat)
        solid_box(Vector3(gap, height * 0.35, d), Vector3(cx, height * 0.825, cz), mat)
    else:
        solid_box(Vector3(d, height, seg), Vector3(cx, height * 0.5, cz - gap * 0.5 - seg * 0.5), mat)
        solid_box(Vector3(d, height, seg), Vector3(cx, height * 0.5, cz + gap * 0.5 + seg * 0.5), mat)
        solid_box(Vector3(d, height * 0.35, gap), Vector3(cx, height * 0.825, cz), mat)

func _building(pos: Vector3, w: float, d: float, h: float, kind: String, tint: Color) -> void:
    var mat = _mat(kind, tint, 3.0)
    var dark = _flat(Color(0.13, 0.14, 0.14), 0.85)
    _wall_with_door(pos.x, pos.z - d * 0.5, w, 0.45, h, mat, "x")
    _wall_with_door(pos.x, pos.z + d * 0.5, w, 0.45, h, mat, "x")
    _wall_with_door(pos.x - w * 0.5, pos.z, d, 0.45, h, mat, "z")
    _wall_with_door(pos.x + w * 0.5, pos.z, d, 0.45, h, mat, "z")
    solid_box(Vector3(w + 0.9, 0.28, d + 0.9), Vector3(pos.x, h + 0.14, pos.z), _mat("metal", Color(0.55, 0.57, 0.58), 3.0))
    visual_box(Vector3(w + 1.0, 0.45, 0.22), Vector3(pos.x, h + 0.45, pos.z - d * 0.5), dark)
    visual_box(Vector3(w + 1.0, 0.45, 0.22), Vector3(pos.x, h + 0.45, pos.z + d * 0.5), dark)
    _cover_ring(pos, maxf(w, d) * 0.65 + 2.0, 6)

func _compound() -> void:
    _building(Vector3(0, 0, 2), 15.0, 11.0, 4.6, "concrete", Color(0.88, 0.86, 0.79))
    _building(Vector3(-24, 0, 20), 10.0, 8.0, 3.8, "concrete", Color(0.72, 0.74, 0.70))
    _building(Vector3(26, 0, -22), 11.0, 9.0, 4.0, "concrete", Color(0.78, 0.76, 0.70))
    _building(Vector3(-38, 0, -8), 7.0, 6.0, 3.2, "rust", Color(0.9, 0.8, 0.7))
    var metal = _flat(Color(0.32, 0.34, 0.36), 0.4, 0.8)
    visual_cyl(0.09, 8.0, Vector3(4.5, 8.5, 2.0), metal)
    for i in range(4):
        visual_box(Vector3(0.05, 0.05, 2.4 - i * 0.4), Vector3(4.5, 6.5 + i * 1.1, 2.0), metal)
    visual_cyl(0.12, 0.18, Vector3(4.5, 12.6, 2.0), _flat(Color(0.95, 0.12, 0.10), 0.4, 0.0, 2.0))

func _site_marker(pos: Vector3, label: String) -> void:
    var ring = CylinderMesh.new()
    ring.top_radius = 3.1
    ring.bottom_radius = 3.1
    ring.height = 0.025
    ring.radial_segments = 32
    var mi = MeshInstance3D.new()
    mi.mesh = ring
    mi.material_override = G.materials.ghost(Color(1.0, 0.55, 0.12))
    mi.position = pos + Vector3(0, 0.05, 0)
    root.add_child(mi)
    var l = OmniLight3D.new()
    l.light_color = Color(1.0, 0.52, 0.18)
    l.light_energy = 1.6
    l.omni_range = 8.0
    l.position = pos + Vector3(0, 1.6, 0)
    root.add_child(l)
    lamps.append({"light": l, "base": 1.6, "phase": randf() * 6.28})
    solid_box(Vector3(1.1, 0.75, 0.8), pos + Vector3(0, 0.38, 0), _mat("metal", Color(0.38, 0.42, 0.36), 1.0))
    visual_box(Vector3(0.72, 0.10, 0.45), pos + Vector3(0, 0.80, 0), _flat(Color(0.85, 0.20, 0.12), 0.5, 0.2, 1.2))
    sites.append({"name": label, "pos": pos, "marker": mi, "light": l})

func _sites() -> void:
    _site_marker(Vector3(-27, 0, -25), "A")
    _site_marker(Vector3(27, 0, 25), "B")

func _container(pos: Vector3, yaw: float, color: Color) -> void:
    var holder = Node3D.new()
    holder.position = pos
    holder.rotation.y = yaw
    root.add_child(holder)
    var mat = _mat("metal", color, 2.0)
    solid_box(Vector3(6.0, 2.6, 2.45), Vector3(0, 1.3, 0), mat, Vector3.ZERO, G.L_WORLD, holder)
    var rib = _flat(color.darkened(0.35), 0.6, 0.55)
    for i in range(11):
        visual_box(Vector3(0.055, 2.45, 2.5), Vector3(-2.7 + i * 0.54, 1.3, 0), rib, Vector3.ZERO, holder)
    visual_box(Vector3(6.05, 0.10, 2.5), Vector3(0, 2.6, 0), rib, Vector3.ZERO, holder)
    _cover_ring(pos, 4.5, 5)

func _containers() -> void:
    var cols = [Color(0.34, 0.39, 0.30), Color(0.48, 0.32, 0.24), Color(0.28, 0.36, 0.42), Color(0.44, 0.43, 0.36)]
    var data = [[Vector3(-14, 0, -18), 0.0], [Vector3(-14, 0, -12), 0.0],
        [Vector3(16, 0, 14), PI * 0.5], [Vector3(16, 0, 20), PI * 0.5],
        [Vector3(-40, 0, 26), 0.3], [Vector3(39, 0, -30), -0.4],
        [Vector3(8, 0, 36), PI * 0.5], [Vector3(-8, 0, -38), 0.0]]
    for i in range(data.size()):
        _container(data[i][0], data[i][1], cols[i % cols.size()])

func _hesco(pos: Vector3, yaw: float, length: float) -> void:
    var holder = Node3D.new()
    holder.position = pos
    holder.rotation.y = yaw
    root.add_child(holder)
    var mat = _mat("fabric", Color(0.68, 0.63, 0.48), 2.0)
    var n = int(length / 1.1)
    for i in range(n):
        solid_box(Vector3(1.06, 1.55, 0.85), Vector3(-length * 0.5 + 0.55 + i * 1.1, 0.78, 0), mat, Vector3.ZERO, G.L_WORLD, holder)
    _cover_ring(pos, length * 0.5 + 1.0, 4)

func _sandbags(pos: Vector3, yaw: float, length: float) -> void:
    var holder = Node3D.new()
    holder.position = pos
    holder.rotation.y = yaw
    root.add_child(holder)
    var mat = _mat("fabric", Color(0.72, 0.66, 0.48), 2.0)
    var n = int(length / 0.85)
    for layer in range(3):
        for i in range(n - layer % 2):
            solid_box(Vector3(0.80, 0.30, 0.55),
                Vector3(-length * 0.5 + 0.42 + i * 0.85 + (layer % 2) * 0.42, 0.16 + layer * 0.29, 0),
                mat, Vector3.ZERO, G.L_WORLD, holder)
    _cover_ring(pos, length * 0.5 + 1.0, 5)

func _jersey(pos: Vector3, yaw: float) -> void:
    var holder = Node3D.new()
    holder.position = pos
    holder.rotation.y = yaw
    root.add_child(holder)
    var mat = _mat("concrete", Color(0.86, 0.85, 0.80), 1.0)
    solid_box(Vector3(2.6, 0.55, 0.42), Vector3(0, 0.28, 0), mat, Vector3.ZERO, G.L_WORLD, holder)
    solid_box(Vector3(2.6, 0.42, 0.72), Vector3(0, 0.62, 0), mat, Vector3.ZERO, G.L_WORLD, holder)
    _cover_ring(pos, 2.2, 3)

func _field_fortifications() -> void:
    _hesco(Vector3(-27, 0, -18), 0.0, 6.6)
    _hesco(Vector3(-20, 0, -27), PI * 0.5, 5.5)
    _sandbags(Vector3(-34, 0, -25), PI * 0.5, 5.1)
    _hesco(Vector3(27, 0, 18), 0.0, 6.6)
    _hesco(Vector3(20, 0, 27), PI * 0.5, 5.5)
    _sandbags(Vector3(34, 0, 25), PI * 0.5, 5.1)
    _jersey(Vector3(-6, 0, -30), 0.0)
    _jersey(Vector3(-2.6, 0, -30), 0.0)
    _jersey(Vector3(6, 0, 30), 0.0)
    _jersey(Vector3(9.4, 0, 30), 0.0)
    _jersey(Vector3(-30, 0, 8), PI * 0.5)
    _jersey(Vector3(30, 0, -8), PI * 0.5)

func _tower(pos: Vector3) -> void:
    var metal = _flat(Color(0.30, 0.33, 0.31), 0.55, 0.65)
    var wood = _mat("wood", Color(0.75, 0.70, 0.60), 1.0)
    for sx in range(-1, 2, 2):
        for sz in range(-1, 2, 2):
            solid_box(Vector3(0.24, 6.0, 0.24), pos + Vector3(sx * 1.5, 3.0, sz * 1.5), metal)
    solid_box(Vector3(4.2, 0.25, 4.2), pos + Vector3(0, 6.1, 0), wood)
    for sx in range(-1, 2, 2):
        solid_box(Vector3(0.14, 1.1, 4.2), pos + Vector3(sx * 2.0, 6.75, 0), metal)
    for sz in range(-1, 2, 2):
        solid_box(Vector3(4.2, 1.1, 0.14), pos + Vector3(0, 6.75, sz * 2.0), metal)
    solid_box(Vector3(4.8, 0.18, 4.8), pos + Vector3(0, 8.0, 0), _mat("metal", Color(0.42, 0.45, 0.40), 1.0))
    for i in range(9):
        solid_box(Vector3(0.10, 0.10, 1.1), pos + Vector3(-1.6 + i * 0.4, 1.0 + i * 0.55, 2.15), metal)
    var lamp = OmniLight3D.new()
    lamp.light_energy = 2.2
    lamp.light_color = Color(1.0, 0.90, 0.72)
    lamp.omni_range = 22.0
    lamp.position = pos + Vector3(0, 7.4, 0)
    root.add_child(lamp)
    visual_cyl(0.25, 0.35, pos + Vector3(0, 7.7, 0), _flat(Color(0.95, 0.90, 0.70), 0.3, 0.1, 1.6))
    _cover_ring(pos, 4.0, 5)

func _towers() -> void:
    _tower(Vector3(-43, 0, -40))
    _tower(Vector3(43, 0, 40))

func _crate(pos: Vector3, s: float = 1.0) -> void:
    var mat = _mat("wood", Color(0.72, 0.66, 0.50), 1.0)
    solid_box(Vector3(s, s, s), pos + Vector3(0, s * 0.5, 0), mat)
    visual_box(Vector3(s * 1.02, 0.055, s * 1.02), pos + Vector3(0, s * 0.9, 0), _flat(Color(0.32, 0.28, 0.20), 0.7, 0.25))
    _cover_ring(pos, s * 0.9 + 1.0, 3)

func _barrel(pos: Vector3, color: Color) -> void:
    var mat = _flat(color, 0.6, 0.55)
    var sb = StaticBody3D.new()
    sb.collision_layer = G.L_WORLD
    sb.collision_mask = 0
    sb.position = pos + Vector3(0, 0.52, 0)
    var cs = CollisionShape3D.new()
    var cy = CylinderShape3D.new()
    cy.radius = 0.34
    cy.height = 1.04
    cs.shape = cy
    sb.add_child(cs)
    var cm = CylinderMesh.new()
    cm.top_radius = 0.34
    cm.bottom_radius = 0.34
    cm.height = 1.04
    var mi = MeshInstance3D.new()
    mi.mesh = cm
    mi.material_override = mat
    sb.add_child(mi)
    root.add_child(sb)
    props.append(sb)
    var rim = _flat(color.darkened(0.35), 0.5, 0.7)
    visual_cyl(0.36, 0.055, pos + Vector3(0, 0.75, 0), rim)
    visual_cyl(0.36, 0.055, pos + Vector3(0, 0.28, 0), rim)
    _cover_ring(pos, 1.2, 2)

func _truck(pos: Vector3, yaw: float) -> void:
    var holder = Node3D.new()
    holder.position = pos
    holder.rotation.y = yaw
    root.add_child(holder)
    var olive = _mat("camo", Color(0.72, 0.76, 0.62), 1.0)
    var dark = _flat(Color(0.10, 0.11, 0.11), 0.85)
    solid_box(Vector3(2.3, 1.5, 4.6), Vector3(0, 1.25, 0), olive, Vector3.ZERO, G.L_WORLD, holder)
    solid_box(Vector3(2.2, 1.2, 1.7), Vector3(0, 1.85, -1.7), olive, Vector3.ZERO, G.L_WORLD, holder)
    for sx in range(-1, 2, 2):
        for sz in range(-1, 2, 2):
            visual_cyl(0.48, 0.30, Vector3(sx * 1.15, 0.48, sz * 1.55), dark, Vector3(0, 0, PI * 0.5), holder)
    _cover_ring(pos, 3.6, 5)

func _clutter() -> void:
    var crate_spots = [Vector3(-11, 0, -24), Vector3(-9.5, 0, -24), Vector3(-10.2, 0, -22.7),
        Vector3(13, 0, 22), Vector3(14.2, 0, 22), Vector3(13.6, 0, 23.2),
        Vector3(-33, 0, 13), Vector3(33, 0, -13), Vector3(0, 0, 12), Vector3(3, 0, -12)]
    for i in range(crate_spots.size()):
        _crate(crate_spots[i], 0.85 if i % 3 else 1.15)
    var barrel_colors = [Color(0.35, 0.42, 0.28), Color(0.52, 0.28, 0.18), Color(0.30, 0.38, 0.44)]
    var barrel_spots = [Vector3(-22, 0, -30), Vector3(-20.8, 0, -30.4), Vector3(22, 0, 30),
        Vector3(23.2, 0, 30.3), Vector3(-44, 0, 6), Vector3(44, 0, -6), Vector3(6, 0, -6), Vector3(-6, 0, 8)]
    for i in range(barrel_spots.size()):
        _barrel(barrel_spots[i], barrel_colors[i % barrel_colors.size()])
    _truck(Vector3(-12, 0, 34), 0.35)
    _truck(Vector3(14, 0, -34), -0.5)
    var tent = _mat("fabric", Color(0.55, 0.57, 0.45), 2.0)
    solid_box(Vector3(5.0, 0.15, 4.0), Vector3(-40, 0.08, -22), tent)
    for sx in range(-1, 2, 2):
        visual_box(Vector3(0.12, 2.4, 0.12), Vector3(-40 + sx * 2.4, 1.2, -22), _flat(Color(0.3, 0.32, 0.3), 0.6, 0.5))
    visual_box(Vector3(5.4, 0.12, 4.4), Vector3(-40, 2.45, -22), tent)
    var rifle = G.models.sniper_rifle_model()
    if rifle != null:
        rifle.position = Vector3(0, 1.20, 12.0)
        rifle.rotation.y = 0.6
        root.add_child(rifle)

func _light_pole(pos: Vector3) -> void:
    var metal = _flat(Color(0.32, 0.34, 0.33), 0.55, 0.6)
    visual_cyl(0.10, 7.0, Vector3(pos.x, 3.5, pos.z), metal)
    visual_box(Vector3(0.9, 0.14, 0.2), Vector3(pos.x, 7.0, pos.z), metal)
    visual_box(Vector3(0.75, 0.06, 0.16), Vector3(pos.x, 6.91, pos.z), _flat(Color(1.0, 0.93, 0.75), 0.3, 0.0, 2.4))
    var l = OmniLight3D.new()
    l.light_energy = 1.6
    l.light_color = Color(1.0, 0.91, 0.76)
    l.omni_range = 19.0
    l.position = pos + Vector3(0, 6.8, 0)
    root.add_child(l)

func _lights() -> void:
    for p in [Vector3(-18, 0, -6), Vector3(18, 0, 6), Vector3(-32, 0, 30),
              Vector3(32, 0, -30), Vector3(0, 0, -42), Vector3(0, 0, 42)]:
        _light_pole(p)

func _cover_ring(pos: Vector3, radius: float, count: int) -> void:
    for i in range(count):
        var a = TAU * float(i) / float(count) + randf() * 0.35
        cover_points.append(pos + Vector3(cos(a) * radius, 0.0, sin(a) * radius))

func _spawns() -> void:
    for i in range(6):
        spawns[0].append(Vector3(-14.0 + i * 5.5, 0.1, -48.0 + randf() * 3.0))
        spawns[1].append(Vector3(-14.0 + i * 5.5, 0.1, 45.0 - randf() * 3.0))

func nearest_cover(pos: Vector3, threat: Vector3 = Vector3.ZERO) -> Vector3:
    var best = pos
    var best_score = -INF
    for p in cover_points:
        var d = p.distance_to(pos)
        if d > 22.0 or d < 1.5:
            continue
        var score = -d
        if threat != Vector3.ZERO:
            score += (p - threat).normalized().dot((pos - threat).normalized()) * 8.0
        score += randf() * 2.0
        if score > best_score:
            best_score = score
            best = p
    return best

func site_at(pos: Vector3) -> Dictionary:
    for s in sites:
        if Vector2(s.pos.x, s.pos.z).distance_to(Vector2(pos.x, pos.z)) < 3.4:
            return s
    return {}

func _process(delta: float) -> void:
    time += delta
    for l in lamps:
        var light: OmniLight3D = l.light
        light.light_energy = l.base * (0.35 + 0.65 * absf(sin(time * 2.2 + l.phase)))
