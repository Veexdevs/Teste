extends CanvasLayer
## Menu principal e seleccao de missao/dificuldade/equipamento.

var bg: ColorRect
var title: Label
var sub: Label
var panel: Panel
var diff_buttons: Array = []
var diff_value: Label
var primary_buttons: Array = []
var primary_value: Label
var start_btn: Button
var controls_label: Label
var chosen_diff = 0.65
var chosen_primary = "m4a1"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 20
    bg = ColorRect.new()
    bg.color = Color(0.020, 0.024, 0.024, 0.72)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    title = Label.new()
    title.text = "S E N T I N E L A"
    title.add_theme_font_size_override("font_size", 52)
    title.add_theme_color_override("font_color", Color(0.94, 0.94, 0.91))
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(title)
    sub = Label.new()
    sub.text = "OPERACAO CERRADO  //  INCURSAO TACTICA  //  MOTOR GODOT 4.5"
    sub.add_theme_font_size_override("font_size", 15)
    sub.add_theme_color_override("font_color", Color(0.66, 0.67, 0.65))
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(sub)
    panel = Panel.new()
    var s = StyleBoxFlat.new()
    s.bg_color = Color(0.045, 0.050, 0.050, 0.94)
    s.set_corner_radius_all(6)
    s.border_width_left = 1
    s.border_width_right = 1
    s.border_width_top = 1
    s.border_width_bottom = 1
    s.border_color = Color(0.40, 0.41, 0.40, 0.35)
    panel.add_theme_stylebox_override("panel", s)
    add_child(panel)
    var t = Label.new()
    t.name = "PTitle"
    t.text = "PREPARACAO DA MISSAO"
    t.add_theme_font_size_override("font_size", 22)
    t.add_theme_color_override("font_color", Color(0.98, 0.74, 0.20))
    t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    panel.add_child(t)
    diff_value = _label("DIFICULDADE: NORMAL", 14, Color(0.88, 0.89, 0.87), panel)
    var dl = ["RECRUTA", "TREINADO", "NORMAL", "VETERANO", "ELITE"]
    for i in range(dl.size()):
        var idx = i
        diff_buttons.append(_button(dl[i], panel, func(): _set_diff(idx), Vector2(92, 34), 12))
    primary_value = _label("ARMAMENTO: M4A1 CARABINA", 14, Color(0.88, 0.89, 0.87), panel)
    var pl = ["M4A1", "AK-47", "MP5", "SNIPER"]
    var pk = ["m4a1", "ak47", "mp5", "sniper"]
    for i in range(pl.size()):
        var key: String = pk[i]
        primary_buttons.append(_button(pl[i], panel, func(): _set_primary(key), Vector2(92, 34), 12))
    start_btn = _button("INICIAR OPERACAO", panel, func(): _start(), Vector2(300, 48), 20)
    controls_label = _label(
        "WASD mover  |  RATO olhar  |  ESQ disparar  |  DIR mirar  |  SHIFT correr\n" +
        "CTRL agachar  |  ESPACO saltar  |  R recarregar  |  1/2 armas  |  Q/E inclinar\n" +
        "F plantar/desactivar  |  B fortificar  |  TAB placar  |  ESC pausa  |  F1 ajuda",
        12, Color(0.66, 0.67, 0.65), panel)
    controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var foot = Label.new()
    foot.text = "SIMULACAO TACTICA FICCIONAL  -  SEM CONEXAO A ARMAS OU OPERACOES REAIS"
    foot.add_theme_font_size_override("font_size", 11)
    foot.add_theme_color_override("font_color", Color(0.45, 0.46, 0.45))
    foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(foot)
    foot.name = "Foot"
    _layout()
    get_viewport().size_changed.connect(_layout)
    _set_diff(2)
    _set_primary("m4a1")

func _label(text: String, size: int, color: Color, parent: Control) -> Label:
    var l = Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    parent.add_child(l)
    return l

func _button(text: String, parent: Control, cb: Callable, sz: Vector2, size: int) -> Button:
    var b = Button.new()
    b.text = text
    b.custom_minimum_size = sz
    b.add_theme_font_size_override("font_size", size)
    b.add_theme_color_override("font_color", Color(0.93, 0.93, 0.91))
    b.add_theme_color_override("font_hover_color", Color(0.98, 0.74, 0.20))
    var st = StyleBoxFlat.new()
    st.bg_color = Color(0.11, 0.12, 0.12, 1.0)
    st.set_corner_radius_all(3)
    b.add_theme_stylebox_override("normal", st)
    var st2 = st.duplicate()
    st2.bg_color = Color(0.22, 0.23, 0.21, 1.0)
    b.add_theme_stylebox_override("hover", st2)
    parent.add_child(b)
    b.pressed.connect(cb)
    return b

func _vp() -> Vector2:
    var s = get_viewport().get_visible_rect().size
    if s.x < 16.0:
        return Vector2(1280, 720)
    return s

func _layout() -> void:
    var W = _vp().x
    var H = _vp().y
    title.position = Vector2(W * 0.5 - 400, H * 0.08)
    title.size = Vector2(800, 68)
    sub.position = Vector2(W * 0.5 - 400, H * 0.08 + 66)
    sub.size = Vector2(800, 28)
    var pw = minf(620.0, W - 40.0)
    var ph = minf(420.0, H - 140.0)
    panel.position = Vector2(W * 0.5 - pw * 0.5, H * 0.5 - ph * 0.5 + 30)
    panel.size = Vector2(pw, ph)
    var pt = panel.get_node_or_null("PTitle") as Label
    if pt:
        pt.position = Vector2(12, 12)
        pt.size = Vector2(pw - 24, 34)
    diff_value.position = Vector2(20, 58)
    diff_value.size = Vector2(pw - 40, 24)
    var n = diff_buttons.size()
    var bw = minf(100.0, (pw - 40 - (n - 1) * 6) / n)
    for i in range(n):
        diff_buttons[i].position = Vector2(20 + i * (bw + 6), 86)
        diff_buttons[i].size = Vector2(bw, 34)
    primary_value.position = Vector2(20, 132)
    primary_value.size = Vector2(pw - 40, 24)
    for i in range(primary_buttons.size()):
        primary_buttons[i].position = Vector2(20 + i * (bw + 6), 160)
        primary_buttons[i].size = Vector2(bw, 34)
    start_btn.position = Vector2(pw * 0.5 - 150, 218)
    start_btn.size = Vector2(300, 48)
    controls_label.position = Vector2(16, ph - 96)
    controls_label.size = Vector2(pw - 32, 88)
    var foot = get_node_or_null("Foot") as Label
    if foot:
        foot.position = Vector2(W * 0.5 - 400, H - 34)
        foot.size = Vector2(800, 22)

func _set_diff(i: int) -> void:
    var vals = [0.32, 0.48, 0.65, 0.80, 0.94]
    var names = ["RECRUTA", "TREINADO", "NORMAL", "VETERANO", "ELITE"]
    chosen_diff = vals[clampi(i, 0, 4)]
    diff_value.text = "DIFICULDADE: " + names[clampi(i, 0, 4)]
    for j in range(diff_buttons.size()):
        diff_buttons[j].modulate = Color(1, 1, 1, 1) if j != i else Color(1.0, 0.85, 0.45, 1.0)
    G.audio.play("ui", -12.0)

func _set_primary(k: String) -> void:
    chosen_primary = k
    primary_value.text = "ARMAMENTO: " + str(G.weapons[k].name)
    for j in range(primary_buttons.size()):
        var keys = ["m4a1", "ak47", "mp5", "sniper"]
        primary_buttons[j].modulate = Color(1, 1, 1, 1) if keys[j] != k else Color(1.0, 0.85, 0.45, 1.0)
    G.audio.play("ui", -12.0)

func _start() -> void:
    G.audio.play("radio", -4.0)
    G.main.start_match(chosen_diff, chosen_primary)
