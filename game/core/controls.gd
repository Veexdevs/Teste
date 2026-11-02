extends Node
## Mapa de accoes unificado (teclado/rato/gamepad/toque).

var enabled = false
var move = Vector2.ZERO
var look = Vector2.ZERO
var fire = false
var fire_just = false
var aim = false
var reload = false
var jump = false
var crouch = false
var sprint = false
var lean_left = false
var lean_right = false
var interact = false
var pause = false
var help = false
var scoreboard = false
var weapon_primary = false
var weapon_secondary = false
var build_place = false
var build_toggle = false
var build_cycle = false
var build_rotate = false
var touch_move = Vector2.ZERO
var touch_look = Vector2.ZERO
var touch_sprint = false
var touch_rotate = false
var touch_hold = {}
var touch_pressed = {}
var gamepad_look = Vector2.ZERO
var mouse_look = Vector2.ZERO
var sens = 0.0022
var captured = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _install_actions()

func _install_actions() -> void:
    var keys = {
        "snt_forward": [KEY_W, KEY_UP], "snt_back": [KEY_S, KEY_DOWN],
        "snt_left": [KEY_A, KEY_LEFT], "snt_right": [KEY_D, KEY_RIGHT],
        "snt_jump": [KEY_SPACE], "snt_crouch": [KEY_CTRL, KEY_C],
        "snt_sprint": [KEY_SHIFT], "snt_lean_left": [KEY_Q],
        "snt_lean_right": [KEY_E], "snt_interact": [KEY_F],
        "snt_reload": [KEY_R], "snt_primary": [KEY_1],
        "snt_secondary": [KEY_2], "snt_pause": [KEY_ESCAPE, KEY_P],
        "snt_help": [KEY_F1], "snt_score": [KEY_TAB],
        "snt_build": [KEY_B], "snt_build_cycle": [KEY_V], "snt_build_rotate": [KEY_T]
    }
    for a in keys:
        if not InputMap.has_action(a):
            InputMap.add_action(a, 0.25)
        for k in keys[a]:
            var e = InputEventKey.new()
            e.physical_keycode = k
            if not InputMap.action_has_event(a, e):
                InputMap.action_add_event(a, e)
    var mouse = {
        "snt_fire": MOUSE_BUTTON_LEFT, "snt_aim": MOUSE_BUTTON_RIGHT
    }
    for a in mouse:
        if not InputMap.has_action(a):
            InputMap.add_action(a, 0.25)
        var m = InputEventMouseButton.new()
        m.button_index = mouse[a]
        if not InputMap.action_has_event(a, m):
            InputMap.action_add_event(a, m)
    var pad = {
        "snt_pad_fire": JOY_BUTTON_RIGHT_SHOULDER,
        "snt_pad_aim": JOY_BUTTON_LEFT_SHOULDER,
        "snt_pad_jump": JOY_BUTTON_A,
        "snt_pad_reload": JOY_BUTTON_X,
        "snt_pad_build": JOY_BUTTON_Y,
        "snt_pad_interact": JOY_BUTTON_B
    }
    for a in pad:
        if not InputMap.has_action(a):
            InputMap.add_action(a, 0.25)
        var j = InputEventJoypadButton.new()
        j.button_index = pad[a]
        if not InputMap.action_has_event(a, j):
            InputMap.action_add_event(a, j)
    var stick = {
        "snt_pad_lxn": [JOY_AXIS_LEFT_X, -1.0], "snt_pad_lxp": [JOY_AXIS_LEFT_X, 1.0],
        "snt_pad_lyn": [JOY_AXIS_LEFT_Y, -1.0], "snt_pad_lyp": [JOY_AXIS_LEFT_Y, 1.0],
        "snt_pad_rxn": [JOY_AXIS_RIGHT_X, -1.0], "snt_pad_rxp": [JOY_AXIS_RIGHT_X, 1.0],
        "snt_pad_ryn": [JOY_AXIS_RIGHT_Y, -1.0], "snt_pad_ryp": [JOY_AXIS_RIGHT_Y, 1.0]
    }
    for a in stick:
        if not InputMap.has_action(a):
            InputMap.add_action(a, 0.25)
        var j = InputEventJoypadMotion.new()
        j.axis = stick[a][0]
        j.axis_value = stick[a][1]
        if not InputMap.action_has_event(a, j):
            InputMap.action_add_event(a, j)
    if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
        var touch = {
            "snt_touch_fire": 7, "snt_touch_aim": 8, "snt_touch_jump": 9,
            "snt_touch_crouch": 10, "snt_touch_reload": 11
        }
        for a in touch:
            if not InputMap.has_action(a):
                InputMap.add_action(a, 0.25)
            var mb = InputEventMouseButton.new()
            mb.button_index = touch[a]
            if not InputMap.action_has_event(a, mb):
                InputMap.action_add_event(a, mb)

func set_capture(on: bool) -> void:
    captured = on and enabled and not G.is_mobile()
    if captured:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    elif not G.is_mobile():
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
    if not enabled or G.hud == null:
        return
    if event is InputEventMouseMotion and captured:
        mouse_look += Vector2(-event.relative.x, -event.relative.y) * sens
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            fire_just = true
    if event is InputEventKey and event.pressed and not event.echo:
        if event.physical_keycode == KEY_ESCAPE:
            pause = true
        elif event.physical_keycode == KEY_F1:
            help = true
        elif event.physical_keycode == KEY_1:
            weapon_primary = true
        elif event.physical_keycode == KEY_2:
            weapon_secondary = true
        elif event.physical_keycode == KEY_B:
            build_toggle = true
        elif event.physical_keycode == KEY_V:
            build_cycle = true
        elif event.physical_keycode == KEY_T:
            build_rotate = true
        elif event.physical_keycode == KEY_R:
            reload = true
        elif event.physical_keycode == KEY_SPACE:
            jump = true

func touch_set(action: String, v: bool) -> void:
    touch_hold[action] = v
    match action:
        "fire": fire = v
        "fire_just":
            if v:
                fire_just = true
        "aim": aim = v
        "jump": jump = v
        "crouch": crouch = v
        "sprint": touch_sprint = v
        "interact": interact = v
        "build": build_place = v

func touch_press(action: String) -> void:
    touch_pressed[action] = true
    match action:
        "reload": reload = true
        "primary": weapon_primary = true
        "secondary": weapon_secondary = true
        "build_toggle": build_toggle = true
        "build_cycle": build_cycle = true
        "build_rotate": touch_rotate = true
        "pause": pause = true
        "help": help = true
        "score": scoreboard = true

func consume_look() -> Vector2:
    var out = (mouse_look + touch_look + gamepad_look).limit_length(0.35)
    mouse_look = Vector2.ZERO
    touch_look = Vector2.ZERO
    return out

func poll(delta: float) -> void:
    if not enabled:
        move = Vector2.ZERO
        look = Vector2.ZERO
        fire = false
        aim = false
        crouch = false
        sprint = false
        lean_left = false
        lean_right = false
        interact = false
        return
    var kb = Vector2(
        float(Input.is_action_pressed("snt_right")) - float(Input.is_action_pressed("snt_left")),
        float(Input.is_action_pressed("snt_back")) - float(Input.is_action_pressed("snt_forward")))
    gamepad_look = Vector2(
        Input.get_axis("snt_pad_rxn", "snt_pad_rxp"),
        Input.get_axis("snt_pad_ryn", "snt_pad_ryp")) * delta * 2.1
    var pad_move = Vector2(
        Input.get_axis("snt_pad_lxn", "snt_pad_lxp"),
        Input.get_axis("snt_pad_lyn", "snt_pad_lyp"))
    if pad_move.length() < 0.15:
        pad_move = Vector2.ZERO
    move = (kb + pad_move + touch_move).limit_length(1.0)
    fire = Input.is_action_pressed("snt_fire") or Input.is_action_pressed("snt_pad_fire") or bool(touch_hold.get("fire", false))
    aim = Input.is_action_pressed("snt_aim") or Input.is_action_pressed("snt_pad_aim") or bool(touch_hold.get("aim", false))
    reload = reload or Input.is_action_just_pressed("snt_reload") or Input.is_action_just_pressed("snt_pad_reload")
    jump = jump or Input.is_action_pressed("snt_jump") or Input.is_action_just_pressed("snt_pad_jump") or bool(touch_hold.get("jump", false))
    crouch = Input.is_action_pressed("snt_crouch") or bool(touch_hold.get("crouch", false))
    sprint = Input.is_action_pressed("snt_sprint") or touch_sprint
    lean_left = Input.is_action_pressed("snt_lean_left")
    lean_right = Input.is_action_pressed("snt_lean_right")
    interact = Input.is_action_pressed("snt_interact") or Input.is_action_pressed("snt_pad_interact") or bool(touch_hold.get("interact", false))
    scoreboard = Input.is_action_pressed("snt_score")
    build_toggle = build_toggle or Input.is_action_pressed("snt_build") or Input.is_action_just_pressed("snt_pad_build")

func clear_edges() -> void:
    reload = false
    jump = false
    weapon_primary = false
    weapon_secondary = false
    build_toggle = false
    build_cycle = false
    build_rotate = false
    build_place = false
    pause = false
    help = false
    fire_just = false
    touch_pressed.clear()
