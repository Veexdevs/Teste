extends Node
## Biblioteca de materiais: albedo fotorrealista (texturas PBR geradas) +
## normais/grão procedurais. Paleta dessaturada de cidade em ruínas.

var cache = {}
var tex_cache = {}
var photo = {}
var noise = FastNoiseLite.new()

const PHOTO_CONCRETE = "res://game/assets/textures/concrete_ruin.bin"
const PHOTO_ASPHALT = "res://game/assets/textures/asphalt_rubble.bin"

func _ready() -> void:
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.frequency = 0.06
    noise.fractal_octaves = 4
    noise.seed = 20261102
    _load_photo("concrete", PHOTO_CONCRETE)
    _load_photo("asphalt", PHOTO_ASPHALT)
    G.note("materiais: %d texturas fotograficas, %d procedural" % [photo.size(), tex_cache.size()])

func _load_photo(key: String, path: String) -> void:
    if not FileAccess.file_exists(path):
        G.note("materiais: textura ausente " + path)
        return
    var img = Image.new()
    if img.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
        G.note("materiais: PNG invalido " + path)
        return
    photo[key] = ImageTexture.create_from_image(img)

func _noise(x: float, y: float) -> float:
    return noise.get_noise_2d(x, y) * 0.5 + 0.5

func make_albedo(kind: String, size: int = 128) -> ImageTexture:
    var key = kind + "_" + str(size)
    if tex_cache.has(key):
        return tex_cache[key]
    var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.5, 0.5, 0.5, 1))
    var a = Color()
    var b = Color()
    var c = Color()
    var scale = 8.0
    match kind:
        "camo":
            a = Color(0.20, 0.22, 0.17); b = Color(0.34, 0.34, 0.25); c = Color(0.12, 0.14, 0.11); scale = 13.0
        "sand":
            a = Color(0.55, 0.52, 0.44); b = Color(0.67, 0.63, 0.53); c = Color(0.43, 0.40, 0.34); scale = 11.0
        "metal":
            a = Color(0.22, 0.24, 0.25); b = Color(0.33, 0.35, 0.36); c = Color(0.15, 0.17, 0.18); scale = 7.0
        "rust":
            a = Color(0.34, 0.19, 0.11); b = Color(0.48, 0.28, 0.14); c = Color(0.21, 0.15, 0.10); scale = 12.0
        "fabric":
            a = Color(0.17, 0.19, 0.15); b = Color(0.25, 0.26, 0.19); c = Color(0.11, 0.13, 0.10); scale = 22.0
        "wood":
            a = Color(0.30, 0.24, 0.17); b = Color(0.42, 0.33, 0.22); c = Color(0.21, 0.16, 0.11); scale = 6.0
        "soot":
            a = Color(0.13, 0.13, 0.13); b = Color(0.21, 0.21, 0.20); c = Color(0.08, 0.08, 0.08); scale = 15.0
        _:
            a = Color(0.36, 0.36, 0.35); b = Color(0.52, 0.52, 0.50); c = Color(0.26, 0.26, 0.25)
    for y in range(size):
        for x in range(size):
            var n1 = _noise(float(x) * scale / size, float(y) * scale / size)
            var n2 = _noise(float(x) * scale * 2.7 / size + 31.7, float(y) * scale * 2.7 / size - 12.3)
            var t = clampf(n1 * 0.78 + n2 * 0.22, 0.0, 1.0)
            var col = Color()
            if kind == "wood":
                col = a.lerp(b, clampf(t + sin(float(y) * 0.55 + n1 * 9.0) * 0.09, 0.0, 1.0))
            elif kind == "camo" or kind == "fabric":
                col = a if t > 0.57 else (b if t > 0.43 else c)
                if kind == "fabric" and (x + y) % 4 == 0:
                    col = col.darkened(0.10)
            else:
                col = c.lerp(b, t)
                if t > 0.78:
                    col = col.lerp(a, 0.35)
            var g = (randf() - 0.5) * 0.05
            img.set_pixel(x, y, Color(clampf(col.r + g, 0, 1), clampf(col.g + g, 0, 1), clampf(col.b + g, 0, 1), 1))
    var tex = ImageTexture.create_from_image(img)
    tex_cache[key] = tex
    return tex

func make_normal(kind: String, size: int = 128) -> ImageTexture:
    var key = "n_" + kind + "_" + str(size)
    if tex_cache.has(key):
        return tex_cache[key]
    var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
    var s = 10.0
    for y in range(size):
        for x in range(size):
            var h = _noise(float(x) * s / size, float(y) * s / size)
            var hx = _noise((float(x) + 1.0) * s / size, float(y) * s / size)
            var hy = _noise(float(x) * s / size, (float(y) + 1.0) * s / size)
            img.set_pixel(x, y, Color(clampf((h - hx) * 2.6 + 0.5, 0, 1), clampf((h - hy) * 2.6 + 0.5, 0, 1), 0.93, 1))
    var tex = ImageTexture.create_from_image(img)
    tex_cache[key] = tex
    return tex

func _photo_kind(kind: String) -> String:
    match kind:
        "concrete", "ruin", "plaster", "jersey", "barrier", "wall":
            return "concrete"
        "asphalt", "rubble", "burnt", "dust", "street", "ground":
            return "asphalt"
    return ""

func get_mat(kind: String, tint: Color = Color(1, 1, 1, 1), tile: float = 1.0) -> StandardMaterial3D:
    var key = "%s_%s_%.2f" % [kind, tint.to_html(false), tile]
    if cache.has(key):
        return cache[key]
    var m = StandardMaterial3D.new()
    var pk = _photo_kind(kind)
    if pk != "" and photo.has(pk):
        m.albedo_texture = photo[pk]
        m.normal_texture = make_normal(pk)
        m.normal_scale = 0.85
    else:
        m.albedo_texture = make_albedo(kind)
        m.normal_texture = make_normal(kind)
        m.normal_scale = 0.55
    m.albedo_color = tint
    m.uv1_scale = Vector3(tile, tile, tile)
    m.metallic = 0.0
    m.roughness = 0.94
    match kind:
        "metal":
            m.metallic = 0.72; m.roughness = 0.48; m.normal_scale = 0.35
        "rust":
            m.metallic = 0.25; m.roughness = 0.88
        "burnt":
            m.roughness = 0.98
        "glass":
            m.roughness = 0.35
    m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    m.anisotropy = 4.0
    cache[key] = m
    return m

func flat(color: Color, rough: float = 0.75, metal: float = 0.0, emission: float = 0.0) -> StandardMaterial3D:
    var key = "flat_" + color.to_html(true) + str(rough) + str(metal) + str(emission)
    if cache.has(key):
        return cache[key]
    var m = StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = rough
    m.metallic = metal
    if emission > 0.0:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = emission
    cache[key] = m
    return m

func ghost(color: Color) -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = Color(color.r, color.g, color.b, 0.35)
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

func glass(color: Color) -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = Color(color.r, color.g, color.b, 0.62)
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.metallic = 0.25
    m.roughness = 0.18
    return m

func smoke(color: Color, alpha: float) -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = Color(color.r, color.g, color.b, alpha)
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m
