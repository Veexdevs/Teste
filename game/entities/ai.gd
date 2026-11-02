extends "res://game/entities/soldier.gd"
## IA: percepcao com linha de visao, avanco/contacto/cobertura/investigacao,
## rajadas, cobertura e accao no objectivo.

const WeaponScript = preload("res://game/entities/weapon.gd")

var weapon: Node
var state = "advance"
var target_enemy: Node = null
var last_seen_pos = Vector3.ZERO
var last_seen_t = 0.0
var waypoint = Vector3.ZERO
var objective = Vector3.ZERO
var think_t = 0.0
var burst_t = 0.0
var burst_left = 0
var strafe_dir = 1.0
var strafe_t = 0.0
var cover_t = 0.0
var accuracy = 0.82
var reaction = 0.28
var has_charge = false
var patrol_points: Array = []
var patrol_i = 0

func setup_ai(difficulty: float) -> void:
    accuracy = clampf(difficulty, 0.25, 0.98)
    reaction = lerpf(0.75, 0.16, difficulty)

func _ready() -> void:
    super._ready()
    weapon = WeaponScript.new()
    add_child(weapon)
    weapon.setup(self, weapon_key)
    think_t = randf() * 0.3
    strafe_dir = 1.0 if randf() > 0.5 else -1.0

func set_objective(p: Vector3, charge: bool) -> void:
    objective = p
    has_charge = charge
    waypoint = p
    patrol_points = [p + Vector3(G.rng_range(-5, 5), 0, G.rng_range(-5, 5)),
                     p + Vector3(G.rng_range(-9, 9), 0, G.rng_range(-9, 9)),
                     p + Vector3(G.rng_range(-12, 12), 0, G.rng_range(-12, 12))]

func notice(nodes: Array) -> void:
    if target_enemy != null and is_instance_valid(target_enemy) and target_enemy.alive:
        return
    for n in nodes:
        var p: Vector3 = n.pos
        if p.distance_to(global_position) < 26.0 and n.team != team:
            last_seen_pos = p
            last_seen_t = 4.0
            if state == "advance" or state == "hold" or state == "patrol":
                state = "investigate"
                waypoint = p

func _perceive() -> void:
    var best: Node = null
    var best_d = INF
    var origin = global_position + Vector3(0, 1.55, 0)
    var space = get_world_3d().direct_space_state
    var excl = [get_rid()]
    for s in G.match_mgr.all_soldiers():
        if s == self or not is_instance_valid(s) or not s.alive or s.team == team:
            continue
        var d = global_position.distance_to(s.global_position)
        if d > 72.0 or d > best_d:
            continue
        var dir = (s.aim_point() - origin).normalized()
        var facing = -global_transform.basis.z
        if facing.dot(dir) < -0.35 and d > 8.0:
            continue
        var q = PhysicsRayQueryParameters3D.create(origin, s.aim_point())
        q.collision_mask = G.L_WORLD | G.L_FORT | G.L_CHARACTER | G.L_PROP
        q.exclude = excl
        var hit = space.intersect_ray(q)
        if hit.is_empty():
            continue
        var col = hit.collider
        if col == s or (col != null and "apply_damage" in col and col.team == s.team):
            best = s
            best_d = d
    if best != null:
        target_enemy = best
        last_seen_pos = best.global_position
        last_seen_t = 4.0
        if state != "engage" and state != "cover":
            state = "engage"
            burst_t = reaction
    elif target_enemy != null:
        last_seen_t -= think_t
        if last_seen_t <= 0.0:
            target_enemy = null
            if state == "engage":
                state = "investigate"
                waypoint = last_seen_pos

func think(delta: float) -> void:
    if G.match_mgr == null:
        return
    think_t -= delta
    if think_t <= 0.0:
        think_t = 0.16 + randf() * 0.10
        _perceive()
        _decide()
    last_seen_t = maxf(0.0, last_seen_t - delta)
    cover_t = maxf(0.0, cover_t - delta)
    strafe_t -= delta
    if strafe_t <= 0.0:
        strafe_t = G.rng_range(0.8, 2.2)
        strafe_dir *= -1.0
    if burst_t > 0.0:
        burst_t -= delta
    match state:
        "advance":
            _steer(objective, delta, G.tuning.walk_speed * 0.92)
            if global_position.distance_to(objective) < 3.0 and has_charge:
                state = "plant"
        "patrol", "hold":
            if patrol_points.is_empty():
                _steer(objective, delta, 1.8)
            else:
                var p: Vector3 = patrol_points[patrol_i % patrol_points.size()]
                _steer(p, delta, 2.1)
                if global_position.distance_to(p) < 2.0:
                    patrol_i += 1
        "investigate":
            _steer(last_seen_pos, delta, G.tuning.walk_speed * 0.85)
            if global_position.distance_to(last_seen_pos) < 2.5:
                state = "hold"
        "engage":
            _combat(delta)
        "cover":
            _steer(waypoint, delta, G.tuning.sprint_speed * 0.85)
            if global_position.distance_to(waypoint) < 1.5 or cover_t <= 0.0:
                state = "engage" if target_enemy != null else "advance"
        "plant", "defuse":
            velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
            velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
            G.match_mgr.ai_interact(self, true, delta)
    if state == "hold" or state == "patrol":
        G.match_mgr.ai_interact(self, false, delta)

func _decide() -> void:
    if G.match_mgr.bomb_planted and target_enemy == null:
        if team == G.TEAM_DEFEND and global_position.distance_to(G.match_mgr.bomb_pos) < 10.0:
            state = "defuse"
            waypoint = G.match_mgr.bomb_pos
            return
        if team == G.TEAM_ATTACK:
            state = "hold"
            waypoint = G.match_mgr.bomb_pos + Vector3(G.rng_range(-5, 5), 0, G.rng_range(-5, 5))
            return
    if target_enemy == null:
        if state == "engage" or state == "cover" or state == "defuse":
            state = "advance" if team == G.TEAM_ATTACK else "hold"
        return
    if health < 42.0 and cover_t <= 0.0 and randf() < 0.55:
        state = "cover"
        waypoint = G.world.nearest_cover(global_position, target_enemy.global_position)
        cover_t = 3.2
        return
    if state == "cover" and cover_t <= 0.0:
        state = "engage"

func _combat(delta: float) -> void:
    if target_enemy == null or not is_instance_valid(target_enemy) or not target_enemy.alive:
        target_enemy = null
        state = "advance" if team == G.TEAM_ATTACK else "hold"
        return
    var epos: Vector3 = target_enemy.global_position
    var d = global_position.distance_to(epos)
    var to = epos - global_position
    to.y = 0.0
    var dir = to.normalized()
    _face(dir, delta, 8.0)
    var wish = Vector3.ZERO
    if d > 26.0:
        wish = dir
    elif d < 5.0:
        wish = -dir * 0.7
    else:
        wish = Vector3(-dir.z, 0, dir.x) * strafe_dir * 0.7
    _steer(global_position + wish * 3.0, delta, G.tuning.walk_speed * 0.72)
    if burst_left <= 0 and burst_t <= 0.0:
        burst_left = int(G.rng_range(2, 5))
        burst_t = G.rng_range(0.35, 0.9)
    if burst_left > 0 and burst_t <= 0.0:
        var origin = global_position + Vector3(0, 1.48 if not crouched else 1.05, 0)
        var aim = target_enemy.aim_point() + Vector3(0, G.rng_range(-0.12, 0.16), 0)
        var sdir = (aim - origin).normalized()
        var base_spread = lerpf(7.0, 1.1, accuracy) + clampf(d * 0.045, 0.0, 4.0)
        if weapon != null:
            weapon.fire(origin, sdir, base_spread, false)
        burst_left -= 1
        burst_t = 60.0 / float(weapon.data.rpm) + G.rng_range(0.02, 0.11)
    if weapon != null and weapon.mag <= 0 and weapon.reserve > 0 and not weapon.reloading:
        weapon.start_reload()

func _face(dir: Vector3, delta: float, rate: float) -> void:
    if dir.length() < 0.001:
        return
    var want = atan2(-dir.x, -dir.z)
    rotation.y = lerp_angle(rotation.y, want, clampf(delta * rate, 0.0, 1.0))

func _steer(target: Vector3, delta: float, speed: float) -> void:
    var to = target - global_position
    to.y = 0.0
    var dist = to.length()
    if dist < 0.55:
        velocity.x = move_toward(velocity.x, 0.0, 9.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 9.0 * delta)
        return
    var dir = to / dist
    var avoid = Vector3.ZERO
    var space = get_world_3d().direct_space_state
    var origin = global_position + Vector3(0, 0.85, 0)
    for a in [0.0, 0.55, -0.55]:
        var rd = dir.rotated(Vector3.UP, a)
        var q = PhysicsRayQueryParameters3D.create(origin, origin + rd * 1.9)
        q.collision_mask = G.L_WORLD | G.L_FORT
        q.exclude = [get_rid()]
        var hit = space.intersect_ray(q)
        if not hit.is_empty():
            avoid -= rd * (1.9 - origin.distance_to(hit.position)) / 1.9
    dir = (dir + avoid * 1.35).normalized()
    _face(dir, delta, 5.0)
    var accel = 18.0 if is_on_floor() else 3.0
    velocity.x = move_toward(velocity.x, dir.x * speed, accel * delta)
    velocity.z = move_toward(velocity.z, dir.z * speed, accel * delta)

func reset_for_round(pos: Vector3) -> void:
    super.reset_for_round(pos)
    state = "advance" if team == G.TEAM_ATTACK else "hold"
    target_enemy = null
    burst_left = 0
    burst_t = reaction
    cover_t = 0.0
    last_seen_t = 0.0
    if weapon != null:
        weapon.refill()
