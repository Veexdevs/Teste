extends CanvasLayer
## HUD táctico minimalista (referência: CS / Battlefield).
## Sem painéis verdes: minimapa circular, placar central, arma e munição,
## vida/colete em baixo à esquerda e mira discreta.

const Paint = preload("res://game/ui/paint.gd")

const BG = Color(0.055, 0.060, 0.060, 0.80)
const BG_SOLID = Color(0.045, 0.050, 0.050, 0.94)
const LINE = Color(0.40, 0.41, 0.40, 0.35)
const TXT = Color(0.93, 0.93, 0.91, 1)
const MUTED = Color(0.64, 0.65, 0.63, 1)
const BLUE = Color(0.36, 0.63, 0.96, 1)
const AMBER = Color(0.98, 0.72, 0.18, 1)
const RED = Color(0.92, 0.28, 0.24, 1)

var root: Control
var minimap: Control
var crosshair: Control
var weapon_panel: Control
var vitals: Control
var radar: Control
var score_bar: Control
var compass: Control
var paints: Array = []

var lbl_atk: Label
var lbl_timer: Label
var lbl_def: Label
var lbl_obj: Label
var feed_labels: Array = []
var lbl_interact: Label
var interact_bg: ColorRect
var interact_fill: ColorRect
var lbl_build: Label
var build_bg: ColorRect
var build_fill: ColorRect
var lbl_flash: Label
var lbl_banner: Label
var lbl_banner_sub: Label
var vignette: ColorRect
var death_panel: Panel
var buy_panel: Panel
var buy_list: VBoxContainer
var lbl_money: Label
var pause_panel: Panel
var score_panel: Panel
var score_list: VBoxContainer
var help_panel: Panel
var end_panel: Panel
var lbl_end: Label

var dead = false
var hit_t = 0.0
var hit_head = false
var hit_kill = false
var kick = 0.0
var banner_t = 0.0
var flash_t = 0.0
var vignette_a = 0.0
var pause_open = false
var help_open = false
var build_active = false
var build_selected = "sandbag"
var build_progress = 0.0
var interact_progress = 0.0

var ammo_mag = 30
var ammo_reserve = 90
var weapon_name = "M4A1 CARBINE"
var health_v = 100.0
var armor_v = 0.0
var score_a = 0
var score_d = 0
var timer_text = "1:42"
var obj_text = ""

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 10
    root = Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)
    _build_paints()
    _build_score()
    _build_feed()
    _build_overlays()
    _build_panels()
    G.note("hud: interface construida")

# --- auxiliares ------------------------------------------------------------
func _style(color: Color) -> StyleBoxFlat:
    var s = StyleBoxFlat.new()
    s.bg_color = color
    s.set_corner_radius_all(3)
    s.border_width_left = 1
    s.border_width_right = 1
    s.border_width_top = 1
    s.border_width_bottom = 1
    s.border_color = LINE
    return s

func _lbl(text: String, size: int, color: Color, parent: Control, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var l = Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    l.horizontal_alignment = align
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(l)
    return l

func _panel(parent: Control) -> Panel:
    var p = Panel.new()
    p.add_theme_stylebox_override("panel", _style(BG_SOLID))
    parent.add_child(p)
    return p

func _paint(kind: String) -> Control:
    var c = Paint.new()
    c.kind = kind
    c.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(c)
    paints.append(c)
    return c

func _button(text: String, parent: Control, cb: Callable, size: int = 13) -> Button:
    var b = Button.new()
    b.text = text
    b.add_theme_font_size_override("font_size", size)
    b.add_theme_color_override("font_color", TXT)
    b.add_theme_color_override("font_hover_color", AMBER)
    b.add_theme_stylebox_override("normal", _style(Color(0.11, 0.12, 0.12, 0.95)))
    b.add_theme_stylebox_override("hover", _style(Color(0.20, 0.21, 0.20, 0.98)))
    b.add_theme_stylebox_override("pressed", _style(Color(0.28, 0.27, 0.20, 1.0)))
    b.custom_minimum_size = Vector2(0, 30)
    parent.add_child(b)
    b.pressed.connect(cb)
    return b

func _build_paints() -> void:
    minimap = _paint("minimap")
    score_bar = _paint("score")
    weapon_panel = _paint("weapon")
    vitals = _paint("vitals")
    radar = _paint("radar")
    crosshair = _paint("crosshair")
    compass = _paint("compass")

func _build_score() -> void:
    # placar central: 5 | 1:42 | 5
    var p = _panel(root)
    p.name = "ScoreFrame"
    lbl_atk = _lbl("5", 27, BLUE, p, HORIZONTAL_ALIGNMENT_CENTER)
    lbl_timer = _lbl("1:42", 24, TXT, p, HORIZONTAL_ALIGNMENT_CENTER)
    lbl_def = _lbl("5", 27, AMBER, p, HORIZONTAL_ALIGNMENT_CENTER)
    lbl_obj = _lbl("", 11, MUTED, root, HORIZONTAL_ALIGNMENT_CENTER)

func _build_feed() -> void:
    for i in range(5):
        feed_labels.append(_lbl("", 12, MUTED, root, HORIZONTAL_ALIGNMENT_RIGHT))

func _build_overlays() -> void:
    vignette = ColorRect.new()
    vignette.color = Color(0.60, 0.05, 0.04, 0.0)
    vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(vignette)
    lbl_banner = _lbl("", 23, TXT, root, HORIZONTAL_ALIGNMENT_CENTER)
    lbl_banner_sub = _lbl("", 12, MUTED, root, HORIZONTAL_ALIGNMENT_CENTER)
    lbl_flash = _lbl("", 14, AMBER, root, HORIZONTAL_ALIGNMENT_CENTER)
    lbl_interact = _lbl("", 14, TXT, root, HORIZONTAL_ALIGNMENT_CENTER)
    interact_bg = ColorRect.new()
    interact_bg.color = Color(0.02, 0.02, 0.02, 0.75)
    interact_fill = ColorRect.new()
    interact_fill.color = AMBER
    root.add_child(interact_bg)
    root.add_child(interact_fill)
    lbl_build = _lbl("", 12, TXT, root, HORIZONTAL_ALIGNMENT_CENTER)
    build_bg = ColorRect.new()
    build_bg.color = Color(0.02, 0.02, 0.02, 0.75)
    build_fill = ColorRect.new()
    build_fill.color = Color(0.55, 0.80, 0.55, 0.95)
    root.add_child(build_bg)
    root.add_child(build_fill)

func _build_panels() -> void:
    # compras
    buy_panel = _panel(root)
    var t = _lbl("PLANEAMENTO / ARMARIA", 20, AMBER, buy_panel)
    t.name = "Title"
    lbl_money = _lbl("CREDITO  $800", 15, Color(0.62, 0.82, 0.62), buy_panel)
    lbl_money.name = "Money"
    buy_list = VBoxContainer.new()
    buy_list.add_theme_constant_override("separation", 4)
    buy_panel.add_child(buy_list)
    for item in G.buy_items:
        var key: String = item.key
        _button("%s    $%d" % [item.label, item.price], buy_list,
                func(): G.match_mgr.buy(key), 12)
    _button(">>  INICIAR RONDA  <<", buy_list, func(): G.match_mgr.force_start(), 15)
    var hint = _lbl("Escolhe o equipamento. Durante a ronda usa [B] para fortificar.",
                    11, MUTED, buy_panel)
    hint.name = "Hint"
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    # pausa
    pause_panel = _panel(root)
    var pt = _lbl("PAUSA", 24, TXT, pause_panel, HORIZONTAL_ALIGNMENT_CENTER)
    pt.name = "Title"
    var pv = VBoxContainer.new()
    pv.name = "Buttons"
    pause_panel.add_child(pv)
    _button("CONTINUAR", pv, func(): toggle_pause(false))
    _button("REINICIAR OPERACAO", pv, func(): G.main.restart())
    _button("CONTROLES", pv, func(): toggle_help())
    _button("SAIR", pv, func(): get_tree().quit())

    # ajuda
    help_panel = _panel(root)
    var ht = _lbl("CONTROLES", 21, TXT, help_panel, HORIZONTAL_ALIGNMENT_CENTER)
    ht.name = "Title"
    var txt = _lbl(
        "WASD mover   |   RATO olhar   |   SHIFT correr   |   CTRL agachar   |   ESPACO saltar\n" +
        "ESQ disparar   |   DIR mirar   |   R recarregar   |   1 / 2 trocar arma\n" +
        "Q / E inclinar   |   F plantar / desactivar   |   B fortificar   |   V alternar   |   T rodar\n" +
        "TAB placar   |   ESC pausa   |   F1 ajuda\n\n" +
        "No telemovel: joystick esquerdo, arrastar à direita para olhar, botoes de accao.",
        13, TXT, help_panel)
    txt.name = "Text"
    txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _button("FECHAR", help_panel, func(): toggle_help(false), 13)

    # placar de jogadores
    score_panel = _panel(root)
    var st = _lbl("PLACAR DA OPERACAO", 18, TXT, score_panel, HORIZONTAL_ALIGNMENT_CENTER)
    st.name = "Title"
    score_list = VBoxContainer.new()
    score_panel.add_child(score_list)

    # morte
    death_panel = _panel(root)
    var dt = _lbl("ABATIDO EM COMBATE", 24, Color(1.0, 0.68, 0.60), death_panel, HORIZONTAL_ALIGNMENT_CENTER)
    dt.name = "Title"
    var ds = _lbl("A observar a equipa — toca para alternar operador", 12, MUTED, death_panel, HORIZONTAL_ALIGNMENT_CENTER)
    ds.name = "Sub"
    death_panel.visible = false

    # fim
    end_panel = _panel(root)
    lbl_end = _lbl("", 22, TXT, end_panel, HORIZONTAL_ALIGNMENT_CENTER)
    lbl_end.name = "Title"
    var ev = VBoxContainer.new()
    ev.name = "Buttons"
    end_panel.add_child(ev)
    _button("NOVA OPERACAO", ev, func(): G.main.restart())
    _button("SAIR", ev, func(): get_tree().quit())
    end_panel.visible = false
    pause_panel.visible = false
    score_panel.visible = false
    help_panel.visible = false
    buy_panel.visible = false

# --- API pública (usada pelo resto do jogo) --------------------------------
func toggle_pause(on: bool) -> void:
    pause_open = on
    pause_panel.visible = on
    get_tree().paused = on
    G.controls.enabled = not on
    G.controls.set_capture(not on)
    if on:
        help_panel.visible = false

func toggle_help(on: bool = true) -> void:
    help_open = on
    help_panel.visible = on

func show_buy(on: bool) -> void:
    buy_panel.visible = on
    if on:
        pause_panel.visible = false
        pause_open = false
        get_tree().paused = false

func show_match_end(sc: Array) -> void:
    end_panel.visible = true
    lbl_end.text = "OPERACAO CONCLUIDA\nASSALTO %d  -  %d DEFESA\n%s" % [
        sc[0], sc[1], "VITORIA DO ASSALTO" if sc[0] > sc[1] else "VITORIA DA DEFESA"]

func on_player_death(_killer: Node) -> void:
    dead = true
    death_panel.visible = true

func flash(text: String) -> void:
    lbl_flash.text = text
    flash_t = 2.2

func banner(title: String, sub: String, dur: float) -> void:
    lbl_banner.text = title
    lbl_banner_sub.text = sub
    banner_t = dur

func hitmarker(head: bool, kill: bool) -> void:
    hit_t = 0.22
    hit_head = head
    hit_kill = kill

func crosshair_kick() -> void:
    kick = minf(kick + 4.0, 14.0)

func damage_flash() -> void:
    vignette_a = 0.36

func set_interact(text: String, p: float) -> void:
    lbl_interact.text = text
    interact_progress = p

func set_build_mode(on: bool, selected: String) -> void:
    build_active = on
    build_selected = selected

func set_build_progress(p: float, name: String) -> void:
    build_progress = p
    if name != "":
        lbl_build.text = "A MONTAR: " + name

func _vp_size() -> Vector2:
    var vp = get_viewport()
    if vp != null:
        var s: Vector2 = vp.get_visible_rect().size
        if s.x > 16.0 and s.y > 16.0:
            return s
    return Vector2(float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280)),
                   float(ProjectSettings.get_setting("display/window/size/viewport_height", 720)))

func _process(delta: float) -> void:
    var w = _vp_size()
    _layout(w.x, w.y)
    if G.match_mgr != null:
        _update_texts(delta)
    hit_t = maxf(0.0, hit_t - delta)
    kick = maxf(0.0, kick - delta * 32.0)
    banner_t = maxf(0.0, banner_t - delta)
    flash_t = maxf(0.0, flash_t - delta)
    vignette_a = maxf(0.0, vignette_a - delta * 0.9)
    vignette.color.a = vignette_a
    lbl_banner.modulate.a = clampf(banner_t, 0.0, 1.0)
    lbl_banner_sub.modulate.a = clampf(banner_t, 0.0, 1.0)
    lbl_flash.modulate.a = clampf(flash_t, 0.0, 1.0)
    for c in paints:
        c.queue_redraw()

# --- layout ----------------------------------------------------------------
func _layout(W: float, H: float) -> void:
    minimap.position = Vector2(14, 12)
    minimap.size = Vector2(172, 172)
    score_bar.position = Vector2(W * 0.5 - 150, 12)
    score_bar.size = Vector2(300, 52)
    weapon_panel.position = Vector2(W - 266, 12)
    weapon_panel.size = Vector2(250, 100)
    vitals.position = Vector2(14, H - 86)
    vitals.size = Vector2(306, 72)
    radar.position = Vector2(W - 94, H - 94)
    radar.size = Vector2(78, 78)
    crosshair.position = Vector2(W * 0.5 - 60, H * 0.5 - 60)
    crosshair.size = Vector2(120, 120)
    compass.position = Vector2(W * 0.5 - 190, 70)
    compass.size = Vector2(380, 22)
    vignette.position = Vector2.ZERO
    vignette.size = Vector2(W, H)
    var sf = root.get_node_or_null("ScoreFrame") as Panel
    if sf:
        sf.position = Vector2(W * 0.5 - 150, 12)
        sf.size = Vector2(300, 52)
    lbl_atk.position = Vector2(6, 2)
    lbl_atk.size = Vector2(94, 44)
    lbl_timer.position = Vector2(100, 3)
    lbl_timer.size = Vector2(100, 42)
    lbl_def.position = Vector2(200, 2)
    lbl_def.size = Vector2(94, 44)
    lbl_obj.position = Vector2(W * 0.5 - 170, 66)
    lbl_obj.size = Vector2(340, 18)
    for i in range(feed_labels.size()):
        feed_labels[i].position = Vector2(W - 300, 122 + i * 18)
        feed_labels[i].size = Vector2(284, 18)
    lbl_banner.position = Vector2(W * 0.5 - 320, H * 0.20)
    lbl_banner.size = Vector2(640, 34)
    lbl_banner_sub.position = Vector2(W * 0.5 - 320, H * 0.20 + 36)
    lbl_banner_sub.size = Vector2(640, 22)
    lbl_flash.position = Vector2(W * 0.5 - 250, H * 0.70)
    lbl_flash.size = Vector2(500, 22)
    lbl_interact.position = Vector2(W * 0.5 - 220, H * 0.68)
    lbl_interact.size = Vector2(440, 24)
    interact_bg.position = Vector2(W * 0.5 - 140, H * 0.68 + 28)
    interact_bg.size = Vector2(280, 6)
    interact_fill.position = interact_bg.position
    interact_fill.size = Vector2(280 * clampf(interact_progress, 0.0, 1.0), 6)
    interact_bg.visible = interact_progress > 0.0
    interact_fill.visible = interact_bg.visible
    lbl_build.position = Vector2(W * 0.5 - 200, H - 60)
    lbl_build.size = Vector2(400, 20)
    build_bg.position = Vector2(W * 0.5 - 150, H - 38)
    build_bg.size = Vector2(300, 6)
    build_fill.position = build_bg.position
    build_fill.size = Vector2(300 * clampf(build_progress, 0.0, 1.0), 6)
    lbl_build.visible = build_active
    build_bg.visible = build_active and build_progress > 0.0
    build_fill.visible = build_bg.visible
    _layout_panel(buy_panel, W, H, 470, 430)
    _layout_panel(pause_panel, W, H, 350, 290)
    _layout_panel(help_panel, W, H, 600, 300)
    _layout_panel(score_panel, W, H, 440, 400)
    _layout_panel(death_panel, W, H, 480, 96)
    _layout_panel(end_panel, W, H, 440, 240)

func _layout_panel(p: Panel, W: float, H: float, pw: float, ph: float) -> void:
    p.position = Vector2(W * 0.5 - pw * 0.5, H * 0.5 - ph * 0.5)
    p.size = Vector2(pw, ph)
    var t = p.get_node_or_null("Title") as Label
    if t:
        t.position = Vector2(12, 10)
        t.size = Vector2(pw - 24, 40)
    var v = p.get_node_or_null("Buttons") as VBoxContainer
    if v:
        v.position = Vector2(22, 62)
        v.size = Vector2(pw - 44, ph - 80)
    var sub = p.get_node_or_null("Sub") as Label
    if sub:
        sub.position = Vector2(12, 52)
        sub.size = Vector2(pw - 24, 24)
    var txt = p.get_node_or_null("Text") as Label
    if txt:
        txt.position = Vector2(22, 56)
        txt.size = Vector2(pw - 44, ph - 110)
    if p == buy_panel:
        lbl_money.position = Vector2(18, 46)
        lbl_money.size = Vector2(pw - 36, 24)
        buy_list.position = Vector2(18, 76)
        buy_list.size = Vector2(pw - 36, ph - 126)
        var h = p.get_node_or_null("Hint") as Label
        if h:
            h.position = Vector2(18, ph - 42)
            h.size = Vector2(pw - 36, 34)
    if p == help_panel:
        var b = p.get_child(p.get_child_count() - 1) as Button
        if b:
            b.position = Vector2(22, ph - 46)
            b.size = Vector2(pw - 44, 32)
    if p == score_panel:
        score_list.position = Vector2(18, 58)
        score_list.size = Vector2(pw - 36, ph - 72)

func _update_texts(delta: float) -> void:
    var m = G.match_mgr
    score_a = m.score[0]
    score_d = m.score[1]
    lbl_atk.text = str(score_a)
    lbl_def.text = str(score_d)
    if m.bomb_planted:
        timer_text = "%02d:%02d" % [int(m.bomb_timer) / 60, int(m.bomb_timer) % 60]
        obj_text = "CARGA ACTIVA — LOCAL " + str(m.bomb_site.name)
    elif m.state == "BUY":
        timer_text = "%02d:%02d" % [int(m.phase_left) / 60, int(m.phase_left) % 60]
        obj_text = "PLANEAMENTO"
    elif m.state == "LIVE":
        timer_text = "%02d:%02d" % [int(m.round_left) / 60, int(m.round_left) % 60]
        obj_text = "PLANTAR CARGA EM A OU B"
    else:
        timer_text = "--:--"
        obj_text = m.last_reason
    lbl_timer.text = timer_text
    lbl_obj.text = obj_text
    lbl_money.text = "CREDITO  $%d" % m.money
    for i in range(feed_labels.size()):
        var idx = m.kill_feed.size() - 1 - i
        feed_labels[i].text = str(m.kill_feed[idx].text) if idx >= 0 else ""
        if idx >= 0:
            feed_labels[i].modulate.a = clampf(1.0 - float(m.kill_feed[idx].t) / 8.0, 0.25, 1.0)
    for k in m.kill_feed:
        k.t += delta
    var p = G.player
    if p == null:
        return
    health_v = p.health
    armor_v = p.armor
    if p.weapon != null:
        ammo_mag = p.weapon.mag
        ammo_reserve = p.weapon.reserve
        weapon_name = str(p.weapon.data.name)
    if dead and p.alive:
        dead = false
        death_panel.visible = false
    score_panel.visible = G.controls.scoreboard and not pause_open
    if score_panel.visible:
        _fill_score()
    if build_active:
        var cfg: Dictionary = G.fortifications[build_selected]
        lbl_build.text = "FORTIFICACAO: %s   |   CARGAS: %d   |   [V] alternar  [T] rodar" % [
            str(cfg.name), int(p.build_sys.charges.get(build_selected, 0))]

func _fill_score() -> void:
    for c in score_list.get_children():
        c.queue_free()
    var t1 = _lbl("ASSALTO                 K / D", 13, BLUE, score_list)
    t1.custom_minimum_size = Vector2(0, 24)
    for s in G.match_mgr.all_soldiers():
        if s.team == G.TEAM_ATTACK:
            _lbl("  %s   %d / %d" % [s.display_name, s.kills, s.deaths], 12,
                TXT if s.alive else MUTED, score_list)
    var t2 = _lbl("DEFESA                  K / D", 13, AMBER, score_list)
    t2.custom_minimum_size = Vector2(0, 24)
    for s in G.match_mgr.all_soldiers():
        if s.team == G.TEAM_DEFEND:
            _lbl("  %s   %d / %d" % [s.display_name, s.kills, s.deaths], 12,
                TXT if s.alive else MUTED, score_list)

# --- Desenhos --------------------------------------------------------------
func _font() -> Font:
    return ThemeDB.fallback_font

func paint_score(ci: Control) -> void:
    var s = ci.size
    ci.draw_rect(Rect2(Vector2.ZERO, s), BG, true)
    ci.draw_rect(Rect2(Vector2.ZERO, s), LINE, false, 1.0)
    ci.draw_line(Vector2(s.x * 0.5 - 48, 6), Vector2(s.x * 0.5 - 48, s.y - 6), LINE, 1.0)
    ci.draw_line(Vector2(s.x * 0.5 + 48, 6), Vector2(s.x * 0.5 + 48, s.y - 6), LINE, 1.0)

func paint_weapon(ci: Control) -> void:
    var s = ci.size
    ci.draw_rect(Rect2(Vector2.ZERO, s), BG, true)
    ci.draw_rect(Rect2(Vector2.ZERO, s), LINE, false, 1.0)
    var f = _font()
    var gun = Color(0.80, 0.81, 0.80, 0.92)
    # silhueta de espingarda de assalto
    var y = 34.0
    ci.draw_line(Vector2(20, y), Vector2(150, y), gun, 3.0)
    ci.draw_line(Vector2(150, y), Vector2(166, y - 3), gun, 3.0)
    ci.draw_rect(Rect2(58, y - 9, 62, 18), gun, true)
    ci.draw_rect(Rect2(58, y - 9, 62, 18), Color(0.10, 0.11, 0.11, 1), true)
    ci.draw_rect(Rect2(58, y - 9, 62, 18), gun, false, 1.5)
    ci.draw_rect(Rect2(116, y + 9, 12, 22), gun, true)       # carregador
    ci.draw_rect(Rect2(74, y + 9, 10, 18), gun, true)        # punho
    ci.draw_rect(Rect2(120, y - 15, 34, 6), gun, true)       # coronha / óptica
    ci.draw_rect(Rect2(150, y - 14, 8, 5), gun, true)
    ci.draw_rect(Rect2(84, y - 17, 22, 7), gun, true)        # mira
    ci.draw_line(Vector2(20, y + 4), Vector2(42, y + 4), gun, 2.0)
    if f != null:
        ci.draw_string(f, Vector2(14, 84), "%d / %d" % [ammo_mag, ammo_reserve],
                       HORIZONTAL_ALIGNMENT_LEFT, -1, 27, TXT)
        ci.draw_string(f, Vector2(14, 98), weapon_name,
                       HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)
    # riscas de munição
    for i in range(4):
        ci.draw_line(Vector2(196 + i * 9, 96), Vector2(202 + i * 9, 74),
                     Color(0.85, 0.86, 0.84, 0.85), 2.0)

func paint_vitals(ci: Control) -> void:
    var s = ci.size
    ci.draw_rect(Rect2(Vector2.ZERO, s), BG, true)
    ci.draw_rect(Rect2(Vector2.ZERO, s), LINE, false, 1.0)
    var f = _font()
    var white = Color(0.95, 0.95, 0.93, 1)
    # cruz
    ci.draw_rect(Rect2(16, 24, 22, 7), white, true)
    ci.draw_rect(Rect2(23.5, 16.5, 7, 22), white, true)
    # escudo
    var pts = PackedVector2Array([
        Vector2(166, 16), Vector2(188, 22), Vector2(188, 40),
        Vector2(177, 52), Vector2(166, 56), Vector2(155, 52),
        Vector2(144, 40), Vector2(144, 22)])
    ci.draw_colored_polygon(pts, white)
    if f != null:
        ci.draw_string(f, Vector2(48, 42), str(int(round(health_v))),
                       HORIZONTAL_ALIGNMENT_LEFT, -1, 27, TXT)
        ci.draw_string(f, Vector2(196, 42), str(int(round(armor_v))),
                       HORIZONTAL_ALIGNMENT_LEFT, -1, 27, TXT)
    ci.draw_rect(Rect2(14, s.y - 9, 130, 3), Color(0.85, 0.85, 0.83, 0.65), true)
    ci.draw_rect(Rect2(150, s.y - 9, 142, 3), Color(0.85, 0.85, 0.83, 0.65), true)
    var hp = clampf(health_v / 100.0, 0.0, 1.0)
    var ar = clampf(armor_v / 100.0, 0.0, 1.0)
    ci.draw_rect(Rect2(14, s.y - 9, 130 * hp, 3), white, true)
    ci.draw_rect(Rect2(150, s.y - 9, 142 * ar, 3), Color(0.55, 0.72, 0.92, 1), true)

func paint_radar(ci: Control) -> void:
    var c = ci.size * 0.5
    ci.draw_circle(c, 36, Color(0.04, 0.05, 0.05, 0.55))
    ci.draw_arc(c, 36, 0, TAU, 40, Color(0.72, 0.73, 0.70, 0.65), 1.5)
    ci.draw_arc(c, 30, 0, TAU, 40, Color(0.45, 0.46, 0.44, 0.35), 1.0)
    ci.draw_line(c + Vector2(-11, 0), c + Vector2(11, 0), Color(0.90, 0.91, 0.88, 0.8), 1.5)
    ci.draw_line(c + Vector2(0, -11), c + Vector2(0, 11), Color(0.90, 0.91, 0.88, 0.8), 1.5)
    ci.draw_circle(c, 1.5, Color(0.95, 0.95, 0.92, 0.9))

func paint_minimap(ci: Control) -> void:
    var c = ci.size * 0.5
    var r = ci.size.x * 0.5 - 3.0
    ci.draw_circle(c, r, Color(0.055, 0.062, 0.060, 0.82))
    ci.draw_arc(c, r, 0, TAU, 48, Color(0.62, 0.63, 0.60, 0.55), 1.5)
    var p = G.player
    if p == null:
        return
    var pp = Vector2(p.global_position.x, p.global_position.z)
    var yaw = p.rotation.y
    var sc = 1.65
    var cosy = cos(yaw)
    var siny = sin(yaw)
    # quarteirões em ruínas (mapa esquemático, rodado com o jogador)
    var blocks = [
        Vector2(-20, -14), Vector2(20, 14), Vector2(-30, 22),
        Vector2(31, -24), Vector2(-6, 34), Vector2(8, -36),
        Vector2(-40, -36), Vector2(0, -30), Vector2(0, 28),
        Vector2(-12, 4), Vector2(14, -6), Vector2(-34, 4), Vector2(36, -4)]
    for b in blocks:
        var d = b - pp
        var rp = Vector2(d.x * cosy - d.y * siny, d.x * siny + d.y * cosy) * sc
        var q = c + rp
        if q.distance_to(c) > r - 12:
            continue
        ci.draw_rect(Rect2(q - Vector2(9, 9), Vector2(18, 18)),
                     Color(0.30, 0.31, 0.30, 0.85), true)
        ci.draw_rect(Rect2(q - Vector2(9, 9), Vector2(18, 18)),
                     Color(0.48, 0.49, 0.47, 0.55), false, 1.0)
    # estradas
    for i in range(-3, 4):
        var off = i * 26.0
        var rp = Vector2(off * cosy, off * siny) * sc
        if c.distance_to(c + rp) < r + 20:
            ci.draw_line(c + rp - Vector2(0, r), c + rp + Vector2(0, r),
                         Color(0.22, 0.23, 0.22, 0.30), 5.0)
    # objectivos A / B
    var f = _font()
    for site in G.world.sites:
        var d = Vector2(site.pos.x, site.pos.z) - pp
        var rp = Vector2(d.x * cosy - d.y * siny, d.x * siny + d.y * cosy) * sc
        var q = c + rp
        if q.distance_to(c) > r - 10:
            continue
        ci.draw_circle(q, 6.0, Color(0.95, 0.66, 0.14, 0.30))
        ci.draw_arc(q, 6.0, 0, TAU, 20, AMBER, 1.4)
        if f != null:
            ci.draw_string(f, q + Vector2(-4, -9), str(site.name),
                           HORIZONTAL_ALIGNMENT_LEFT, -1, 12, AMBER)
    if G.match_mgr.bomb_planted:
        var db = Vector2(G.match_mgr.bomb_pos.x, G.match_mgr.bomb_pos.z) - pp
        var rb = Vector2(db.x * cosy - db.y * siny, db.x * siny + db.y * cosy) * sc
        ci.draw_circle(c + rb, 3.5, RED)
    # combatentes
    for s in G.match_mgr.all_soldiers():
        if s == p or not s.alive:
            continue
        var ds = Vector2(s.global_position.x, s.global_position.z) - pp
        var rs = Vector2(ds.x * cosy - ds.y * siny, ds.x * siny + ds.y * cosy) * sc
        var qs = c + rs
        if qs.distance_to(c) > r - 6:
            continue
        ci.draw_circle(qs, 3.2, BLUE if s.team == G.TEAM_ATTACK else RED)
    # seta do jogador
    var tri = PackedVector2Array([c + Vector2(0, -9), c + Vector2(-6, 6), c + Vector2(6, 6)])
    ci.draw_colored_polygon(tri, Color(0.96, 0.96, 0.93, 1))
    ci.draw_line(Vector2(c.x, 4), Vector2(c.x, 12), Color(0.75, 0.76, 0.72, 0.8), 2.0)

func paint_crosshair(ci: Control) -> void:
    var c = ci.size * 0.5
    var gap = 5.0 + kick
    if G.player != null and G.player.weapon != null:
        var spread = G.player.weapon.current_spread_deg(G.player.aiming,
            Vector2(G.player.velocity.x, G.player.velocity.z).length(),
            G.player.crouched, not G.player.is_on_floor())
        gap += spread * 1.8
    var col = Color(0.92, 0.93, 0.90, 0.90)
    ci.draw_line(c + Vector2(-gap - 7, 0), c + Vector2(-gap, 0), col, 1.5)
    ci.draw_line(c + Vector2(gap, 0), c + Vector2(gap + 7, 0), col, 1.5)
    ci.draw_line(c + Vector2(0, -gap - 7), c + Vector2(0, -gap), col, 1.5)
    ci.draw_line(c + Vector2(0, gap), c + Vector2(0, gap + 7), col, 1.5)
    ci.draw_rect(Rect2(c - Vector2(1, 1), Vector2(2, 2)), col, true)
    if hit_t > 0.0:
        var hc = RED if hit_head or hit_kill else Color(0.96, 0.96, 0.92)
        hc.a = clampf(hit_t / 0.22, 0.0, 1.0)
        var d = 6.0
        ci.draw_line(c + Vector2(-d, -d), c + Vector2(-d + 5, -d + 5), hc, 1.8)
        ci.draw_line(c + Vector2(d, -d), c + Vector2(d - 5, -d + 5), hc, 1.8)
        ci.draw_line(c + Vector2(-d, d), c + Vector2(-d + 5, d - 5), hc, 1.8)
        ci.draw_line(c + Vector2(d, d), c + Vector2(d - 5, d - 5), hc, 1.8)

func paint_compass(_ci: Control) -> void:
    pass
