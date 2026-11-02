extends Node3D
## Cidade em ruínas "CERRADO": quarteirões destruídos, janelas vazias,
## entulho, viaturas queimadas, candeeiros tortos, fumo e névoa densa.
## Tudo com texturas PBR fotorrealistas e paleta dessaturada.

var root: Node3D
var env_node: WorldEnvironment
var sun: DirectionalLight3D
var fill: DirectionalLight3D
var sites = []
var spawns = {0: [], 1: []}
var cover_points: Array = []
var props = []
var lamps = []
var smoke_balls = []
var fire_lights = []
var conc_for_ruin: StandardMaterial3D
var time = 0.0
var R: RandomNumberGenerator

func _ready() -> void:
    R = RandomNumberGenerator.new()
    R.seed = 48151623

func build() -> void:
    R.seed = 48151623
    root = Node3D.new()
    root.name = "Geometry"
    add_child(root)
    _environment()
    _perimeter()
    _ground()
    _ruins()
    _skyline()
    _rubble_field()
    _vehicles()
    _fieldworks()
    _lamps()
    _sites()
    _smoke()
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
    cm.radial_segments = 10
    var mi = MeshInstance3D.new()
    mi.mesh = cm
    mi.material_override = mat
    mi.position = pos
    mi.rotation = rot
    host.add_child(mi)
    return mi

# --- Iluminação / atmosfera ------------------------------------------------
func _environment() -> void:
    env_node = WorldEnvironment.new()
    var e = Environment.new()
    e.background_mode = Environment.BG_SKY
    var sky = Sky.new()
    var psm = ProceduralSkyMaterial.new()
    psm.sky_top_color = Color(0.19, 0.21, 0.22)
    psm.sky_horizon_color = Color(0.44, 0.44, 0.42)
    psm.ground_bottom_color = Color(0.23, 0.22, 0.20)
    psm.ground_horizon_color = Color(0.39, 0.38, 0.35)
    psm.sun_angle_max = 14.0
    psm.sun_curve = 0.09
    sky.sky_material = psm
    e.sky = sky
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_energy = 0.92
    e.tonemap_mode = Environment.TONE_MAPPER_ACES
    e.tonemap_exposure = 0.95
    e.fog_enabled = true
    e.fog_light_color = Color(0.37, 0.38, 0.37)
    e.fog_density = 0.0095
    e.fog_sky_affect = 0.62
    e.glow_enabled = true
    e.glow_intensity = 0.20
    e.glow_bloom = 0.06
    e.glow_hdr_threshold = 1.2
    env_node.environment = e
    add_child(env_node)
    sun = DirectionalLight3D.new()
    sun.light_energy = 1.15
    sun.light_color = Color(0.89, 0.89, 0.85)
    sun.rotation = Vector3(deg_to_rad(-52.0), deg_to_rad(32.0), deg_to_rad(-14.0))
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 95.0
    sun.shadow_bias = 0.03
    sun.shadow_normal_bias = 0.7
    add_child(sun)
    fill = DirectionalLight3D.new()
    fill.light_energy = 0.32
    fill.light_color = Color(0.55, 0.62, 0.72)
    fill.rotation = Vector3(deg_to_rad(-28.0), deg_to_rad(-140.0), deg_to_rad(20.0))
    fill.shadow_enabled = false
    add_child(fill)

# --- Limites e solo --------------------------------------------------------
func _perimeter() -> void:
    var conc = _mat("concrete", Color(0.72, 0.71, 0.68), 3.0)
    for side in [-1.0, 1.0]:
        for i in range(10):
            var z = -50.0 + i * 11.0
            if R.randf() < 0.16:
                continue
            var h = R.randf_range(3.2, 6.4)
            solid_box(Vector3(1.1, h, 10.2), Vector3(side * 56.0, h * 0.5, z), conc)
        for i in range(10):
            var x = -50.0 + i * 11.0
            if R.randf() < 0.16:
                continue
            var h = R.randf_range(3.2, 6.4)
            solid_box(Vector3(10.2, h, 1.1), Vector3(x, h * 0.5, side * 56.0), conc)

func _ground() -> void:
    solid_box(Vector3(124, 1, 124), Vector3(0, -0.5, 0), _mat("asphalt", Color(0.94, 0.94, 0.93), 30.0))
    visual_box(Vector3(11.2, 0.045, 116), Vector3(0, 0.012, 0), _mat("asphalt", Color(0.74, 0.74, 0.74), 15.0))
    var walk = _mat("concrete", Color(0.83, 0.82, 0.79), 2.6)
    for side in [-1.0, 1.0]:
        for i in range(11):
            if R.randf() < 0.20:
                continue
            var z = -52.0 + i * 10.4
            solid_box(Vector3(3.5, 0.20, R.randf_range(7.0, 9.6)),
                Vector3(side * 7.4, 0.10, z), walk)
    var paint = _flat(Color(0.50, 0.48, 0.41), 0.95)
    for i in range(14):
        if R.randf() < 0.30:
            continue
        visual_box(Vector3(0.13, 0.012, R.randf_range(2.0, 3.6)),
            Vector3(0, 0.042, -52.0 + i * 8.0), paint)
    # crateras e manchas de poeira
    var dust = _mat("dust", Color(0.80, 0.79, 0.75), 1.0)
    for i in range(24):
        var p = Vector3(R.randf_range(-46, 46), 0.018, R.randf_range(-46, 46))
        visual_box(Vector3(R.randf_range(2, 7), 0.012, R.randf_range(2, 7)), p, dust)

# --- Construção de fachadas em ruínas (uma só malha por edifício) ----------
func _st_box(st: SurfaceTool, xf: Transform3D, size: Vector3) -> void:
    var h = size * 0.5
    var v = [
        Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z),
        Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z),
        Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z),
        Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)]
    var faces = [[0, 1, 2, 3], [5, 4, 7, 6], [4, 0, 3, 7],
                 [1, 5, 6, 2], [3, 2, 6, 7], [4, 5, 1, 0]]
    var norms = [Vector3(0, 0, -1), Vector3(0, 0, 1), Vector3(-1, 0, 0),
                 Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 0)]
    var uvs = [Vector2(0, 0), Vector2(size.x * 0.5, 0),
               Vector2(size.x * 0.5, size.y * 0.5), Vector2(0, size.y * 0.5)]
    for fi in range(6):
        var n = xf.basis * norms[fi]
        var pts = []
        for k in faces[fi]:
            pts.append(xf * v[k])
        st.set_normal(n)
        st.set_uv(uvs[0]); st.add_vertex(pts[0])
        st.set_uv(uvs[1]); st.add_vertex(pts[1])
        st.set_uv(uvs[2]); st.add_vertex(pts[2])
        st.set_uv(uvs[0]); st.add_vertex(pts[0])
        st.set_uv(uvs[2]); st.add_vertex(pts[2])
        st.set_uv(uvs[3]); st.add_vertex(pts[3])

func _ruin(pos: Vector3, w: float, d: float, h: float, floors: int, yaw: float) -> void:
    var holder = Node3D.new()
    holder.position = pos
    holder.rotation.y = yaw
    root.add_child(holder)
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var dark_st = SurfaceTool.new()
    dark_st.begin(Mesh.PRIMITIVE_TRIANGLES)
    conc_for_ruin = G.materials.get_mat("concrete", Color(0.88, 0.87, 0.84), 1.0)
    var t = 0.62
    _facade_root(st, dark_st, holder, Vector3(0, 0, -d * 0.5), 0.0, w, h, floors, t)
    _facade_root(st, dark_st, holder, Vector3(0, 0, d * 0.5), 0.0, w, h, floors, t)
    _facade_root(st, dark_st, holder, Vector3(-w * 0.5, 0, 0), PI * 0.5, d, h, floors, t)
    _facade_root(st, dark_st, holder, Vector3(w * 0.5, 0, 0), PI * 0.5, d, h, floors, t)
    # lajes interiores partidas
    var fh = h / float(floors)
    for fl in range(1, floors):
        for k in range(3):
            if R.randf() < 0.30:
                continue
            var x = R.randf_range(-w * 0.35, w * 0.35)
            var z = R.randf_range(-d * 0.35, d * 0.35)
            _st_box(st, Transform3D(holder.transform.basis,
                pos + holder.transform.basis * Vector3(x, fl * fh, z)),
                Vector3(R.randf_range(2.0, 4.6), 0.22, R.randf_range(2.0, 4.6)))
    var mesh = st.commit()
    var mi = MeshInstance3D.new()
    mi.mesh = mesh
    conc_for_ruin.cull_mode = BaseMaterial3D.CULL_DISABLED
    mi.material_override = conc_for_ruin
    root.add_child(mi)
    props.append(mi)
    var dmesh = dark_st.commit()
    var dmi = MeshInstance3D.new()
    dmi.mesh = dmesh
    dmi.material_override = _flat(Color(0.045, 0.046, 0.046), 1.0)
    root.add_child(dmi)
    props.append(dmi)
    _cover_ring(pos, maxf(w, d) * 0.75 + 2.0, 7)


func _facade_root(st: SurfaceTool, dark_st: SurfaceTool, holder: Node3D, offset: Vector3, yaw: float, length: float, height: float, floors: int, thickness: float) -> void:
    var world_off = holder.position + offset.rotated(Vector3.UP, holder.rotation.y)
    var total_yaw = holder.rotation.y + yaw
    var base = Transform3D(Basis.from_euler(Vector3(0, total_yaw, 0)), world_off)
    var fh = height / float(floors)
    var win = maxi(2, int(length / 2.9))
    var step = length / float(win)
    var broken = R.randf() < 0.85
    for fl in range(floors):
        var y0 = fl * fh
        _st_box(st, Transform3D(base.basis, base.origin + Vector3(0, y0 + 0.20, 0)), Vector3(length, 0.40, thickness))
        if not (broken and fl == floors - 1 and R.randf() < 0.55):
            _st_box(st, Transform3D(base.basis, base.origin + Vector3(0, y0 + fh - 0.25, 0)), Vector3(length, 0.50, thickness))
        for i in range(win + 1):
            if broken and fl == floors - 1 and R.randf() < 0.48:
                continue
            if R.randf() < 0.07:
                continue
            var x = -length * 0.5 + i * step
            var p = base.origin + base.basis * Vector3(x, y0 + fh * 0.5, 0)
            _st_box(st, Transform3D(base.basis, p), Vector3(0.48, fh - 0.88, thickness))
        for i in range(win):
            if R.randf() < 0.14:
                continue
            var x = -length * 0.5 + step * (i + 0.5)
            var p = base.origin + base.basis * Vector3(x, y0 + fh * 0.5, -thickness * 0.62)
            _st_box(dark_st, Transform3D(base.basis, p), Vector3(step - 0.55, fh - 0.95, 0.05))
    for i in range(win + 1):
        if R.randf() < 0.55:
            var hh = R.randf_range(0.35, 1.7)
            var x = -length * 0.5 + i * step
            var p = base.origin + base.basis * Vector3(x, height + hh * 0.5, 0)
            _st_box(st, Transform3D(base.basis, p), Vector3(0.52, hh, thickness))
    var col = StaticBody3D.new()
    col.collision_layer = G.L_WORLD
    col.collision_mask = 0
    col.position = world_off
    col.rotation.y = total_yaw
    var cs = CollisionShape3D.new()
    var bs = BoxShape3D.new()
    bs.size = Vector3(length, height, thickness)
    cs.shape = bs
    cs.position = Vector3(0, height * 0.5, 0)
    col.add_child(cs)
    root.add_child(col)
    props.append(col)
    for i in range(5):
        var rx = R.randf_range(-length * 0.5, length * 0.5)
        var rh = R.randf_range(0.5, 1.2)
        var rb = Basis.from_euler(Vector3(R.randf_range(-0.3, 0.3), total_yaw, R.randf_range(-0.3, 0.3)))
        _st_box(st, Transform3D(rb,
            world_off + Vector3(rx, height + rh * 0.5, 0).rotated(Vector3.UP, total_yaw)),
            Vector3(0.035, rh, 0.035))

func _ruins() -> void:
    _ruin(Vector3(-20, 0, -14), 14.0, 11.0, 9.6, 3, 0.0)
    _ruin(Vector3(20, 0, 14), 13.0, 10.0, 9.6, 3, 0.06)
    _ruin(Vector3(-30, 0, 22), 11.0, 9.0, 6.4, 2, -0.22)
    _ruin(Vector3(31, 0, -24), 12.0, 9.5, 6.4, 2, 0.30)
    _ruin(Vector3(-6, 0, 34), 10.0, 8.0, 6.4, 2, -0.40)
    _ruin(Vector3(8, 0, -36), 10.5, 8.5, 9.6, 3, 0.18)
    # torre de esquina semi-derrubada
    _ruin(Vector3(-40, 0, -36), 8.0, 8.0, 12.8, 4, 0.12)

func _skyline() -> void:
    var conc = _mat("concrete", Color(0.58, 0.58, 0.56), 1.6)
    var dark = _flat(Color(0.09, 0.09, 0.09), 1.0)
    for i in range(30):
        var ang = R.randf_range(0.0, TAU)
        var dist = R.randf_range(64.0, 98.0)
        var p = Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
        var h = R.randf_range(9.0, 27.0)
        var w = R.randf_range(5.0, 12.0)
        var d = R.randf_range(5.0, 12.0)
        visual_box(Vector3(w, h, d), Vector3(p.x, h * 0.5, p.z), conc)
        for fl in range(int(h / 3.2)):
            for k in range(3):
                visual_box(Vector3(w * 0.22, 1.1, 0.06),
                    Vector3(p.x - w * 0.28 + k * w * 0.28, 2.2 + fl * 3.2, p.z - d * 0.5 - 0.04), dark)

# --- Entulho (MultiMesh: uma só chamada de desenho) ------------------------
func _rubble_field() -> void:
    var list = []
    var centres = [Vector3(-20, 0, -14), Vector3(20, 0, 14), Vector3(-30, 0, 22),
                   Vector3(31, 0, -24), Vector3(-6, 0, 34), Vector3(8, 0, -36),
                   Vector3(-40, 0, -36), Vector3(0, 0, -30), Vector3(0, 0, 28),
                   Vector3(-12, 0, 4), Vector3(14, 0, -6)]
    for c in centres:
        for i in range(28):
            var a = R.randf_range(0.0, TAU)
            var rr = R.randf_range(0.0, 8.5)
            var s = R.randf_range(0.16, 1.15)
            var p = c + Vector3(cos(a) * rr, s * 0.32, sin(a) * rr)
            var xf = Transform3D(Basis.from_euler(Vector3(R.randf_range(-0.45, 0.45), R.randf_range(0.0, TAU), R.randf_range(-0.45, 0.45))), p)
            xf.basis = xf.basis.scaled(Vector3(s, s * R.randf_range(0.45, 0.95), s * R.randf_range(0.7, 1.35)))
            list.append(xf)
    for i in range(90):
        var s = R.randf_range(0.12, 0.75)
        var p = Vector3(R.randf_range(-48, 48), s * 0.3, R.randf_range(-48, 48))
        var xf = Transform3D(Basis.from_euler(Vector3(R.randf_range(-0.4, 0.4), R.randf() * TAU, R.randf_range(-0.4, 0.4))), p)
        xf.basis = xf.basis.scaled(Vector3(s, s * 0.7, s))
        list.append(xf)
    var bm = BoxMesh.new()
    bm.size = Vector3(1, 1, 1)
    var mm = MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = bm
    mm.instance_count = list.size()
    for i in range(list.size()):
        mm.set_instance_transform(i, list[i])
    var mmi = MultiMeshInstance3D.new()
    mmi.multimesh = mm
    mmi.material_override = _mat("rubble", Color(0.82, 0.82, 0.80), 1.0)
    root.add_child(mmi)
    props.append(mmi)
    for c in centres:
        _cover_ring(c, 8.0, 5)
        if R.randf() < 0.6:
            solid_box(Vector3(R.randf_range(1.4, 2.6), R.randf_range(0.5, 1.1), R.randf_range(1.2, 2.2)),
                c + Vector3(R.randf_range(-5, 5), 0.45, R.randf_range(-5, 5)),
                _mat("concrete", Color(0.78, 0.77, 0.74), 1.0),
                Vector3(0, R.randf() * TAU, 0))

# --- Viaturas queimadas ----------------------------------------------------
func _burnt_car(pos: Vector3, yaw: float) -> void:
    var holder = Node3D.new()
    holder.position = pos
    holder.rotation.y = yaw
    root.add_child(holder)
    var burnt = _mat("burnt", Color(0.55, 0.55, 0.55), 1.0)
    var rust = _flat(Color(0.26, 0.16, 0.11), 0.85, 0.35)
    var glass = _flat(Color(0.06, 0.06, 0.06), 0.4, 0.2)
    solid_box(Vector3(2.05, 0.60, 4.30), Vector3(0, 0.55, 0), burnt, Vector3.ZERO, G.L_WORLD, holder)
    solid_box(Vector3(1.85, 0.66, 2.00), Vector3(0, 1.15, -0.25), burnt, Vector3.ZERO, G.L_WORLD, holder)
    visual_box(Vector3(1.70, 0.42, 0.05), Vector3(0, 1.20, -1.28), glass, Vector3.ZERO, holder)
    visual_box(Vector3(1.70, 0.42, 0.05), Vector3(0, 1.20, 0.78), glass, Vector3.ZERO, holder)
    for sx in [-1.0, 1.0]:
        for sz in [-1.0, 1.0]:
            visual_cyl(0.40, 0.24, Vector3(sx * 1.02, 0.40, sz * 1.42),
                _flat(Color(0.09, 0.09, 0.09), 0.95), Vector3(0, 0, PI * 0.5), holder)
    visual_box(Vector3(2.10, 0.08, 0.16), Vector3(0, 0.92, 2.16), rust, Vector3.ZERO, holder)
    visual_box(Vector3(0.36, 0.06, 0.10), Vector3(-0.68, 0.88, 2.18), rust, Vector3.ZERO, holder)
    _cover_ring(pos, 3.6, 5)

func _vehicles() -> void:
    var spots = [Vector3(-5.6, 0, -20), Vector3(5.8, 0, -8), Vector3(-6.2, 0, 12),
                 Vector3(6.0, 0, 26), Vector3(-8.0, 0, 34), Vector3(9.0, 0, -30),
                 Vector3(-6.4, 0, -42), Vector3(6.8, 0, 42)]
    for i in range(spots.size()):
        _burnt_car(spots[i], R.randf_range(-0.5, 0.5) + (0.0 if i % 2 == 0 else PI * 0.5))

# --- Trabalhos de campo (cobertura militar) --------------------------------
func _jersey(pos: Vector3, yaw: float) -> void:
    var holder = Node3D.new()
    holder.position = pos
    holder.rotation.y = yaw
    root.add_child(holder)
    var m = _mat("concrete", Color(0.80, 0.79, 0.76), 1.0)
    solid_box(Vector3(2.7, 0.55, 0.44), Vector3(0, 0.28, 0), m, Vector3.ZERO, G.L_WORLD, holder)
    solid_box(Vector3(2.7, 0.42, 0.74), Vector3(0, 0.63, 0), m, Vector3.ZERO, G.L_WORLD, holder)
    _cover_ring(pos, 2.3, 3)

func _sandbag_nest(pos: Vector3, yaw: float) -> void:
    var holder = Node3D.new()
    holder.position = pos
    holder.rotation.y = yaw
    root.add_child(holder)
    var m = _mat("fabric", Color(0.78, 0.74, 0.62), 1.0)
    for layer in range(3):
        for i in range(6 - layer % 2):
            solid_box(Vector3(0.78, 0.28, 0.52),
                Vector3(-2.2 + 0.42 + i * 0.82 + (layer % 2) * 0.41, 0.15 + layer * 0.27, 0),
                m, Vector3.ZERO, G.L_WORLD, holder)
    _cover_ring(pos, 3.4, 5)

func _fieldworks() -> void:
    _jersey(Vector3(-9.0, 0, -31), 0.0)
    _jersey(Vector3(-6.0, 0, -31), 0.0)
    _jersey(Vector3(9.0, 0, 31), 0.0)
    _jersey(Vector3(12.0, 0, 31), 0.0)
    _jersey(Vector3(-27, 0, -8), PI * 0.5)
    _jersey(Vector3(27, 0, 8), PI * 0.5)
    _sandbag_nest(Vector3(-27, 0, -25), PI * 0.5)
    _sandbag_nest(Vector3(27, 0, 25), PI * 0.5)
    _sandbag_nest(Vector3(-14, 0, 8), 0.4)
    _sandbag_nest(Vector3(16, 0, -10), -0.3)
    # blocos HESCO em betão/grade
    for p in [Vector3(-33, 0, -27), Vector3(-30, 0, -27), Vector3(33, 0, 27), Vector3(30, 0, 27)]:
        solid_box(Vector3(2.2, 1.75, 0.9), p + Vector3(0, 0.88, 0),
            _mat("concrete", Color(0.70, 0.69, 0.65), 1.4))
        _cover_ring(p, 2.4, 3)

# --- Candeeiros, cabos e fogo distante -------------------------------------
func _lamp(pos: Vector3, tilt: float) -> void:
    var metal = _flat(Color(0.22, 0.23, 0.22), 0.7, 0.55)
    visual_cyl(0.075, 6.6, Vector3(pos.x, 3.3, pos.z), metal, Vector3(0, 0, tilt))
    visual_box(Vector3(1.1, 0.09, 0.13), Vector3(pos.x + sin(tilt) * 0.9, 6.55, pos.z), metal, Vector3(0, 0, tilt))
    visual_box(Vector3(0.52, 0.055, 0.16), Vector3(pos.x + sin(tilt) * 1.3, 6.46, pos.z),
        _flat(Color(0.55, 0.54, 0.48), 0.4, 0.0, 0.35))
    var l = OmniLight3D.new()
    l.light_energy = 0.85
    l.light_color = Color(0.86, 0.83, 0.74)
    l.omni_range = 15.0
    l.position = Vector3(pos.x + sin(tilt) * 1.3, 6.3, pos.z)
    root.add_child(l)
    lamps.append({"light": l, "base": 0.85, "phase": R.randf() * 6.28})

func _lamps() -> void:
    for i in range(10):
        var side = -1.0 if i % 2 == 0 else 1.0
        _lamp(Vector3(side * 8.2, 0, -46.0 + i * 10.2), R.randf_range(-0.18, 0.18))
    # cabos pendentes entre postes
    var wire = _flat(Color(0.12, 0.12, 0.12), 0.9)
    for i in range(4):
        var z = -36.0 + i * 24.0
        visual_box(Vector3(0.025, 0.025, 16.4), Vector3(0, 6.0 + R.randf_range(-0.3, 0.3), z), wire,
            Vector3(R.randf_range(-0.05, 0.05), 0, R.randf_range(-0.04, 0.04)))
    for p in [Vector3(-34, 0, -40), Vector3(36, 0, 38), Vector3(0, 0, -49)]:
        var l = OmniLight3D.new()
        l.light_color = Color(1.0, 0.44, 0.14)
        l.light_energy = 2.6
        l.omni_range = 16.0
        l.position = p + Vector3(0, 1.2, 0)
        root.add_child(l)
        fire_lights.append({"light": l, "base": 2.6, "phase": R.randf() * 6.28})

# --- Objectivos ------------------------------------------------------------
func _sites() -> void:
    _site_marker(Vector3(-27, 0, -25), "A")
    _site_marker(Vector3(27, 0, 25), "B")

func _site_marker(pos: Vector3, label: String) -> void:
    var tm = TorusMesh.new()
    tm.inner_radius = 3.05
    tm.outer_radius = 3.18
    tm.ring_segments = 40
    tm.rings = 6
    var mi = MeshInstance3D.new()
    mi.mesh = tm
    mi.material_override = _flat(Color(0.95, 0.62, 0.14), 0.5, 0.0, 0.9)
    mi.position = pos + Vector3(0, 0.06, 0)
    root.add_child(mi)
    var l = OmniLight3D.new()
    l.light_color = Color(1.0, 0.58, 0.18)
    l.light_energy = 1.1
    l.omni_range = 7.0
    l.position = pos + Vector3(0, 1.4, 0)
    root.add_child(l)
    lamps.append({"light": l, "base": 1.1, "phase": R.randf() * 6.28})
    var lb = Label3D.new()
    lb.text = label
    lb.font_size = 96
    lb.modulate = Color(1.0, 0.68, 0.18, 0.85)
    lb.position = pos + Vector3(0, 3.4, 0)
    lb.billboard = 1
    root.add_child(lb)
    sites.append({"name": label, "pos": pos, "marker": mi, "light": l})

# --- Colunas de fumo -------------------------------------------------------
func _smoke_column(pos: Vector3, base: float) -> void:
    var mat = G.materials.smoke(Color(0.19, 0.19, 0.19), 0.15)
    for i in range(11):
        var sm = SphereMesh.new()
        sm.radius = 1.0
        sm.height = 2.0
        sm.radial_segments = 8
        sm.rings = 4
        var mi = MeshInstance3D.new()
        mi.mesh = sm
        mi.material_override = mat
        var p = pos + Vector3(R.randf_range(-2.2, 2.2), 2.0 + i * 2.1, R.randf_range(-2.2, 2.2))
        mi.position = p
        var s = base * (1.0 + i * 0.20)
        mi.scale = Vector3(s, s * 1.15, s)
        root.add_child(mi)
        smoke_balls.append({"node": mi, "y0": p.y, "phase": R.randf() * 6.28,
                            "speed": R.randf_range(0.16, 0.38), "x0": p.x, "z0": p.z})

func _smoke() -> void:
    _smoke_column(Vector3(-34, 0, -40), 2.3)
    _smoke_column(Vector3(36, 0, 38), 2.0)
    _smoke_column(Vector3(0, 0, -52), 1.5)
    _smoke_column(Vector3(-44, 0, 20), 1.2)

# --- Cobertura / spawns / consultas ----------------------------------------
func _cover_ring(pos: Vector3, radius: float, count: int) -> void:
    for i in range(count):
        var a = TAU * float(i) / float(count) + R.randf() * 0.4
        cover_points.append(pos + Vector3(cos(a) * radius, 0.0, sin(a) * radius))

func _spawns() -> void:
    for i in range(6):
        spawns[0].append(Vector3(-13.0 + i * 5.2, 0.12, -48.0 + R.randf() * 3.0))
        spawns[1].append(Vector3(-13.0 + i * 5.2, 0.12, 45.0 - R.randf() * 3.0))

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
        score += R.randf() * 2.0
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
        light.light_energy = l.base * (0.55 + 0.45 * absf(sin(time * 1.4 + l.phase)))
    for f in fire_lights:
        var fl: OmniLight3D = f.light
        fl.light_energy = f.base * (0.65 + 0.35 * absf(sin(time * 7.3 + f.phase)))
    for s in smoke_balls:
        var n: MeshInstance3D = s.node
        n.position.y = s.y0 + sin(time * s.speed + s.phase) * 1.4
        n.position.x = s.x0 + sin(time * s.speed * 0.6 + s.phase) * 0.8
        n.rotation.y += delta * 0.08
