extends CharacterBody3D
## Base comum: corpo glTF rigado, animacoes, zonas de dano, colete/capacete.

var team = 0
var alive = true
var health = 100.0
var armor = 0.0
var has_helmet = false
var display_name = "OPERADOR"
var kills = 0
var deaths = 0
var is_player = false
var weapon_key = "m4a1"
var last_attacker: Node = null
var speed_anim = 0.0
var crouched = false
var model_root: Node3D
var anim: AnimationPlayer
var skeleton: Skeleton3D
var clip_idle = "Idle"
var clip_walk = "Walk"
var clip_run = "Run"
var current_clip = ""
var death_t = 0.0
var voice_t = 0.0

func setup(p_team: int, p_name: String, p_weapon: String, p_is_player: bool = false) -> void:
    team = p_team
    display_name = p_name
    weapon_key = p_weapon
    is_player = p_is_player

func _ready() -> void:
    collision_layer = G.L_CHARACTER
    collision_mask = G.L_WORLD | G.L_FORT | G.L_PROP
    floor_snap_length = 0.35
    floor_max_angle = deg_to_rad(48.0)
    var cs = CollisionShape3D.new()
    cs.name = "BodyShape"
    var cap = CapsuleShape3D.new()
    cap.radius = 0.36
    cap.height = 1.78
    cs.shape = cap
    cs.position = Vector3(0, 0.89, 0)
    add_child(cs)
    _build_body()

func _build_body() -> void:
    model_root = Node3D.new()
    model_root.name = "Body"
    add_child(model_root)
    var m = G.models.soldier_model()
    if m == null:
        return
    model_root.add_child(m)
    var tint = Color(0.86, 0.90, 0.76) if team == G.TEAM_ATTACK else Color(0.70, 0.78, 0.92)
    if is_player:
        tint = Color(0.90, 0.92, 0.82)
    G.models.tint_model(m, tint)
    _add_gear(tint)
    skeleton = _find_skeleton(m)
    anim = _find_anim(m)
    if anim != null:
        for a in anim.get_animation_list():
            var low = a.to_lower()
            if low.contains("idle"):
                clip_idle = a
            elif low.contains("walk"):
                clip_walk = a
            elif low.contains("run"):
                clip_run = a
        anim.play(clip_idle, 0.15)


func _add_gear(tint: Color) -> void:
    var vest = G.materials.flat(Color(0.17, 0.19, 0.15), 0.92, 0.05)
    var pouch = G.materials.get_mat("fabric", tint.darkened(0.35), 1.0)
    var dark = G.materials.flat(Color(0.10, 0.11, 0.10), 0.85, 0.10)
    var metal = G.materials.flat(Color(0.16, 0.17, 0.17), 0.55, 0.65)
    # capacete balístico
    G.models.box(model_root, Vector3(0.36, 0.20, 0.34), Vector3(0, 1.71, 0), vest)
    G.models.box(model_root, Vector3(0.40, 0.045, 0.37), Vector3(0, 1.62, 0), dark)
    G.models.box(model_root, Vector3(0.30, 0.045, 0.05), Vector3(0, 1.66, -0.18), metal)
    # colete / placas
    G.models.box(model_root, Vector3(0.48, 0.44, 0.30), Vector3(0, 1.28, 0.01), vest)
    G.models.box(model_root, Vector3(0.40, 0.30, 0.05), Vector3(0, 1.30, -0.16), dark)
    G.models.box(model_root, Vector3(0.42, 0.14, 0.06), Vector3(0, 1.06, -0.16), pouch)
    for i in range(3):
        G.models.box(model_root, Vector3(0.11, 0.11, 0.07),
            Vector3(-0.15 + i * 0.15, 1.08, -0.20), pouch)
    # mochila / rádio
    G.models.box(model_root, Vector3(0.36, 0.42, 0.20), Vector3(0, 1.28, 0.24), pouch)
    G.models.box(model_root, Vector3(0.07, 0.22, 0.05), Vector3(0.24, 1.42, 0.24), dark)
    # ombreiras
    for sx in [-1.0, 1.0]:
        G.models.box(model_root, Vector3(0.16, 0.12, 0.26),
            Vector3(sx * 0.31, 1.48, 0), vest, Vector3(0, 0, sx * 0.25))
    # luvas e joelheiras
    for sx in [-1.0, 1.0]:
        G.models.box(model_root, Vector3(0.14, 0.12, 0.16),
            Vector3(sx * 0.32, 1.08, -0.06), dark)
        G.models.box(model_root, Vector3(0.18, 0.14, 0.12),
            Vector3(sx * 0.13, 0.50, -0.10), dark)
    # cinto
    G.models.box(model_root, Vector3(0.44, 0.07, 0.30), Vector3(0, 0.98, 0), dark)

func _find_skeleton(n: Node) -> Skeleton3D:
    if n is Skeleton3D:
        return n
    for c in n.get_children():
        var r = _find_skeleton(c)
        if r != null:
            return r
    return null

func _find_anim(n: Node) -> AnimationPlayer:
    if n is AnimationPlayer:
        return n
    for c in n.get_children():
        var r = _find_anim(c)
        if r != null:
            return r
    return null

func _attach_helmet(_m: Node3D) -> void:
    if has_helmet:
        return
    G.models.box(model_root, Vector3(0.10, 0.07, 0.18), Vector3(0, 1.74, -0.16),
        G.materials.flat(Color(0.12, 0.13, 0.13), 0.6, 0.55))
    has_helmet = true

func think(_delta: float) -> void:
    pass

func _physics_process(delta: float) -> void:
    if not alive:
        death_t += delta
        if death_t > 12.0:
            queue_free()
        return
    think(delta)
    if not is_on_floor():
        velocity.y -= G.tuning.gravity * delta
    move_and_slide()
    speed_anim = Vector2(velocity.x, velocity.z).length()
    _update_animation(delta)
    voice_t -= delta

func _update_animation(_delta: float) -> void:
    if anim == null:
        return
    var want = clip_idle
    var rate = 1.0
    if crouched:
        want = clip_idle
    elif speed_anim > 4.9:
        want = clip_run
        rate = clampf(speed_anim / 6.4, 0.8, 1.25)
    elif speed_anim > 0.5:
        want = clip_walk
        rate = clampf(speed_anim / 4.3, 0.65, 1.2)
    if want != current_clip:
        current_clip = want
        anim.play(want, 0.18, rate)
    elif anim.is_playing():
        anim.speed_scale = rate

func hit_zone(world_pos: Vector3) -> String:
    var h = world_pos.y - global_position.y
    if h >= G.tuning.zone_head:
        return "head"
    if h < G.tuning.zone_legs:
        return "limb"
    if h > 1.22:
        return "chest"
    return "stomach"

func aim_point() -> Vector3:
    return global_position + Vector3(0, 1.35 if not crouched else 1.02, 0)

func head_point() -> Vector3:
    return global_position + Vector3(0, 1.65 if not crouched else 1.18, 0)

func apply_damage(amount: float, zone: String, attacker: Node, hit_pos: Vector3) -> void:
    if not alive:
        return
    var mult = 1.0
    match zone:
        "head": mult = G.tuning.dmg_head
        "chest": mult = G.tuning.dmg_chest
        "stomach": mult = G.tuning.dmg_stomach
        _: mult = G.tuning.dmg_limb
    var dmg = amount * mult
    if (zone == "chest" or zone == "stomach" or zone == "head") and armor > 0.0:
        dmg *= G.tuning.armor_torso
        armor = maxf(0.0, armor - dmg * 0.75)
    if zone == "head" and has_helmet:
        dmg *= 0.42
        has_helmet = false
    health -= dmg
    last_attacker = attacker
    G.fx.blood(hit_pos)
    G.fx.impact(hit_pos, Vector3.UP, "body")
    if attacker != null and attacker.is_player:
        G.hud.hitmarker(zone == "head", health <= 0.0)
        G.audio.play("hit", -6.0)
    if not is_player and voice_t <= 0.0 and randf() < 0.35:
        voice_t = 1.2
        G.audio.play_at("radio", global_position, -14.0, G.rng_range(0.9, 1.15))
    if health <= 0.0:
        die(attacker, zone == "head")
    elif not is_player and attacker != null and G.match_mgr != null:
        G.match_mgr.on_damage(self, attacker)

func die(killer: Node, headshot: bool = false) -> void:
    if not alive:
        return
    alive = false
    health = 0.0
    deaths += 1
    collision_layer = 0
    collision_mask = 0
    velocity = Vector3.ZERO
    if anim != null:
        anim.stop()
    if model_root != null:
        var tw = create_tween()
        tw.tween_property(model_root, "rotation:x", -PI * 0.5, 0.35)
        tw.parallel().tween_property(model_root, "position:y", 0.28, 0.35)
    G.fx.blood(aim_point())
    G.audio.play_at("impact", global_position, -6.0)
    if G.match_mgr != null:
        G.match_mgr.on_kill(killer, self, headshot)
    if is_player and G.hud != null:
        G.hud.on_player_death(killer)

func give_armor(value: float) -> void:
    armor = clampf(armor + value, 0.0, 100.0)
    if armor >= 50.0 and not has_helmet and model_root != null:
        _attach_helmet(model_root)

func reset_for_round(pos: Vector3) -> void:
    alive = true
    health = 100.0
    deaths = 0
    velocity = Vector3.ZERO
    collision_layer = G.L_CHARACTER
    collision_mask = G.L_WORLD | G.L_FORT | G.L_PROP
    global_position = pos
    if model_root != null:
        model_root.rotation = Vector3.ZERO
        model_root.position = Vector3.ZERO
    current_clip = ""
    death_t = 0.0
