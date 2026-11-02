extends Node
## Rondas estilo CS: compra -> accao -> resultado, economia, carga/desactivacao.

const PlayerScript = preload("res://game/entities/player.gd")
const AiScript = preload("res://game/entities/ai.gd")

var state = "MENU"
var round_no = 0
var score = [0, 0]
var round_left = 0.0
var phase_left = 0.0
var bomb_planted = false
var bomb_timer = 0.0
var bomb_site: Dictionary = {}
var bomb_node: Node3D
var bomb_pos = Vector3.ZERO
var beep_t = 0.0
var beep_fast = 0.0
var difficulty = 0.65
var friendly_fire = false
var money = 800
var soldiers: Array = []
var attackers: Array = []
var defenders: Array = []
var built_forts: Array = []
var noises: Array = []
var kill_feed: Array = []
var progress = {}
var pending_end = -1
var pending_reason = ""
var match_over = false
var last_reason = ""
var player: Node
var carrier: Node

func start(p_difficulty: float = 0.65) -> void:
    difficulty = clampf(p_difficulty, 0.25, 0.95)
    score = [0, 0]
    round_no = 0
    money = int(G.tuning.start_money)
    match_over = false
    _create_teams()
    start_round()
    G.note("partida iniciada: dificuldade %.2f, %d combatentes" % [difficulty, soldiers.size()])

func reset() -> void:
    for s in soldiers:
        if is_instance_valid(s):
            s.queue_free()
    soldiers.clear()
    attackers.clear()
    defenders.clear()
    player = null
    carrier = null
    G.player = null
    _clear_forts()
    if is_instance_valid(bomb_node):
        bomb_node.queue_free()
        bomb_node = null
    bomb_planted = false
    bomb_site = {}
    state = "MENU"
    round_no = 0
    score = [0, 0]
    money = int(G.tuning.start_money)
    kill_feed.clear()
    noises.clear()
    progress.clear()
    pending_end = -1
    match_over = false

func _create_teams() -> void:
    var p = PlayerScript.new()
    p.setup(G.TEAM_ATTACK, "TU / LIDER", "m4a1", true)
    p.setup_player("m4a1")
    G.world.add_child(p)
    player = p
    G.player = p
    soldiers.append(p)
    attackers.append(p)
    var atk_names = ["CABO REIS", "SARGENTO MATOS", "SOLDADO VIANA"]
    var atk_weapons = ["ak47", "mp5", "m4a1"]
    for i in range(3):
        var a = AiScript.new()
        a.setup(G.TEAM_ATTACK, atk_names[i], atk_weapons[i], false)
        a.setup_ai(difficulty)
        G.world.add_child(a)
        soldiers.append(a)
        attackers.append(a)
    var def_names = ["SENTINELA 01", "SENTINELA 02", "SENTINELA 03", "SENTINELA 04", "SENTINELA 05"]
    var def_weapons = ["ak47", "m4a1", "mp5", "sniper", "ak47"]
    for i in range(5):
        var a = AiScript.new()
        a.setup(G.TEAM_DEFEND, def_names[i], def_weapons[i], false)
        a.setup_ai(difficulty)
        G.world.add_child(a)
        soldiers.append(a)
        defenders.append(a)
    carrier = attackers[1]

func all_soldiers() -> Array:
    var out = []
    for s in soldiers:
        if is_instance_valid(s):
            out.append(s)
    return out

func alive_count(team: int) -> int:
    var n = 0
    for s in all_soldiers():
        if s.team == team and s.alive:
            n += 1
    return n

func start_round() -> void:
    round_no += 1
    state = "BUY"
    phase_left = G.tuning.buy_time
    round_left = G.tuning.round_time
    bomb_planted = false
    bomb_timer = 0.0
    bomb_site = {}
    pending_end = -1
    noises.clear()
    progress.clear()
    kill_feed.clear()
    _clear_forts()
    if is_instance_valid(bomb_node):
        bomb_node.queue_free()
        bomb_node = null
    var sites = G.world.sites
    var target_site: Dictionary = sites[round_no % sites.size()]
    var atk_spawns: Array = G.world.spawns[G.TEAM_ATTACK]
    var def_spawns: Array = G.world.spawns[G.TEAM_DEFEND]
    for i in range(soldiers.size()):
        var s = soldiers[i]
        if not is_instance_valid(s):
            continue
        var pos: Vector3
        if s.team == G.TEAM_ATTACK:
            pos = atk_spawns[i % atk_spawns.size()]
        else:
            pos = def_spawns[(i - attackers.size()) % def_spawns.size()]
        s.reset_for_round(pos)
        if s.is_player:
            continue
        if s.team == G.TEAM_ATTACK:
            s.set_objective(target_site.pos, s == carrier)
        else:
            var site: Dictionary = sites[i % sites.size()]
            s.set_objective(site.pos + Vector3(G.rng_range(-4, 4), 0, G.rng_range(-4, 4)), false)
            s.state = "hold"
    if player != null and player.build_sys != null:
        player.build_sys.charges = {"sandbag": 1, "hesco": 0, "wire": 1, "shield": 0}
        player.build_sys.selected = "sandbag"
    G.controls.enabled = false
    G.controls.set_capture(false)
    G.hud.show_buy(true)
    G.hud.banner("RONDA %d - FASE DE PLANEAMENTO" % round_no, "Escolhe equipamento e fortificacoes", 2.6)
    G.audio.play("radio", -8.0)

func begin_live() -> void:
    if state != "BUY":
        return
    state = "LIVE"
    G.controls.enabled = true
    G.controls.set_capture(true)
    G.hud.show_buy(false)
    G.hud.banner("RONDA %d - INICIO" % round_no, "ASSALTO: plantar carga em A ou B | DEFESA: impedir", 2.2)
    G.audio.play("beep", -6.0)

func end_round(winner: int, reason: String) -> void:
    if state != "LIVE":
        return
    state = "ROUND_END"
    phase_left = 5.0
    last_reason = reason
    score[winner] += 1
    money += 3250 if winner == G.TEAM_ATTACK else 1400
    G.audio.play("radio", -5.0)
    G.controls.enabled = false
    G.controls.set_capture(false)
    G.hud.banner("ASSALTO VENCE" if winner == G.TEAM_ATTACK else "DEFESA VENCE", reason, 4.6)
    if score[winner] >= int(G.tuning.rounds_to_win):
        match_over = true

func _process(delta: float) -> void:
    if state == "MENU" or state == "MATCH_END":
        return
    for i in range(noises.size() - 1, -1, -1):
        noises[i].t += delta
        if noises[i].t > 4.0:
            noises.remove_at(i)
    if pending_end >= 0 and state == "LIVE":
        var w = pending_end
        var r = pending_reason
        pending_end = -1
        end_round(w, r)
        return
    match state:
        "BUY":
            phase_left -= delta
            if phase_left <= 0.0:
                begin_live()
        "LIVE":
            if bomb_planted:
                bomb_timer -= delta
                beep_t -= delta
                if beep_t <= 0.0:
                    beep_fast = clampf(1.0 - bomb_timer / G.tuning.bomb_time, 0.0, 1.0)
                    beep_t = lerpf(1.0, 0.13, beep_fast)
                    G.audio.play("beep", -10.0 + beep_fast * 6.0, 1.0 + beep_fast * 0.5)
                if bomb_node != null and is_instance_valid(bomb_node):
                    var l = bomb_node.get_node_or_null("Beacon") as OmniLight3D
                    if l != null:
                        l.light_energy = 0.6 + 3.4 * absf(sin(bomb_timer * lerpf(5.0, 18.0, beep_fast)))
                if bomb_timer <= 0.0:
                    _detonate()
            else:
                round_left -= delta
                if round_left <= 0.0:
                    end_round(G.TEAM_DEFEND, "TEMPO ESGOTADO - CARGA NAO PLANTADA")
        "ROUND_END":
            phase_left -= delta
            if phase_left <= 0.0:
                if match_over:
                    state = "MATCH_END"
                    G.hud.show_match_end(score)
                else:
                    start_round()

func _detonate() -> void:
    G.fx.explosion(bomb_pos)
    G.audio.play("boom", 2.0)
    for s in all_soldiers():
        if s.alive and s.global_position.distance_to(bomb_pos) < 12.0:
            s.apply_damage(160.0, "chest", null, s.aim_point())
    pending_end = G.TEAM_ATTACK
    pending_reason = "CARGA DETONADA"

func plant_bomb(actor: Node, site: Dictionary) -> void:
    if bomb_planted or state != "LIVE":
        return
    bomb_planted = true
    bomb_site = site
    bomb_timer = G.tuning.bomb_time
    bomb_pos = site.pos + Vector3(0, 0.1, 0)
    beep_t = 0.5
    var n = Node3D.new()
    n.position = bomb_pos
    var body = G.models.box(n, Vector3(0.42, 0.24, 0.32), Vector3(0, 0.16, 0),
        G.materials.flat(Color(0.20, 0.22, 0.18), 0.7, 0.3))
    body.name = "Charge"
    var led = G.models.box(n, Vector3(0.10, 0.04, 0.10), Vector3(0, 0.30, 0),
        G.materials.flat(Color(1.0, 0.15, 0.10), 0.3, 0.0, 2.5))
    led.name = "LED"
    var l = OmniLight3D.new()
    l.name = "Beacon"
    l.light_color = Color(1.0, 0.18, 0.10)
    l.light_energy = 2.0
    l.omni_range = 9.0
    l.position = Vector3(0, 0.5, 0)
    n.add_child(l)
    G.world.add_child(n)
    bomb_node = n
    G.audio.play_at("plant", bomb_pos, -2.0)
    G.hud.banner("CARGA PLANTADA - LOCAL " + str(site.name),
        "Defesa tem %.0f segundos para desactivar" % G.tuning.bomb_time, 3.0)
    G.audio.play("radio", -5.0)
    if actor == player:
        money += 300
    for a in all_soldiers():
        if not a.is_player and a.team == G.TEAM_DEFEND:
            a.set_objective(bomb_pos, false)
            a.state = "advance"

func defuse_bomb(actor: Node) -> void:
    if not bomb_planted:
        return
    bomb_planted = false
    if is_instance_valid(bomb_node):
        bomb_node.queue_free()
    G.audio.play_at("plant", bomb_pos, -4.0, 1.4)
    if actor == player:
        money += 300
    pending_end = G.TEAM_DEFEND
    pending_reason = "CARGA DESACTIVADA"

func _progress(actor: Node, key: String, amount: float, needed: float) -> float:
    var k = "%d_%s" % [actor.get_instance_id(), key]
    var v = float(progress.get(k, 0.0)) + amount
    progress[k] = v
    if v >= needed:
        progress[k] = 0.0
        return 1.0
    return v / needed

func _clear_progress(actor: Node, key: String) -> void:
    progress["%d_%s" % [actor.get_instance_id(), key]] = 0.0

func update_interact(actor: Node, holding: bool, delta: float) -> void:
    if state != "LIVE" or not actor.alive:
        G.hud.set_interact("", 0.0)
        return
    if bomb_planted:
        if actor.team == G.TEAM_DEFEND and actor.global_position.distance_to(bomb_pos) < 2.6:
            if holding:
                var f = _progress(actor, "defuse", delta, G.tuning.defuse_time)
                G.hud.set_interact("DESACTIVAR CARGA", f)
                if f >= 1.0:
                    defuse_bomb(actor)
            else:
                _clear_progress(actor, "defuse")
                G.hud.set_interact("MANTER [F] PARA DESACTIVAR", 0.0)
        else:
            G.hud.set_interact("", 0.0)
        return
    var site = G.world.site_at(actor.global_position)
    if actor.team == G.TEAM_ATTACK and not site.is_empty():
        if holding:
            var f = _progress(actor, "plant", delta, G.tuning.plant_time)
            G.hud.set_interact("PLANTAR CARGA - LOCAL " + str(site.name), f)
            if f >= 1.0:
                plant_bomb(actor, site)
        else:
            _clear_progress(actor, "plant")
            G.hud.set_interact("MANTER [F] PARA PLANTAR CARGA", 0.0)
    else:
        G.hud.set_interact("", 0.0)

func ai_interact(ai: Node, holding: bool, delta: float) -> void:
    if state != "LIVE" or not ai.alive:
        return
    var enemies_near = false
    for s in all_soldiers():
        if s.team != ai.team and s.alive and s.global_position.distance_to(ai.global_position) < 9.0:
            enemies_near = true
            break
    if bomb_planted:
        if ai.team == G.TEAM_DEFEND and ai.global_position.distance_to(bomb_pos) < 2.8 and not enemies_near:
            var f = _progress(ai, "defuse", delta * 0.85, G.tuning.defuse_time)
            ai.velocity.x = 0.0
            ai.velocity.z = 0.0
            if f >= 1.0:
                defuse_bomb(ai)
        return
    if ai.team == G.TEAM_ATTACK and ai.has_charge and not enemies_near:
        var site = G.world.site_at(ai.global_position)
        if not site.is_empty():
            var f = _progress(ai, "plant", delta * 0.9, G.tuning.plant_time)
            ai.velocity.x = 0.0
            ai.velocity.z = 0.0
            ai.state = "plant"
            if f >= 1.0:
                plant_bomb(ai, site)

func on_kill(killer: Node, victim: Node, headshot: bool) -> void:
    var kname = "---" if killer == null else killer.display_name
    kill_feed.append({"text": "%s  >  %s%s" % [kname, victim.display_name, "  [CABECA]" if headshot else ""], "t": 0.0})
    if kill_feed.size() > 6:
        kill_feed.pop_front()
    if killer != null and killer != victim:
        killer.kills += 1
        if killer == player:
            money += 300
            G.audio.play("hit", -4.0, 1.3)
    if state == "LIVE":
        if alive_count(G.TEAM_ATTACK) <= 0:
            pending_end = G.TEAM_DEFEND
            pending_reason = "ASSALTO ELIMINADO"
        elif alive_count(G.TEAM_DEFEND) <= 0:
            pending_end = G.TEAM_ATTACK
            pending_reason = "DEFESA ELIMINADA"

func on_damage(victim: Node, attacker: Node) -> void:
    if not victim.is_player and attacker != null and attacker != victim:
        victim.target_enemy = attacker
        victim.last_seen_pos = attacker.global_position
        victim.last_seen_t = 5.0
        victim.state = "engage"
        victim.burst_t = minf(victim.burst_t, victim.reaction)

func report_gunshot(shooter: Node, pos: Vector3) -> void:
    var n = {"pos": pos, "team": shooter.team, "t": 0.0}
    noises.append(n)
    for a in all_soldiers():
        if not a.is_player and a.team != shooter.team and a.alive:
            a.notice([n])

func report_noise(actor: Node, pos: Vector3, radius: float) -> void:
    var n = {"pos": pos, "team": actor.team, "t": 0.0}
    noises.append(n)
    for a in all_soldiers():
        if not a.is_player and a.team != actor.team and a.alive and a.global_position.distance_to(pos) < radius:
            a.notice([n])

func buy(key: String) -> void:
    if state != "BUY" or player == null:
        return
    var item = {}
    for i in G.buy_items:
        if i.key == key:
            item = i
            break
    if item.is_empty():
        return
    var price = int(item.price)
    if money < price:
        G.audio.play("ui", -8.0, 0.6)
        G.hud.flash("CREDITO INSUFICIENTE")
        return
    money -= price
    match item.kind:
        "primary": player.change_primary(key)
        "armor":
            player.give_armor(100.0)
            player.armor = 100.0
        "ammo":
            for w in player.weapons:
                w.refill()
        "charge":
            var n = 2 if (key != "hesco" and key != "shield") else 1
            player.build_sys.add_charges(key, n)
    G.audio.play("ui", -8.0, 1.2)
    G.hud.flash(str(item.label) + " ADQUIRIDO")

func _clear_forts() -> void:
    for f in built_forts:
        if is_instance_valid(f):
            f.queue_free()
    built_forts.clear()
    for c in G.world.get_children():
        if c is StaticBody3D and c.has_meta("fortification"):
            c.queue_free()

func register_fort(f) -> void:
    built_forts.append(f)

func force_start() -> void:
    if state == "BUY":
        phase_left = 0.01
