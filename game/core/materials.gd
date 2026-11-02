extends Node
## Texturas e materiais PBR procedurais (sem ficheiros de imagem externos).

var cache = {}
var tex_cache = {}
var noise = FastNoiseLite.new()

func _ready() -> void:
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.frequency = 0.06
    noise.fractal_octaves = 4
    noise.seed = 20261102

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
            a = Color(0.20, 0.23, 0.16); b = Color(0.37, 0.36, 0.25); c = Color(0.13, 0.15, 0.12); scale = 13.0
        "concrete":
            a = Color(0.42, 0.42, 0.40); b = Color(0.55, 0.54, 0.51); c = Color(0.33, 0.34, 0.33); scale = 9.0
        "sand":
            a = Color(0.63, 0.55, 0.39); b = Color(0.76, 0.68, 0.50); c = Color(0.49, 0.43, 0.31); scale = 11.0
        "asphalt":
            a = Color(0.17, 0.18, 0.18); b = Color(0.25, 0.26, 0.25); c = Color(0.12, 0.13, 0.13); scale = 16.0
        "metal":
            a = Color(0.25, 0.28, 0.30); b = Color(0.36, 0.39, 0.41); c = Color(0.18, 0.20, 0.22); scale = 7.0
        "rust":
            a = Color(0.38, 0.20, 0.10); b = Color(0.55, 0.32, 0.14); c = Color(0.25, 0.17, 0.12); scale = 12.0
        "fabric":
            a = Color(0.19, 0.22, 0.17); b = Color(0.27, 0.29, 0.21); c = Color(0.13, 0.15, 0.12); scale = 22.0
        "wood":
            a = Color(0.35, 0.25, 0.16); b = Color(0.48, 0.35, 0.21); c = Color(0.25, 0.18, 0.11); scale = 6.0
        _:
            a = Color(0.4, 0.4, 0.4); b = Color(0.55, 0.55, 0.55); c = Color(0.3, 0.3, 0.3)
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
            var g = (randf() - 0.5) * 0.055
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
            img.set_pixel(x, y, Color(clampf((h - hx) * 2.2 + 0.5, 0, 1), clampf((h - hy) * 2.2 + 0.5, 0, 1), 0.92, 1))
    var tex = ImageTexture.create_from_image(img)
    tex_cache[key] = tex
    return tex

func get_mat(kind: String, tint: Color = Color(1, 1, 1, 1), tile: float = 1.0) -> StandardMaterial3D:
    var key = "%s_%s_%.2f" % [kind, tint.to_html(false), tile]
    if cache.has(key):
        return cache[key]
    var m = StandardMaterial3D.new()
    m.albedo_texture = make_albedo(kind)
    m.albedo_color = tint
    m.uv1_scale = Vector3(tile, tile, tile)
    m.normal_texture = make_normal(kind)
    m.normal_scale = 0.55
    m.metallic = 0.0
    m.roughness = 0.88
    match kind:
        "metal":
            m.metallic = 0.72; m.roughness = 0.42; m.normal_scale = 0.30
        "rust":
            m.metallic = 0.25; m.roughness = 0.85
        "asphalt":
            m.roughness = 0.96
        "concrete":
            m.roughness = 0.93
        "camo", "fabric":
            m.roughness = 0.95
    m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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
