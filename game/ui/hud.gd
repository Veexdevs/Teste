extends CanvasLayer
## HUD tactico: saude, municao, mira dinamica, minimapa, bussola, feed,
## objectivo, compras, pausa, placar e sobreposicoes.

var root: Control
var top_bar: Panel
var lbl_round: Label
var lbl_timer: Label
var lbl_score: Label
var lbl_alive: Label
var lbl_objective: Label
var crosshair: Control
var minimap: Control
var compass: Control
var vignette: ColorRect
var bars = {}
var lbl_health: Label
var lbl_armor: Label
var lbl_stamina: Label
var lbl_ammo: Label
var lbl_weapon: Label
var lbl_mode: Label
var feed_labels: Array = []
var lbl_interact: Label
var interact_bg: ColorRect
var interact_fill: ColorRect
var build_panel: Panel
var lbl_build: Label
var build_bg: ColorRect
var build_fill: ColorRect
var lbl_flash: Label
var lbl_banner: Label
var lbl_banner_sub: Label
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

var hit_t = 0.0
var hit_head = false
var hit_kill = false
var kick = 0.0
var banner_t = 0.0
var flash_t = 0.0
var vignette_a = 0.0
var pause_open = false
var pause_lock = 0.0
var help_open = false
var build_active = false
var build_selected = "sandbag"
var build_progress = 0.0
var interact_progress = 0.0
var dead = false

const FONT = "font_size"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 10
    root = Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)
    _build_top()
    _build_overlays()
    _build_bottom()
    _build_crosshair()
    _build_minimap()
    _build_compass()
    _build_buy()
    _build_panels()
    G.note("hud: interface construida")

func _style(color: Color) -> StyleBoxFlat:
    var s = StyleBoxFlat.new()
    s.bg_color = color
    s.set_corner_radius_all(4)
    s.border_width_left = 1
    s.border_width_right = 1
    s.border_width_top = 1
    s.border_width_bottom = 1
    s.border_color = Color(0.35, 0.42, 0.34, 0.65)
    return s

func _lbl(text: String, size: int, color: Color, parent: Control, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var l = Label.new()
    l.text = text
    l.add_theme_font_size_override(FONT, size)
    l.add_theme_color_override("font_color", color)
    l.horizontal_alignment = align
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(l)
    return l

func _build_top() -> void:
    top_bar = Panel.new()
    top_bar.add_theme_stylebox_override("panel", _style(Color(0.055, 0.075, 0.065, 0.80)))
    root.add_child(top_bar)
    lbl_round = _lbl("RONDA 1", 17, Color(0.86, 0.92, 0.78), top_bar)
    lbl_timer = _lbl("02:30", 26, Color(0.98, 0.90, 0.62), top_bar, HORIZONTAL_ALIGNMENT_CENTER)
    lbl_score = _lbl("ASSALTO 0  -  0 DEFESA", 18, Color(0.90, 0.94, 0.86), top_bar, HORIZONTAL_ALIGNMENT_CENTER)
    lbl_alive = _lbl("4 x 5", 15, Color(0.70, 0.80, 0.70), top_bar, HORIZONTAL_ALIGNMENT_CENTER)
    lbl_objective = _lbl("PLANEAMENTO", 14, Color(0.65, 0.85, 0.65), top_bar, HORIZONTAL_ALIGNMENT_RIGHT)
    for i in range(6):
        feed_labels.append(_lbl("", 13, Color(0.92, 0.86, 0.72), root, HORIZONTAL_ALIGNMENT_RIGHT))

func _build_overlays() -> void:
    vignette = ColorRect.new()
    vignette.color = Color(0.65, 0.03, 0.02, 0.0)
    vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(vignette)
    lbl_banner = _lbl("", 30, Color(0.98, 0.93, 0.72), root, HORIZONTAL_ALIGNMENT_CENTER)
    lbl_banner_sub = _lbl("", 15, Color(0.80, 0.86, 0.76), root, HORIZONTAL_ALIGNMENT_CENTER)
    lbl_flash = _lbl("", 16, Color(0.95, 0.90, 0.55), root, HORIZONTAL_ALIGNMENT_CENTER)
    lbl_interact = _lbl("", 17, Color(0.95, 0.92, 0.72), root, HORIZONTAL_ALIGNMENT_CENTER)
    interact_bg = ColorRect.new()
    interact_bg.color = Color(0, 0, 0, 0.65)
    interact_fill = ColorRect.new()
    interact_fill.color = Color(0.95, 0.72, 0.20, 0.9)
    root.add_child(interact_bg)
    root.add_child(interact_fill)
    build_panel = Panel.new()
    build_panel.add_theme_stylebox_override("panel", _style(Color(0.06, 0.09, 0.07, 0.82)))
    root.add_child(build_panel)
    lbl_build = _lbl("", 15, Color(0.82, 0.95, 0.78), build_panel)
    build_bg = ColorRect.new()
    build_bg.color = Color(0.1, 0.1, 0.1, 0.8)
    build_fill = ColorRect.new()
    build_fill.color = Color(0.45, 0.85, 0.45, 0.95)
    build_panel.add_child(build_bg)
    build_panel.add_child(build_fill)

func _bar(name: String, color: Color) -> void:
    var bg = ColorRect.new()
    bg.color = Color(0.02, 0.03, 0.02, 0.80)
    root.add_child(bg)
    var fill = ColorRect.new()
    fill.color = color
    root.add_child(fill)
    bars[name] = {"bg": bg, "fill": fill}

func _build_bottom() -> void:
    _bar("health", Color(0.78, 0.20, 0.16))
    _bar("armor", Color(0.32, 0.58, 0.82))
    _bar("stamina", Color(0.72, 0.78, 0.38))
    lbl_health = _lbl("SAUDE 100", 14, Color(0.92, 0.88, 0.82), root)
    lbl_armor = _lbl("COLETE 0", 13, Color(0.72, 0.84, 0.95), root)
    lbl_stamina = _lbl("FOLEGO 100", 13, Color(0.84, 0.88, 0.62), root)
    lbl_ammo = _lbl("30 / 120", 36, Color(0.96, 0.94, 0.82), root, HORIZONTAL_ALIGNMENT_RIGHT)
    lbl_weapon = _lbl("M4A1 CARBINE", 15, Color(0.78, 0.86, 0.76), root, HORIZONTAL_ALIGNMENT_RIGHT)
    lbl_mode = _lbl("5.56x45 NATO  |  AUTO", 12, Color(0.62, 0.70, 0.62), root, HORIZONTAL_ALIGNMENT_RIGHT)

func _build_crosshair() -> void:
    crosshair = preload("res://game/ui/crosshair.gd").new()
    crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(crosshair)

func _build_minimap() -> void:
    minimap = preload("res://game/ui/minimap.gd").new()
    minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(minimap)

func _build_compass() -> void:
    compass = preload("res://game/ui/compass.gd").new()
    compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(compass)

func _button(text: String, parent: Control, cb: Callable, size: int = 14) -> Button:
    var b = Button.new()
    b.text = text
    b.add_theme_font_size_override(FONT, size)
    b.add_theme_color_override("font_color", Color(0.90, 0.94, 0.84))
    b.add_theme_color_override("font_hover_color", Color(1.0, 0.90, 0.55))
    b.add_theme_stylebox_override("normal", _style(Color(0.13, 0.18, 0.14, 0.95)))
    b.add_theme_stylebox_override("hover", _style(Color(0.22, 0.30, 0.20, 0.98)))
    b.add_theme_stylebox_override("pressed", _style(Color(0.30, 0.38, 0.24, 1.0)))
    b.custom_minimum_size = Vector2(0, 32)
    parent.add_child(b)
    b.pressed.connect(cb)
    return b

func _build_buy() -> void:
    buy_panel = Panel.new()
    buy_panel.add_theme_stylebox_override("panel", _style(Color(0.045, 0.060, 0.050, 0.95)))
    root.add_child(buy_panel)
    var title = _lbl("ARMARIA / PLANEAMENTO", 22, Color(0.95, 0.90, 0.65), buy_panel)
    title.name = "Title"
    lbl_money = _lbl("CREDITO: $800", 18, Color(0.65, 0.95, 0.65), buy_panel)
    lbl_money.name = "Money"
    buy_list = VBoxContainer.new()
    buy_list.add_theme_constant_override("separation", 5)
    buy_panel.add_child(buy_list)
    for item in G.buy_items:
        var key: String = item.key
        _button("%s   $%d" % [item.label, item.price], buy_list, func(): G.match_mgr.buy(key), 13)
    _button(">> INICIAR RONDA <<", buy_list, func(): G.match_mgr.force_start(), 16)
    var hint = _lbl("Compra com o rato / toque. As fortificacoes constroem-se com [B] durante a ronda.",
        12, Color(0.62, 0.70, 0.62), buy_panel)
    hint.name = "Hint"
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_panels() -> void:
    pause_panel = Panel.new()
    pause_panel.add_theme_stylebox_override("panel", _style(Color(0.04, 0.06, 0.05, 0.96)))
    root.add_child(pause_panel)
    var pt = _lbl("PAUSA", 26, Color(0.95, 0.92, 0.70), pause_panel, HORIZONTAL_ALIGNMENT_CENTER)
    pt.name = "Title"
    var pv = VBoxContainer.new()
    pv.name = "Buttons"
    pause_panel.add_child(pv)
    _button("CONTINUAR", pv, func(): toggle_pause(false))
    _button("REINICIAR PARTIDA", pv, func(): G.main.restart())
    _button("CONTROLES", pv, func(): toggle_help())
    _button("SAIR DO JOGO", pv, func(): get_tree().quit())

    score_panel = Panel.new()
    score_panel.add_theme_stylebox_override("panel", _style(Color(0.04, 0.06, 0.05, 0.94)))
    root.add_child(score_panel)
    var st = _lbl("PLACAR DA OPERACAO", 20, Color(0.95, 0.92, 0.70), score_panel, HORIZONTAL_ALIGNMENT_CENTER)
    st.name = "Title"
    score_list = VBoxContainer.new()
    score_panel.add_child(score_list)

    help_panel = Panel.new()
    help_panel.add_theme_stylebox_override("panel", _style(Color(0.04, 0.06, 0.05, 0.97)))
    root.add_child(help_panel)
    var ht = _lbl("CONTROLES", 22, Color(0.95, 0.92, 0.70), help_panel, HORIZONTAL_ALIGNMENT_CENTER)
    ht.name = "Title"
    var txt = _lbl(
        "WASD mover  |  RATO olhar  |  SHIFT correr  |  CTRL agachar  |  ESPACO saltar\n" +
        "ESQ atirar  |  DIR mirar  |  R recarregar  |  1/2 trocar arma\n" +
        "Q / E inclinar  |  F plantar/desactivar (manter)  |  B modo fortificacao\n" +
        "V ciclo de cobertura  |  T rodar  |  TAB placar  |  ESC pausa  |  F1 ajuda\n\n" +
        "No telemovel: joystick esquerdo, arrastar a direita para olhar, botoes de accao.",
        14, Color(0.82, 0.88, 0.78), help_panel)
    txt.name = "Text"
    txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _button("FECHAR", help_panel, func(): toggle_help(false), 14)

    death_panel = Panel.new()
    death_panel.add_theme_stylebox_override("panel", _style(Color(0.12, 0.03, 0.03, 0.80)))
    root.add_child(death_panel)
    var dt = _lbl("ABATIDO EM COMBATE", 28, Color(1.0, 0.70, 0.60), death_panel, HORIZONTAL_ALIGNMENT_CENTER)
    dt.name = "Title"
    var ds = _lbl("A observar a equipa - clique para alternar operador", 14,
        Color(0.92, 0.80, 0.76), death_panel, HORIZONTAL_ALIGNMENT_CENTER)
    ds.name = "Sub"
    death_panel.visible = false

    end_panel = Panel.new()
    end_panel.add_theme_stylebox_override("panel", _style(Color(0.04, 0.06, 0.05, 0.97)))
    root.add_child(end_panel)
    lbl_end = _lbl("", 26, Color(0.95, 0.92, 0.70), end_panel, HORIZONTAL_ALIGNMENT_CENTER)
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

func toggle_pause(on: bool) -> void:
    pause_open = on
    pause_panel.visible = on
    get_tree().paused = on
    G.controls.enabled = not on
    G.controls.set_capture(not on)
    pause_lock = 0.25
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
    flash_t = 2.4

func banner(title: String, sub: String, dur: float) -> void:
    lbl_banner.text = title
    lbl_banner_sub.text = sub
    banner_t = dur

func hitmarker(head: bool, kill: bool) -> void:
    hit_t = 0.22
    hit_head = head
    hit_kill = kill

func crosshair_kick() -> void:
    kick = minf(kick + 5.0, 16.0)

func damage_flash() -> void:
    vignette_a = 0.42

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
    pause_lock = maxf(0.0, pause_lock - delta)
    if G.match_mgr == null:
        return
    _update_texts(delta)
    hit_t = maxf(0.0, hit_t - delta)
    kick = maxf(0.0, kick - delta * 34.0)
    banner_t = maxf(0.0, banner_t - delta)
    flash_t = maxf(0.0, flash_t - delta)
    vignette_a = maxf(0.0, vignette_a - delta * 0.9)
    vignette.color.a = vignette_a
    lbl_banner.modulate.a = clampf(banner_t, 0.0, 1.0)
    lbl_banner_sub.modulate.a = clampf(banner_t, 0.0, 1.0)
    lbl_flash.modulate.a = clampf(flash_t, 0.0, 1.0)
    crosshair.queue_redraw()
    minimap.queue_redraw()
    compass.queue_redraw()

func _layout(W: float, H: float) -> void:
    top_bar.position = Vector2(12, 8)
    top_bar.size = Vector2(W - 24, 62)
    lbl_round.position = Vector2(12, 6)
    lbl_round.size = Vector2(150, 24)
    lbl_timer.position = Vector2(W * 0.5 - 90, 2)
    lbl_timer.size = Vector2(180, 34)
    lbl_score.position = Vector2(W * 0.5 - 180, 36)
    lbl_score.size = Vector2(360, 22)
    lbl_alive.position = Vector2(W * 0.5 - 40, 2)
    lbl_alive.size = Vector2(80, 22)
    lbl_objective.position = Vector2(W - 300, 10)
    lbl_objective.size = Vector2(280, 24)
    for i in range(feed_labels.size()):
        feed_labels[i].position = Vector2(W - 430, 78 + i * 20)
        feed_labels[i].size = Vector2(410, 20)
    minimap.position = Vector2(14, 80)
    minimap.size = Vector2(156, 156)
    compass.position = Vector2(W * 0.5 - 190, 74)
    compass.size = Vector2(380, 26)
    crosshair.position = Vector2(W * 0.5 - 60, H * 0.5 - 60)
    crosshair.size = Vector2(120, 120)
    vignette.position = Vector2.ZERO
    vignette.size = Vector2(W, H)
    var bw = 210.0
    var bx = 18.0
    var by = H - 112.0
    bars.health.bg.position = Vector2(bx, by)
    bars.health.bg.size = Vector2(bw, 15)
    bars.health.fill.position = Vector2(bx, by)
    bars.health.fill.size = Vector2(bw, 15)
    bars.armor.bg.position = Vector2(bx, by + 22)
    bars.armor.bg.size = Vector2(bw, 11)
    bars.armor.fill.position = Vector2(bx, by + 22)
    bars.armor.fill.size = Vector2(bw, 11)
    bars.stamina.bg.position = Vector2(bx, by + 39)
    bars.stamina.bg.size = Vector2(bw, 11)
    bars.stamina.fill.position = Vector2(bx, by + 39)
    bars.stamina.fill.size = Vector2(bw, 11)
    lbl_health.position = Vector2(bx + 2, by - 20)
    lbl_health.size = Vector2(bw, 20)
    lbl_armor.position = Vector2(bx + bw + 8, by + 18)
    lbl_armor.size = Vector2(160, 20)
    lbl_stamina.position = Vector2(bx + bw + 8, by + 36)
    lbl_stamina.size = Vector2(160, 20)
    lbl_ammo.position = Vector2(W - 300, H - 92)
    lbl_ammo.size = Vector2(282, 46)
    lbl_weapon.position = Vector2(W - 300, H - 128)
    lbl_weapon.size = Vector2(282, 24)
    lbl_mode.position = Vector2(W - 300, H - 46)
    lbl_mode.size = Vector2(282, 20)
    lbl_banner.position = Vector2(W * 0.5 - 350, H * 0.24)
    lbl_banner.size = Vector2(700, 42)
    lbl_banner_sub.position = Vector2(W * 0.5 - 350, H * 0.24 + 44)
    lbl_banner_sub.size = Vector2(700, 26)
    lbl_flash.position = Vector2(W * 0.5 - 260, H * 0.68)
    lbl_flash.size = Vector2(520, 26)
    lbl_interact.position = Vector2(W * 0.5 - 240, H * 0.62)
    lbl_interact.size = Vector2(480, 28)
    interact_bg.position = Vector2(W * 0.5 - 150, H * 0.62 + 30)
    interact_bg.size = Vector2(300, 9)
    interact_fill.position = interact_bg.position
    interact_fill.size = Vector2(300 * clampf(interact_progress, 0.0, 1.0), 9)
    interact_bg.visible = interact_progress > 0.0
    interact_fill.visible = interact_bg.visible
    build_panel.position = Vector2(W * 0.5 - 190, H - 78)
    build_panel.size = Vector2(380, 62)
    build_panel.visible = build_active
    lbl_build.position = Vector2(12, 6)
    lbl_build.size = Vector2(356, 22)
    build_bg.position = Vector2(12, 34)
    build_bg.size = Vector2(356, 12)
    build_fill.position = build_bg.position
    build_fill.size = Vector2(356 * clampf(build_progress, 0.0, 1.0), 12)
    var pw = minf(560.0, W - 60.0)
    var ph = minf(560.0, H - 40.0)
    buy_panel.position = Vector2(W * 0.5 - pw * 0.5, H * 0.5 - ph * 0.5)
    buy_panel.size = Vector2(pw, ph)
    var btitle = buy_panel.get_node_or_null("Title") as Label
    if btitle:
        btitle.position = Vector2(18, 12)
        btitle.size = Vector2(pw - 36, 32)
    lbl_money.position = Vector2(18, 44)
    lbl_money.size = Vector2(pw - 36, 26)
    buy_list.position = Vector2(18, 78)
    buy_list.size = Vector2(pw - 36, ph - 130)
    var bhint = buy_panel.get_node_or_null("Hint") as Label
    if bhint:
        bhint.position = Vector2(18, ph - 46)
        bhint.size = Vector2(pw - 36, 40)
    _layout_panel(pause_panel, W, H, 380, 320)
    _layout_panel(score_panel, W, H, 480, 420)
    _layout_panel(help_panel, W, H, 620, 320)
    _layout_panel(death_panel, W, H, 520, 110)
    _layout_panel(end_panel, W, H, 460, 260)

func _layout_panel(p: Panel, W: float, H: float, pw: float, ph: float) -> void:
    p.position = Vector2(W * 0.5 - pw * 0.5, H * 0.5 - ph * 0.5)
    p.size = Vector2(pw, ph)
    var t = p.get_node_or_null("Title") as Label
    if t:
        t.position = Vector2(12, 12)
        t.size = Vector2(pw - 24, 44)
    var v = p.get_node_or_null("Buttons") as VBoxContainer
    if v:
        v.position = Vector2(24, 70)
        v.size = Vector2(pw - 48, ph - 90)
    var sub = p.get_node_or_null("Sub") as Label
    if sub:
        sub.position = Vector2(12, 58)
        sub.size = Vector2(pw - 24, 28)
    var txt = p.get_node_or_null("Text") as Label
    if txt:
        txt.position = Vector2(24, 60)
        txt.size = Vector2(pw - 48, ph - 120)
    if p == help_panel:
        var btn = p.get_child(p.get_child_count() - 1) as Button
        if btn:
            btn.position = Vector2(24, ph - 50)
            btn.size = Vector2(pw - 48, 34)
    if p == score_panel:
        score_list.position = Vector2(20, 64)
        score_list.size = Vector2(pw - 40, ph - 80)

func _update_texts(delta: float) -> void:
    var m = G.match_mgr
    var p = G.player
    lbl_round.text = "RONDA %d / %d" % [m.round_no, int(G.tuning.rounds_to_win) * 2 - 1]
    lbl_score.text = "ASSALTO  %d   -   %d  DEFESA" % [m.score[0], m.score[1]]
    lbl_alive.text = "%d  x  %d" % [m.alive_count(G.TEAM_ATTACK), m.alive_count(G.TEAM_DEFEND)]
    if m.bomb_planted:
        lbl_timer.text = "%02d:%02d" % [int(m.bomb_timer) / 60, int(m.bomb_timer) % 60]
        lbl_objective.text = "CARGA ACTIVA - LOCAL " + str(m.bomb_site.name)
    elif m.state == "BUY":
        lbl_timer.text = "%02d:%02d" % [int(m.phase_left) / 60, int(m.phase_left) % 60]
        lbl_objective.text = "PLANEAMENTO / COMPRAS"
    elif m.state == "LIVE":
        lbl_timer.text = "%02d:%02d" % [int(m.round_left) / 60, int(m.round_left) % 60]
        lbl_objective.text = "PLANTAR CARGA EM A OU B"
    else:
        lbl_timer.text = "--:--"
        lbl_objective.text = m.last_reason
    lbl_money.text = "CREDITO: $%d" % m.money
    for i in range(feed_labels.size()):
        var idx = m.kill_feed.size() - 1 - i
        feed_labels[i].text = str(m.kill_feed[idx].text) if idx >= 0 else ""
        if idx >= 0:
            feed_labels[i].modulate.a = clampf(1.0 - float(m.kill_feed[idx].t) / 8.0, 0.2, 1.0)
    for k in m.kill_feed:
        k.t += delta
    if p == null:
        return
    bars.health.fill.size.x = 210.0 * clampf(p.health / 100.0, 0.0, 1.0)
    bars.armor.fill.size.x = 210.0 * clampf(p.armor / 100.0, 0.0, 1.0)
    bars.stamina.fill.size.x = 210.0 * clampf(p.stamina / G.tuning.stamina_max, 0.0, 1.0)
    lbl_health.text = "SAUDE %d" % int(round(p.health))
    lbl_armor.text = "COLETE %d" % int(round(p.armor))
    lbl_stamina.text = "FOLEGO %d" % int(round(p.stamina))
    if p.weapon != null:
        lbl_ammo.text = "%d / %d" % [p.weapon.mag, p.weapon.reserve]
        lbl_weapon.text = str(p.weapon.data.name)
        lbl_mode.text = "%s  |  %s" % [str(p.weapon.data.cal), "AUTO" if p.weapon.data.auto else "SEMI"]
    if dead and p.alive:
        dead = false
        death_panel.visible = false
    score_panel.visible = G.controls.scoreboard and not pause_open
    if score_panel.visible:
        _fill_score()
    if build_active:
        var cfg: Dictionary = G.fortifications[build_selected]
        lbl_build.text = "FORTIFICACAO: %s   |   CARGAS: %d" % [str(cfg.name), int(p.build_sys.charges.get(build_selected, 0))]
        if build_progress <= 0.0:
            lbl_build.text += "   |   [V] alternar   [T] rodar"

func _fill_score() -> void:
    for c in score_list.get_children():
        c.queue_free()
    var t1 = _lbl("ASSALTO                     K / D", 14, Color(0.65, 0.90, 0.65), score_list)
    t1.custom_minimum_size = Vector2(0, 26)
    for s in G.match_mgr.all_soldiers():
        if s.team != G.TEAM_ATTACK:
            continue
        _lbl("  %s   %d / %d" % [s.display_name, s.kills, s.deaths], 13,
            Color(0.85, 0.92, 0.82) if s.alive else Color(0.55, 0.55, 0.55), score_list)
    var t2 = _lbl("DEFESA                      K / D", 14, Color(0.65, 0.78, 0.95), score_list)
    t2.custom_minimum_size = Vector2(0, 26)
    for s in G.match_mgr.all_soldiers():
        if s.team != G.TEAM_DEFEND:
            continue
        _lbl("  %s   %d / %d" % [s.display_name, s.kills, s.deaths], 13,
            Color(0.85, 0.92, 0.82) if s.alive else Color(0.55, 0.55, 0.55), score_list)

func paint_crosshair(ci: Control) -> void:
    var c = Vector2(60, 60)
    var gap = 6.0 + kick
    if G.player != null and G.player.weapon != null:
        var spread = G.player.weapon.current_spread_deg(G.player.aiming,
            Vector2(G.player.velocity.x, G.player.velocity.z).length(),
            G.player.crouched, not G.player.is_on_floor())
        gap += spread * 2.4
    if G.player != null and G.player.build_sys != null and G.player.build_sys.active:
        gap = 3.0
    var col = Color(0.88, 0.96, 0.84, 0.92)
    ci.draw_line(c + Vector2(-gap - 9, 0), c + Vector2(-gap, 0), col, 2.0)
    ci.draw_line(c + Vector2(gap, 0), c + Vector2(gap + 9, 0), col, 2.0)
    ci.draw_line(c + Vector2(0, -gap - 9), c + Vector2(0, -gap), col, 2.0)
    ci.draw_line(c + Vector2(0, gap), c + Vector2(0, gap + 9), col, 2.0)
    ci.draw_rect(Rect2(c - Vector2(1, 1), Vector2(2, 2)), col, true)
    if hit_t > 0.0:
        var hc = Color(1.0, 0.35, 0.25) if hit_head else Color(0.95, 0.95, 0.90)
        if hit_kill:
            hc = Color(1.0, 0.25, 0.20)
        hc.a = clampf(hit_t / 0.22, 0.0, 1.0)
        var d = 7.0
        ci.draw_line(c + Vector2(-d, -d), c + Vector2(-d + 5, -d + 5), hc, 2.0)
        ci.draw_line(c + Vector2(d, -d), c + Vector2(d - 5, -d + 5), hc, 2.0)
        ci.draw_line(c + Vector2(-d, d), c + Vector2(-d + 5, d - 5), hc, 2.0)
        ci.draw_line(c + Vector2(d, d), c + Vector2(d - 5, d - 5), hc, 2.0)

func paint_minimap(ci: Control) -> void:
    var sz = 156.0
    ci.draw_rect(Rect2(Vector2.ZERO, Vector2(sz, sz)), Color(0.05, 0.08, 0.06, 0.72), true)
    ci.draw_rect(Rect2(Vector2.ZERO, Vector2(sz, sz)), Color(0.45, 0.55, 0.40, 0.55), false, 1.0)
    var p = G.player
    if p == null:
        return
    var center = Vector2(sz * 0.5, sz * 0.5)
    var sc = 1.55
    var pp = Vector2(p.global_position.x, p.global_position.z)
    for site in G.world.sites:
        var sp = (Vector2(site.pos.x, site.pos.z) - pp) * sc + center
        if sp.x > 2 and sp.x < sz - 2 and sp.y > 2 and sp.y < sz - 2:
            ci.draw_circle(sp, 7.0, Color(1.0, 0.62, 0.18, 0.35))
            ci.draw_arc(sp, 7.0, 0, TAU, 16, Color(1.0, 0.68, 0.20, 0.9), 1.5)
    if G.match_mgr.bomb_planted:
        ci.draw_circle((Vector2(G.match_mgr.bomb_pos.x, G.match_mgr.bomb_pos.z) - pp) * sc + center,
            4.0, Color(1.0, 0.2, 0.15))
    for s in G.match_mgr.all_soldiers():
        if not s.alive or s == p:
            continue
        if s.team != G.TEAM_ATTACK and s.global_position.distance_to(p.global_position) > 26.0:
            continue
        var sp2 = (Vector2(s.global_position.x, s.global_position.z) - pp) * sc + center
        if sp2.x < 3 or sp2.x > sz - 3 or sp2.y < 3 or sp2.y > sz - 3:
            continue
        ci.draw_circle(sp2, 3.4, Color(0.35, 0.85, 0.45) if s.team == G.TEAM_ATTACK else Color(0.95, 0.32, 0.25))
    ci.draw_circle(center, 3.6, Color(0.98, 0.98, 0.90))
    var fwd = -p.global_transform.basis.z
    ci.draw_line(center, center + Vector2(fwd.x, fwd.z) * 10.0, Color(0.98, 0.98, 0.90), 1.5)

func paint_compass(ci: Control) -> void:
    var W = 380.0
    ci.draw_rect(Rect2(Vector2(0, 0), Vector2(W, 24)), Color(0.05, 0.07, 0.06, 0.62), true)
    var p = G.player
    if p == null:
        return
    var yaw = p.rotation.y
    var font = ThemeDB.fallback_font
    var dirs = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]
    for i in range(8):
        var a = float(i) * TAU / 8.0
        var x = fmod(fmod(W * 0.5 + (a + yaw) / PI * W * 0.5, W) + W, W)
        if x < 14.0 or x > W - 14.0:
            continue
        ci.draw_line(Vector2(x, 16), Vector2(x, 23), Color(0.75, 0.82, 0.70, 0.8), 1.0)
        if font != null:
            ci.draw_string(font, Vector2(x - 8, 13), dirs[i], HORIZONTAL_ALIGNMENT_CENTER, 16, 11, Color(0.88, 0.92, 0.78))
    ci.draw_line(Vector2(W * 0.5, 2), Vector2(W * 0.5, 18), Color(1.0, 0.85, 0.35), 2.0)
