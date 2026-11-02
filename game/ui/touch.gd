extends CanvasLayer
## Controlos tácteis (Android/iOS): dois joysticks virtuais e botoes.

var left_base = Vector2.ZERO
var left_knob = Vector2.ZERO
var left_id = -1
var right_id = -1
var right_last = Vector2.ZERO
var buttons: Array = []
var joy_visual: Control

func _ready() -> void:
    layer = 15
    if not G.is_mobile():
        queue_free()
        return
    joy_visual = preload("res://game/ui/touch_draw.gd").new()
    joy_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joy_visual.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(joy_visual)

func add_button(text: String, action: String, hold: bool, pos: Vector2, sz: Vector2, font_size: int = 13) -> void:
    if not G.is_mobile():
        return
    var b = Button.new()
    b.text = text
    b.add_theme_font_size_override("font_size", font_size)
    b.add_theme_color_override("font_color", Color(0.92, 0.95, 0.84))
    var st = StyleBoxFlat.new()
    st.bg_color = Color(0.12, 0.18, 0.13, 0.62)
    st.set_corner_radius_all(26)
    st.border_width_left = 1
    st.border_width_right = 1
    st.border_width_top = 1
    st.border_width_bottom = 1
    st.border_color = Color(0.55, 0.65, 0.50, 0.65)
    b.add_theme_stylebox_override("normal", st)
    b.add_theme_stylebox_override("pressed", st)
    b.position = pos
    b.size = sz
    add_child(b)
    buttons.append({"node": b, "action": action, "hold": hold, "pos": pos, "sz": sz})
    if hold:
        b.button_down.connect(func(): G.controls.touch_set(action, true))
        b.button_up.connect(func(): G.controls.touch_set(action, false))
    else:
        b.pressed.connect(func(): G.controls.touch_press(action))

func layout() -> void:
    if not G.is_mobile() or buttons.is_empty():
        return
    var s = get_viewport().get_visible_rect().size
    var W = s.x
    var H = s.y
    for e in buttons:
        var a: String = e.action
        var sz: Vector2 = e.sz
        var x = W - 110.0
        var y = H - 110.0
        match a:
            "fire": x = W - 104.0; y = H - 106.0
            "aim": x = W - 210.0; y = H - 96.0
            "jump": x = W - 108.0; y = H - 214.0
            "crouch": x = W - 196.0; y = H - 214.0
            "reload": x = W - 286.0; y = H - 160.0
            "interact": x = W - 286.0; y = H - 92.0
            "build_toggle": x = W - 374.0; y = H - 160.0
            "build_cycle": x = W - 374.0; y = H - 92.0
            "build_rotate": x = W - 462.0; y = H - 160.0
            "secondary": x = W - 462.0; y = H - 92.0
            "pause": x = W - 76.0; y = 14.0; sz = Vector2(62, 36)
        x = clampf(x, W * 0.42, W - sz.x - 8.0)
        y = clampf(y, 8.0, H - sz.y - 8.0)
        (e.node as Control).position = Vector2(x, y)
        (e.node as Control).size = sz
    left_base = Vector2(130.0, H - 130.0)
    left_knob = Vector2.ZERO

func _input(event: InputEvent) -> void:
    if not G.is_mobile() or G.controls == null:
        return
    if event is InputEventScreenTouch:
        var t: InputEventScreenTouch = event
        if t.pressed and t.position.x < get_viewport().get_visible_rect().size.x * 0.42 and t.position.y > 90.0 and left_id == -1:
            left_id = t.index
            left_base = t.position
            left_knob = Vector2.ZERO
            G.controls.touch_move = Vector2.ZERO
        elif t.pressed and right_id == -1:
            right_id = t.index
            right_last = t.position
        elif not t.pressed:
            if t.index == left_id:
                left_id = -1
                left_knob = Vector2.ZERO
                G.controls.touch_move = Vector2.ZERO
            if t.index == right_id:
                right_id = -1
        joy_visual.queue_redraw()
    elif event is InputEventScreenDrag:
        var d: InputEventScreenDrag = event
        if d.index == left_id:
            left_knob = (d.position - left_base).limit_length(72.0)
            G.controls.touch_move = Vector2(left_knob.x / 72.0, -left_knob.y / 72.0)
            if G.controls.touch_move.length() < 0.16:
                G.controls.touch_move = Vector2.ZERO
            G.controls.touch_sprint = G.controls.touch_move.y > 0.85
            joy_visual.queue_redraw()
        elif d.index == right_id:
            var delta = d.position - right_last
            right_last = d.position
            G.controls.touch_look += delta * 0.0016

func paint(ci: Control) -> void:
    var r = 72.0
    var col = Color(0.70, 0.82, 0.66, 0.22)
    ci.draw_arc(left_base, r, 0, TAU, 32, col, 3.0)
    ci.draw_circle(left_base, 16.0, Color(0.80, 0.90, 0.72, 0.12))
    ci.draw_circle(left_base + left_knob, 26.0, Color(0.78, 0.90, 0.70, 0.38))
    ci.draw_arc(left_base + left_knob, 26.0, 0, TAU, 24, Color(0.90, 0.95, 0.80, 0.65), 2.0)
