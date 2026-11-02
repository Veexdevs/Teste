extends Node3D
## Ponto de entrada: arranque, ciclo de vida da partida, interface,
## som ambiente e modo de auto-verificacao para CI.

var self_test = false
var selftest_frames = 0
var selftest_done = false
var selftest_started = false
var errors: Array = []
var ambient_t = 0.0
var menu_layer: CanvasLayer
var pause_lock = 0.0

func _ready() -> void:
    randomize()
    for a in OS.get_cmdline_user_args():
        if a == "--selftest":
            self_test = true
    G.main = self
    G.controls = preload("res://game/core/controls.gd").new()
    add_child(G.controls)
    G.materials = preload("res://game/core/materials.gd").new()
    add_child(G.materials)
    G.audio = preload("res://game/core/audio.gd").new()
    add_child(G.audio)
    G.models = preload("res://game/core/models.gd").new()
    add_child(G.models)
    G.world = preload("res://game/world/world.gd").new()
    add_child(G.world)
    G.world.build()
    G.fx = preload("res://game/world/fx.gd").new()
    add_child(G.fx)
    G.match_mgr = preload("res://game/match/match.gd").new()
    add_child(G.match_mgr)
    G.hud = preload("res://game/ui/hud.gd").new()
    add_child(G.hud)
    G.touch = preload("res://game/ui/touch.gd").new()
    add_child(G.touch)
    _setup_touch()
    G.audio.play_ambient()
    if self_test:
        G.note("SELFTEST: a iniciar verificacao automatica")
        start_match(0.65, "m4a1")
        G.match_mgr.force_start()
        selftest_started = true
    else:
        menu_layer = preload("res://game/ui/menu.gd").new()
        add_child(menu_layer)
        G.controls.set_capture(false)
    G.note("[SENTINELA] boot: sistemas prontos")

func _setup_touch() -> void:
    if G.touch == null or not G.is_mobile():
        return
    G.touch.add_button("FOGO", "fire", true, Vector2(40, 40), Vector2(86, 86), 15)
    G.touch.add_button("MIRA", "aim", true, Vector2(132, 40), Vector2(76, 76), 13)
    G.touch.add_button("RECAR", "reload", false, Vector2(40, 132), Vector2(72, 58), 12)
    G.touch.add_button("SALTO", "jump", false, Vector2(118, 132), Vector2(72, 58), 12)
    G.touch.add_button("AGACH", "crouch", true, Vector2(196, 132), Vector2(72, 58), 12)
    G.touch.add_button("USAR", "interact", true, Vector2(40, 198), Vector2(72, 58), 12)
    G.touch.add_button("BUILD", "build_toggle", false, Vector2(118, 198), Vector2(72, 58), 12)
    G.touch.add_button("TROCA", "build_cycle", false, Vector2(196, 198), Vector2(72, 58), 12)
    G.touch.add_button("RODAR", "build_rotate", false, Vector2(274, 198), Vector2(72, 58), 12)
    G.touch.add_button("1/2", "secondary", false, Vector2(274, 132), Vector2(72, 58), 12)
    G.touch.add_button("PAUSA", "pause", false, Vector2(20, 16), Vector2(72, 40), 11)
    G.touch.layout()
    get_viewport().size_changed.connect(func(): G.touch.layout())

func start_match(difficulty: float, primary: String) -> void:
    if menu_layer != null and is_instance_valid(menu_layer):
        menu_layer.queue_free()
        menu_layer = null
    G.match_mgr.reset()
    G.audio.play_ambient()
    G.match_mgr.start(difficulty)
    if G.player != null and G.player.has_method("change_primary"):
        G.player.change_primary(primary)
    G.hud.dead = false
    G.hud.death_panel.visible = false
    G.hud.end_panel.visible = false
    G.hud.toggle_pause(false)
    G.controls.enabled = false
    G.controls.set_capture(false)

func restart() -> void:
    start_match(G.match_mgr.difficulty, "m4a1")

func _physics_process(delta: float) -> void:
    G.controls.poll(delta)
    pause_lock = maxf(0.0, pause_lock - delta)
    if G.controls.pause and pause_lock <= 0.0 and G.match_mgr.state != "MENU" and G.match_mgr.state != "MATCH_END":
        G.hud.toggle_pause(not G.hud.pause_open)
        pause_lock = 0.3
    if G.controls.help and pause_lock <= 0.0:
        G.hud.toggle_help(not G.hud.help_open)
        pause_lock = 0.3
    if self_test and not selftest_done:
        _selftest_step(delta)
    # As acoes de borda sao consumidas apos a fisica de todos os nos.
    call_deferred("_clear_edges")

func _clear_edges() -> void:
    G.controls.clear_edges()

func _process(delta: float) -> void:
    ambient_t -= delta
    if ambient_t <= 0.0:
        ambient_t = G.rng_range(14.0, 28.0)
        if G.audio != null:
            G.audio.play_at("wind", Vector3(G.rng_range(-40, 40), 2.0, G.rng_range(-40, 40)), -25.0, G.rng_range(0.85, 1.15))

func _selftest_step(delta: float) -> void:
    selftest_frames += 1
    if selftest_frames == 3:
        _selftest_check(delta)
    if selftest_frames > 90:
        _selftest_finish()

func _selftest_check(_delta: float) -> void:
    var m = G.match_mgr
    var checks = []
    checks.append(["mundo construido", G.world.props.size() > 120, str(G.world.props.size()) + " props"])
    checks.append(["pontos de cobertura", G.world.cover_points.size() > 100, str(G.world.cover_points.size())])
    checks.append(["objectivos", G.world.sites.size() == 2, str(G.world.sites.size())])
    checks.append(["audio sintetizado", G.audio.streams.size() >= 12, str(G.audio.streams.size()) + " amostras"])
    checks.append(["modelos glTF", G.models.cache.size() > 0, str(G.models.cache.size())])
    checks.append(["jogador", G.player != null and is_instance_valid(G.player), str(G.player != null)])
    checks.append(["combatentes", m.all_soldiers().size() >= 8, str(m.all_soldiers().size())])
    checks.append(["armas", G.player != null and G.player.weapons.size() == 2, str(G.player.weapons.size())])
    checks.append(["hud", G.hud.root != null, "ok"])
    checks.append(["interface de compra", G.hud.buy_list.get_child_count() >= 8, str(G.hud.buy_list.get_child_count())])
    var s = m.all_soldiers()[2]
    checks.append(["IA com arma", s.weapon != null, "ok"])
    checks.append(["balistica", _selftest_ballistic(), "tracador/impacto"])
    checks.append(["fortificacao", _selftest_fort(), "carga montada"])
    checks.append(["carga C4", _selftest_bomb(), "plantar/desactivar"])
    checks.append(["animacao de viewmodel", G.player.weapon.view_anim == null or G.player.weapon.clip_idle != "", "clipes"])
    for c in checks:
        if not bool(c[1]):
            errors.append(str(c[0]) + " (" + str(c[2]) + ")")
            push_error("SELFTEST FAIL: " + str(c[0]))

func _selftest_ballistic() -> bool:
    var w = G.player.weapon
    w.refill()
    var before = w.mag
    var origin = G.player.global_position + Vector3(0, 1.5, 0)
    w.fire(origin, Vector3(0, 0, -1), 0.0, false)
    return w.mag == before - 1 and G.fx.get_child_count() > 0

func _selftest_fort() -> bool:
    var FortScript = load("res://game/entities/fortification.gd")
    var f = FortScript.new()
    G.world.add_child(f)
    f.init("sandbag", Vector3(0, 0, 18), 0.0, G.TEAM_ATTACK)
    var ok = f.hp > 0.0 and f.collision_layer == G.L_FORT
    f.take_damage(20.0)
    ok = ok and f.hp < f.max_hp
    f.queue_free()
    return ok

func _selftest_bomb() -> bool:
    var m = G.match_mgr
    var saved_state = m.state
    m.state = "LIVE"
    m.plant_bomb(G.player, G.world.sites[0])
    var ok = m.bomb_planted and is_instance_valid(m.bomb_node)
    m.defuse_bomb(G.player)
    ok = ok and not m.bomb_planted
    m.state = saved_state
    m.pending_end = -1
    m.progress.clear()
    return ok

func _selftest_finish() -> void:
    selftest_done = true
    print("SELFTEST: %s - %d erros | %d combatentes | %d objectivos | glTF | balistica | fortificacao | carga" % [
        "PASS" if errors.is_empty() else "FAIL", errors.size(),
        G.match_mgr.all_soldiers().size(), G.world.sites.size()])
    for e in errors:
        print("  erro: ", e)
    if errors.is_empty():
        print("SELFTEST_PASS")
    else:
        print("SELFTEST_FAIL")
    get_tree().quit(0 if errors.is_empty() else 1)
