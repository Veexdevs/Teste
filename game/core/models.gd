extends Node
## Carregador runtime de glTF/GLB (sem importador do editor) + armas
## procedurais de fallback. Os GLB ficam com extensao .bin para serem
## copiados como bytes puros para o PCK.

var cache = {}
const MODEL_DIR = "res://game/assets/models/"
const WEAPON_DIR = "res://game/assets/models/weapons/"

func _ready() -> void:
    G.note("models: runtime glTF loader pronto")

func has_file(path: String) -> bool:
    return FileAccess.file_exists(path)

func _collect_aabb(node: Node, xf: Transform3D, out: Array) -> void:
    var cur = xf
    if node is Node3D:
        cur = xf * node.transform
    if node is MeshInstance3D and node.mesh != null:
        out.append(cur * node.mesh.get_aabb())
    for c in node.get_children():
        _collect_aabb(c, cur, out)

func bounds(node: Node3D) -> AABB:
    var boxes: Array = []
    _collect_aabb(node, Transform3D.IDENTITY, boxes)
    if boxes.is_empty():
        return AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1.8, 1))
    var total: AABB = boxes[0]
    for i in range(1, boxes.size()):
        total = total.merge(boxes[i])
    return total

func fit(node: Node3D, height: float, center_xz: bool = true) -> Node3D:
    var wrap = Node3D.new()
    wrap.add_child(node)
    var bb = bounds(node)
    if bb.size.y < 0.0001:
        return wrap
    var s = height / bb.size.y
    node.scale = Vector3(s, s, s)
    node.position = Vector3(
        -(bb.position.x + bb.size.x * 0.5) * s if center_xz else 0.0,
        -bb.position.y * s,
        -(bb.position.z + bb.size.z * 0.5) * s if center_xz else 0.0)
    return wrap

func fit_longest(node: Node3D, length: float) -> Node3D:
    var wrap = Node3D.new()
    var inner = Node3D.new()
    inner.add_child(node)
    wrap.add_child(inner)
    var bb = bounds(node)
    var d = bb.size
    if d.x > d.y and d.x > d.z:
        inner.rotation.y = PI * 0.5
        bb = bounds(inner)
    var s = length / maxf(bb.size.z, 0.0001)
    inner.scale = Vector3(s, s, s)
    inner.position = Vector3(
        -(bb.position.x + bb.size.x * 0.5) * s,
        -(bb.position.y + bb.size.y * 0.5) * s,
        -(bb.position.z + bb.size.z * 0.5) * s - length * 0.5)
    return wrap

func load_glb(key: String, path: String) -> Node3D:
    if cache.has(key):
        return cache[key]
    if not FileAccess.file_exists(path):
        G.note("models: ficheiro ausente " + path)
        return null
    var bytes = FileAccess.get_file_as_bytes(path)
    var doc = GLTFDocument.new()
    var state = GLTFState.new()
    var err = doc.append_from_buffer(bytes, "", state)
    if err != OK:
        G.note("models: GLTF erro %d em %s" % [err, path])
        return null
    var scene = doc.generate_scene(state)
    if scene == null:
        G.note("models: cena vazia " + path)
        return null
    cache[key] = scene
    G.note("models: carregado %s (%d bytes, %d nos)" % [key, bytes.size(), _count(scene)])
    return scene

func _count(n: Node) -> int:
    var c = 1
    for ch in n.get_children():
        c += _count(ch)
    return c

func instance(key: String, path: String) -> Node3D:
    var src = load_glb(key, path)
    if src == null:
        return null
    return src.duplicate() as Node3D

func soldier_model() -> Node3D:
    var n = instance("soldier", MODEL_DIR + "soldier.bin")
    if n == null:
        return placeholder_soldier()
    return fit(n, 1.78)

func helmet_model() -> Node3D:
    var n = instance("helmet", MODEL_DIR + "helmet.bin")
    if n == null:
        return null
    return fit(n, 0.26, true)

func sniper_rifle_model() -> Node3D:
    var n = instance("sniper_glb", MODEL_DIR + "sniper_rifle.bin")
    if n == null:
        return null
    assign_material(n, G.materials.flat(Color(0.16, 0.17, 0.18), 0.5, 0.65))
    return fit_longest(n, 1.05)

func assign_material(n: Node, mat: Material) -> void:
    if n is MeshInstance3D:
        n.material_override = mat
    for c in n.get_children():
        assign_material(c, mat)

func tint_model(n: Node, tint: Color) -> void:
    if n is MeshInstance3D:
        var base: Material = n.material_override
        if base == null:
            var m = n.mesh as Mesh
            if m != null and m.get_surface_count() > 0:
                base = m.surface_get_material(0)
        var dup: Material = base.duplicate() if base != null else StandardMaterial3D.new()
        if dup is StandardMaterial3D:
            dup.albedo_color = tint
        n.material_override = dup
    for c in n.get_children():
        tint_model(c, tint)

func box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var m = BoxMesh.new()
    m.size = size
    var mi = MeshInstance3D.new()
    mi.mesh = m
    mi.material_override = mat
    mi.position = pos
    mi.rotation = rot
    parent.add_child(mi)
    return mi

func cyl(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var m = CylinderMesh.new()
    m.top_radius = radius
    m.bottom_radius = radius
    m.height = height
    m.radial_segments = 12
    var mi = MeshInstance3D.new()
    mi.mesh = m
    mi.material_override = mat
    mi.position = pos
    mi.rotation = rot
    parent.add_child(mi)
    return mi

func placeholder_soldier() -> Node3D:
    var root = Node3D.new()
    var mat = G.materials.get_mat("fabric", Color(0.55, 0.58, 0.45))
    var skin = G.materials.flat(Color(0.62, 0.48, 0.36))
    box(root, Vector3(0.42, 0.62, 0.25), Vector3(0, 1.24, 0), mat)
    box(root, Vector3(0.36, 0.20, 0.26), Vector3(0, 1.66, 0), skin)
    box(root, Vector3(0.13, 0.62, 0.15), Vector3(-0.30, 1.18, 0), mat)
    box(root, Vector3(0.13, 0.62, 0.15), Vector3(0.30, 1.18, 0), mat)
    box(root, Vector3(0.16, 0.82, 0.19), Vector3(-0.12, 0.42, 0), mat)
    box(root, Vector3(0.16, 0.82, 0.19), Vector3(0.12, 0.42, 0), mat)
    return root

func weapon_model(kind: String) -> Node3D:
    var candidates = {
        "rifle": ["arms_m4a1.bin", "ak47.bin", "m4a1.bin", "ak47_low.bin"],
        "smg": ["vm_mp5.bin", "assault_rifle.bin"],
        "sniper": ["sniper_rifle.bin"],
        "pistol": ["pistol.bin"],
    }
    var list: Array = candidates.get(kind, [])
    for f in list:
        var p = WEAPON_DIR + f
        if FileAccess.file_exists(p):
            var glb = instance("w_" + f, p)
            if glb != null:
                var target = 0.85
                if kind == "smg":
                    target = 0.62
                elif kind == "sniper":
                    target = 1.05
                elif kind == "pistol":
                    target = 0.28
                var w = fit_longest(glb, target)
                w.set_meta("from_glb", true)
                return w
    return procedural_weapon(kind)

func procedural_weapon(kind: String) -> Node3D:
    var root = Node3D.new()
    root.set_meta("from_glb", false)
    var metal = G.materials.flat(Color(0.115, 0.125, 0.135), 0.44, 0.78)
    var polymer = G.materials.flat(Color(0.085, 0.09, 0.095), 0.82, 0.05)
    var tan = G.materials.flat(Color(0.36, 0.33, 0.24), 0.78, 0.08)
    var steel = G.materials.flat(Color(0.30, 0.32, 0.34), 0.32, 0.9)
    var glass = G.materials.glass(Color(0.20, 0.42, 0.52))
    var short = kind == "pistol"
    var smg = kind == "smg"
    var snip = kind == "sniper"
    var L = 0.74
    if short:
        L = 0.26
    elif smg:
        L = 0.55
    elif snip:
        L = 0.95
    box(root, Vector3(0.075, 0.105, 0.30 if not short else 0.16), Vector3(0, 0, 0.04), metal)
    cyl(root, 0.014, L * 0.62, Vector3(0, 0.005, -L * 0.42), steel, Vector3(PI * 0.5, 0, 0))
    box(root, Vector3(0.066, 0.062, L * 0.36), Vector3(0, 0.006, -L * 0.28), tan if not short else polymer)
    box(root, Vector3(0.052, 0.012, L * 0.34), Vector3(0, 0.046, -L * 0.28), polymer)
    for i in range(5):
        box(root, Vector3(0.054, 0.006, 0.012), Vector3(0, 0.054, -L * 0.12 - i * 0.05), metal)
    cyl(root, 0.022, 0.055, Vector3(0, 0.005, -L * 0.74), metal, Vector3(PI * 0.5, 0, 0))
    box(root, Vector3(0.058, 0.135, 0.072), Vector3(0, -0.115, 0.115), polymer, Vector3(-0.22, 0, 0))
    if not short:
        box(root, Vector3(0.058, 0.155, 0.075), Vector3(0, -0.135, -0.045), metal, Vector3(0.16, 0, 0))
    if not short:
        box(root, Vector3(0.062, 0.10, 0.22), Vector3(0, -0.012, 0.30), tan if not snip else polymer)
        box(root, Vector3(0.07, 0.135, 0.035), Vector3(0, -0.02, 0.415), polymer)
    if snip:
        cyl(root, 0.026, 0.19, Vector3(0, 0.082, -0.02), metal, Vector3(PI * 0.5, 0, 0))
        cyl(root, 0.030, 0.012, Vector3(0, 0.082, -0.115), glass, Vector3(PI * 0.5, 0, 0))
    elif short:
        box(root, Vector3(0.012, 0.018, 0.018), Vector3(0, 0.062, -0.06), metal)
    else:
        box(root, Vector3(0.038, 0.038, 0.095), Vector3(0, 0.075, 0.005), metal)
        cyl(root, 0.017, 0.008, Vector3(0, 0.075, -0.05), glass, Vector3(PI * 0.5, 0, 0))
    box(root, Vector3(0.040, 0.012, 0.055), Vector3(0.045, 0.028, 0.02), steel)
    var glove = G.materials.get_mat("fabric", Color(0.30, 0.31, 0.25))
    box(root, Vector3(0.095, 0.085, 0.13), Vector3(0.008, -0.132, 0.10), glove, Vector3(-0.22, 0, 0))
    if not short:
        box(root, Vector3(0.085, 0.075, 0.115), Vector3(-0.018, -0.065, -L * 0.30), glove, Vector3(0.12, 0.25, 0))
    return root
