extends Node3D
## Arma: cadencia, carregador, recuo, dispersao e balistica com queda e penetracao.

var owner_node: Node3D
var key = "m4a1"
var data: Dictionary = {}
var mag = 30
var reserve = 120
var cooldown = 0.0
var reloading = false
var reload_t = 0.0
var reload_total = 2.3
var bolt_t = 0.0
var spread_heat = 0.0
var shots_fired = 0
var viewmodel: Node3D
var muzzle: Node3D
var is_ai = false
var view_anim: AnimationPlayer
var clip_idle = ""
var clip_fire = ""
var clip_reload = ""

func setup(p_owner: Node3D, p_key: String) -> void:
    owner_node = p_owner
    key = p_key
    data = G.weapons.get(p_key, G.weapons.m4a1).duplicate()
    mag = data.mag
    reserve = data.reserve
    is_ai = not p_owner.is_player
    _build_view()

func _build_view() -> void:
    var model = G.models.weapon_model(data.model)
    if is_ai:
        var holder = Node3D.new()
        holder.scale = Vector3(0.85, 0.85, 0.85)
        holder.add_child(model)
        holder.position = Vector3(0.28, 1.22, -0.15)
        holder.rotation.y = PI
        if owner_node.has_node("Body"):
            owner_node.get_node("Body").add_child(holder)
        else:
            owner_node.add_child(holder)
    else:
        viewmodel = Node3D.new()
        viewmodel.name = "ViewModel"
        viewmodel.add_child(model)
        var cam: Camera3D = owner_node.camera
        cam.add_child(viewmodel)
        viewmodel.position = Vector3(0.20, -0.19, -0.42)
        if model.has_meta("from_glb") and bool(model.get_meta("from_glb")):
            viewmodel.position = Vector3(0.16, -0.21, -0.26)
            _setup_view_anim(model)
        muzzle = Node3D.new()
        muzzle.position = Vector3(0.0, 0.01, -0.58)
        viewmodel.add_child(muzzle)

func _find_anim(n: Node) -> AnimationPlayer:
    if n is AnimationPlayer:
        return n
    for c in n.get_children():
        var r = _find_anim(c)
        if r != null:
            return r
    return null

func _setup_view_anim(model: Node3D) -> void:
    view_anim = _find_anim(model)
    if view_anim == null:
        return
    for a in view_anim.get_animation_list():
        var low = a.to_lower()
        if low.contains("idle"):
            clip_idle = a
        elif low.contains("shoot") or low.contains("fire"):
            clip_fire = a
        elif low.contains("reload"):
            clip_reload = a
    if clip_idle != "":
        var res = view_anim.get_animation(clip_idle)
        if res != null:
            res.loop_mode = Animation.LOOP_LINEAR
        view_anim.play(clip_idle, 0.2)
        G.note("arma: animacoes de viewmodel " + str(view_anim.get_animation_list()))

func _play_view(kind: String) -> void:
    if view_anim == null:
        return
    var clip = ""
    if kind == "fire":
        clip = clip_fire
    elif kind == "reload":
        clip = clip_reload
    if clip != "":
        view_anim.play(clip, 0.03, 1.0)

func mag_capacity() -> int:
    return int(data.mag)

func refill() -> void:
    mag = int(data.mag)
    reserve = int(data.reserve)
    reloading = false
    reload_t = 0.0
    bolt_t = 0.0
    cooldown = 0.0
    spread_heat = 0.0

func start_reload() -> bool:
    if reloading or mag >= int(data.mag) or reserve <= 0:
        return false
    reloading = true
    reload_total = float(data.reload)
    reload_t = 0.0
    _play_view("reload")
    if is_ai:
        G.audio.play_at("reload", owner_node.global_position + Vector3(0, 1.4, 0), -16.0)
    else:
        G.audio.play("reload", -9.0)
    return true

func _complete_reload() -> void:
    var need = int(data.mag) - mag
    var take = int(min(need, reserve))
    mag += take
    reserve -= take
    reloading = false
    reload_t = 0.0
    if data.has("bolt"):
        bolt_t = 0.85

func current_spread_deg(aiming: bool, moving: float, crouching: bool, airborne: bool) -> float:
    var s: float = float(data.spread)
    s += float(data.move_spread) * clampf(moving / 6.0, 0.0, 1.0) * 0.85
    s += spread_heat * 0.42
    if aiming:
        s *= float(data.ads_spread)
    if crouching:
        s *= 0.62
    if airborne:
        s *= 2.3
    return s

func add_ai_spread(dir: Vector3, deg: float) -> Vector3:
    if deg <= 0.0:
        return dir
    var rad = deg_to_rad(deg)
    var right = dir.cross(Vector3.UP).normalized()
    var up = right.cross(dir).normalized()
    return (dir + right * G.rng_range(-rad, rad) + up * G.rng_range(-rad, rad)).normalized()

func can_fire() -> bool:
    return owner_node != null and is_instance_valid(owner_node) and owner_node.alive \
        and not reloading and bolt_t <= 0.0 and cooldown <= 0.0 and mag > 0

func fire(origin: Vector3, base_dir: Vector3, spread_deg: float, aiming: bool) -> bool:
    if not can_fire():
        if mag <= 0 and not reloading and owner_node.is_player:
            G.audio.play("empty", -8.0)
            if reserve > 0:
                start_reload()
        return false
    mag -= 1
    shots_fired += 1
    cooldown = 60.0 / float(data.rpm)
    spread_heat = minf(spread_heat + 1.0, 8.0)
    var dir = add_ai_spread(base_dir, maxf(spread_deg, 0.0))
    var muzzle_pos = origin
    if muzzle != null:
        muzzle_pos = muzzle.global_position
    G.fx.muzzle(muzzle_pos, dir)
    G.fx.shell(muzzle_pos + Vector3(0.05, -0.06, 0.05))
    _play_view("fire")
    if owner_node.is_player:
        G.audio.play(data.sound, -3.0, G.rng_range(0.97, 1.03))
        owner_node.add_recoil(float(data.recoil), aiming)
        G.hud.crosshair_kick()
    else:
        G.audio.play_at(data.sound, origin, -4.0, G.rng_range(0.96, 1.04))
        if G.match_mgr != null:
            G.match_mgr.report_gunshot(owner_node, origin)
    if data.has("bolt"):
        bolt_t = 60.0 / float(data.rpm)
    if mag <= 0 and reserve > 0:
        start_reload()
    _trace(origin, dir)
    return true

func _trace(origin: Vector3, dir: Vector3) -> void:
    var space = owner_node.get_world_3d().direct_space_state
    var speed: float = float(data.muzzle)
    var step = 2.0
    var dt = step / speed
    var pos = origin
    var vel = dir * speed
    var damage: float = float(data.damage)
    var pen: float = float(data.penetration)
    var penetrations = 0
    var traveled = 0.0
    var end = origin + dir * 140.0
    var exclude = []
    if owner_node is CollisionObject3D:
        exclude.append(owner_node.get_rid())
    for i in range(90):
        var next = pos + vel * dt
        var q = PhysicsRayQueryParameters3D.create(pos, next)
        q.collision_mask = G.L_WORLD | G.L_CHARACTER | G.L_FORT | G.L_PROP
        q.exclude = exclude
        var hit = space.intersect_ray(q)
        vel += Vector3(0, -9.81, 0) * dt
        if hit.is_empty():
            traveled += pos.distance_to(next)
            pos = next
            continue
        var point: Vector3 = hit.position
        var normal: Vector3 = hit.normal
        var col: Object = hit.collider
        end = point
        traveled += pos.distance_to(point)
        var falloff = clampf(1.0 - traveled / 320.0, 0.52, 1.0)
        var dealt = damage * falloff
        if col != null and ("apply_damage" in col) and col != owner_node:
            if col.team == owner_node.team and not G.match_mgr.friendly_fire:
                G.fx.impact(point, normal, "body")
                break
            var zone: String = col.hit_zone(point)
            col.apply_damage(dealt, zone, owner_node, point)
            G.fx.impact(point, normal, "body")
            break
        if col != null and ("take_damage" in col):
            col.take_damage(dealt * 0.8)
            G.fx.impact(point, normal, "wood")
            G.audio.play_at("impact", point, -14.0)
            if penetrations < 2 and pen > 0.2 and dealt * pen > 6.0:
                penetrations += 1
                damage *= pen
                pos = point + dir * 0.08
                continue
            break
        var kind = "concrete"
        if col != null and col.has_meta("surface"):
            kind = str(col.get_meta("surface"))
        G.fx.impact(point, normal, kind)
        if randf() < 0.35:
            G.audio.play_at("ricochet", point, -18.0)
        break
    G.fx.tracer(muzzle_pos_for_tracer(origin), end)

func muzzle_pos_for_tracer(origin: Vector3) -> Vector3:
    if muzzle != null:
        return muzzle.global_position
    return origin

func _process(delta: float) -> void:
    if cooldown > 0.0:
        cooldown -= delta
    if bolt_t > 0.0:
        bolt_t -= delta
    if reloading:
        reload_t += delta
        if reload_t >= reload_total:
            _complete_reload()
    spread_heat = maxf(0.0, spread_heat - delta * 3.6)
    if view_anim != null and clip_idle != "" and not view_anim.is_playing():
        view_anim.play(clip_idle, 0.2)
    if viewmodel != null:
        _animate_view(delta)

func _animate_view(delta: float) -> void:
    var p = owner_node
    var aiming = false
    if "aiming" in p:
        aiming = bool(p.aiming)
    var target = Vector3(0.20, -0.19, -0.42)
    if aiming:
        target = Vector3(0.0, -0.115, -0.30)
    var bob = 0.0
    if p.has_method("get_bob"):
        bob = float(p.get_bob())
    target.y += bob * 0.012
    target.x += sin(bob * 0.5) * 0.008
    var recoil = Vector2.ZERO
    if p.has_method("get_recoil_offset"):
        recoil = p.get_recoil_offset()
    target += Vector3(recoil.x * 0.02, recoil.y * 0.02, recoil.y * 0.05)
    if reloading:
        var f = clampf(reload_t / maxf(reload_total, 0.01), 0.0, 1.0)
        target += Vector3(sin(f * PI) * 0.06, -sin(f * PI) * 0.16, sin(f * PI) * 0.08)
        viewmodel.rotation.x = -sin(f * PI) * 0.7
    else:
        viewmodel.rotation.x = lerpf(viewmodel.rotation.x, recoil.y * 0.02, clampf(delta * 8.0, 0.0, 1.0))
    viewmodel.position = viewmodel.position.lerp(target, clampf(delta * 10.0, 0.0, 1.0))
