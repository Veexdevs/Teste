extends "res://game/entities/soldier.gd"
## Operador do jogador: locomocao, stamina, inclinacao, mira, recuo,
## troca de arma, fortificacoes, objectivo e modo espectador.

const WeaponScript = preload("res://game/entities/weapon.gd")
const BuildScript = preload("res://game/entities/build.gd")

var camera: Camera3D
var capsule: CapsuleShape3D
var weapons: Array = []
var weapon: Node
var active_slot = 0
var switch_t = 0.0
var stamina = 100.0
var aiming = false
var recoil = Vector2.ZERO
var bob = 0.0
var lean = 0.0
var pitch = 0.0
var fall_prev = 0.0
var step_dist = 0.0
var build_sys: Node
var money = 800
var spectate_t = 0.0
var spectate_idx = 0
var primary_key = "m4a1"
var camera_pivot: Node3D
var third_person = true

func setup_player(p_primary: String) -> void:
    primary_key = p_primary

func _ready() -> void:
    super._ready()
    is_player = true
    display_name = "TU / LIDER DE ASSALTO"
    weapon_key = primary_key
    camera_pivot = Node3D.new()
    camera_pivot.name = "CameraPivot"
    camera_pivot.position = Vector3(0, 1.48, 0)
    add_child(camera_pivot)
    camera = Camera3D.new()
    camera.fov = 72.0
    camera.near = 0.04
    camera.far = 320.0
    camera.position = Vector3(0.62, 0.20, 2.85)
    camera.current = true
    camera_pivot.add_child(camera)
    capsule = get_node("BodyShape").shape as CapsuleShape3D
    _create_weapons()
    build_sys = BuildScript.new()
    add_child(build_sys)
    build_sys.setup(self)
    G.player = self

func _create_weapons() -> void:
    for w in weapons:
        if is_instance_valid(w):
            w.queue_free()
    weapons.clear()
    for k in [primary_key, "pistol"]:
        var w = WeaponScript.new()
        add_child(w)
        w.setup(self, k)
        weapons.append(w)
    weapon = weapons[0]
    active_slot = 0
    for i in range(weapons.size()):
        if weapons[i].viewmodel != null:
            weapons[i].viewmodel.visible = false

func change_primary(key: String) -> void:
    if not G.weapons.has(key):
        return
    primary_key = key
    weapon_key = key
    _create_weapons()

func _physics_process(delta: float) -> void:
    if not alive:
        _spectate(delta)
        return
    fall_prev = velocity.y
    super._physics_process(delta)
    _after_move(delta)

func think(delta: float) -> void:
    var c = G.controls
    if c == null or not c.enabled:
        velocity.x = move_toward(velocity.x, 0.0, G.tuning.friction * delta)
        velocity.z = move_toward(velocity.z, 0.0, G.tuning.friction * delta)
        return
    var look = c.consume_look()
    var sens = 0.55 if aiming else 1.0
    rotation.y += look.x * sens
    pitch = clampf(pitch + look.y * sens, -1.45, 1.45)
    recoil = recoil.lerp(Vector2.ZERO, clampf(delta * 7.0, 0.0, 1.0))
    camera_pivot.rotation.x = pitch + recoil.y * 0.011
    camera_pivot.rotation.y = recoil.x * 0.008
    var lean_target = 0.0
    if c.lean_left:
        lean_target = 1.0
    elif c.lean_right:
        lean_target = -1.0
    lean = lerpf(lean, lean_target, clampf(delta * 9.0, 0.0, 1.0))
    camera.rotation.z = lean * 0.10
    crouched = c.crouch
    var h = 1.15 if crouched else 1.78
    capsule.height = lerpf(capsule.height, h, clampf(delta * 12.0, 0.0, 1.0))
    get_node("BodyShape").position.y = capsule.height * 0.5
    var wish = Vector3(c.move.x, 0.0, -c.move.y)
    wish = wish.rotated(Vector3.UP, rotation.y)
    if wish.length() > 1.0:
        wish = wish.normalized()
    var on_floor = is_on_floor()
    var sprinting = c.sprint and not crouched and not aiming and c.move.y > 0.1 and stamina > 1.0
    var target_speed = G.tuning.walk_speed
    if crouched:
        target_speed = G.tuning.crouch_speed
    elif sprinting:
        target_speed = G.tuning.sprint_speed
    elif aiming:
        target_speed = G.tuning.walk_speed * 0.55
    if sprinting:
        stamina = maxf(0.0, stamina - G.tuning.stamina_drain * delta)
    else:
        stamina = minf(G.tuning.stamina_max, stamina + G.tuning.stamina_regen * delta)
    var accel = G.tuning.accel if on_floor else G.tuning.air_accel
    var desired = wish * target_speed
    velocity.x = move_toward(velocity.x, desired.x, accel * delta)
    velocity.z = move_toward(velocity.z, desired.z, accel * delta)
    if wish.length() < 0.05 and on_floor:
        velocity.x = move_toward(velocity.x, 0.0, G.tuning.friction * delta)
        velocity.z = move_toward(velocity.z, 0.0, G.tuning.friction * delta)
    if c.jump and on_floor and not crouched and stamina > 14.0:
        velocity.y = G.tuning.jump_speed
        stamina -= 14.0
        G.audio.play("step", -12.0, 1.3)
    var hspeed = Vector2(velocity.x, velocity.z).length()
    if on_floor and hspeed > 0.6:
        step_dist += hspeed * delta
        bob += hspeed * delta * 1.7
        var stride = 2.1 if not crouched else 2.8
        if step_dist >= stride:
            step_dist = 0.0
            G.audio.play("step", -17.0 if crouched else -11.0, G.rng_range(0.88, 1.14))
            if G.match_mgr != null:
                G.match_mgr.report_noise(self, global_position, 11.0 if sprinting else 6.0)
    else:
        bob = lerpf(bob, 0.0, clampf(delta * 4.0, 0.0, 1.0))
    aiming = c.aim and (build_sys == null or not build_sys.active)
    camera.fov = lerpf(camera.fov, 55.0 if aiming else 72.0, clampf(delta * 12.0, 0.0, 1.0))
    var tp = not aiming
    third_person = tp
    var target_pos = Vector3(0.62, 0.20, 2.85)
    if not tp:
        target_pos = Vector3(0.0, G.tuning.eye_height - camera_pivot.position.y, 0.0)
    elif crouched:
        target_pos.y = 0.02
    target_pos.x += lean * 0.12
    camera.position = camera.position.lerp(target_pos, clampf(delta * 11.0, 0.0, 1.0))
    if model_root != null:
        model_root.visible = tp
    for w in weapons:
        if w.viewmodel != null:
            w.viewmodel.visible = (not tp) and (w == weapon)
    if switch_t > 0.0:
        switch_t -= delta
    if c.reload and weapon != null:
        weapon.start_reload()
    if c.weapon_primary and active_slot != 0:
        _switch(0)
    if c.weapon_secondary and active_slot != 1:
        _switch(1)
    if c.build_toggle and build_sys != null:
        build_sys.toggle()
    if c.build_cycle and build_sys != null and build_sys.active:
        build_sys.cycle()
    if build_sys != null and build_sys.active and c.fire:
        c.build_place = true
    if switch_t <= 0.0 and (build_sys == null or not build_sys.active) and weapon != null:
        var pressed = c.fire_just or (c.fire and bool(weapon.data.auto))
        if pressed:
            var spread = weapon.current_spread_deg(aiming, hspeed, crouched, not on_floor)
            var shot_origin = global_position + Vector3(0, 1.32 if not crouched else 1.02, 0) - camera.global_transform.basis.z * 0.65
            weapon.fire(shot_origin, -camera.global_transform.basis.z, spread, aiming)
    if G.match_mgr != null:
        G.match_mgr.update_interact(self, c.interact, delta)

func _switch(slot: int) -> void:
    if slot < 0 or slot >= weapons.size() or switch_t > 0.0:
        return
    for i in range(weapons.size()):
        if weapons[i].viewmodel != null:
            weapons[i].viewmodel.visible = (not third_person) and i == slot
    active_slot = slot
    weapon = weapons[slot]
    switch_t = 0.42
    G.audio.play("reload", -14.0, 1.4)

func _after_move(delta: float) -> void:
    if build_sys != null:
        build_sys.update(delta)
    if is_on_floor() and fall_prev < -G.tuning.fall_safe:
        var dmg = (absf(fall_prev) - G.tuning.fall_safe) * G.tuning.fall_damage
        apply_damage(dmg, "limb", null, global_position + Vector3(0, 0.3, 0))
        G.hud.damage_flash()
    if G.controls != null:
        G.controls.fire_just = false

func add_recoil(amount: float, is_aiming: bool) -> void:
    var f = 0.65 if is_aiming else 1.0
    recoil.y += amount * f * 4.2
    recoil.x += G.rng_range(-0.35, 0.35) * amount * f
    pitch = clampf(pitch + amount * f * 0.006, -1.45, 1.45)

func get_recoil_offset() -> Vector2:
    return recoil

func get_bob() -> float:
    return bob

func get_muzzle_hint() -> Vector3:
    return global_position + Vector3(0, 1.30 if not crouched else 1.0, 0) - global_transform.basis.z * 0.62

func die(killer: Node, headshot: bool = false) -> void:
    if not alive:
        return
    super.die(killer, headshot)
    for w in weapons:
        if w.viewmodel != null:
            w.viewmodel.visible = false
    if build_sys != null:
        build_sys.reset_round()
    G.controls.set_capture(false)
    camera.top_level = true
    camera_pivot.rotation = Vector3.ZERO
    spectate_t = 0.0
    spectate_idx = 0

func _spectate(_delta: float) -> void:
    if camera == null:
        return
    var mates = []
    if G.match_mgr != null:
        for s in G.match_mgr.all_soldiers():
            if is_instance_valid(s) and s.alive and s != self:
                mates.append(s)
    if mates.is_empty():
        camera.global_position = camera.global_position.lerp(global_position + Vector3(0, 6.0, 6.0), 0.02)
        camera.look_at(global_position, Vector3.UP)
        return
    var target: Node3D = mates[spectate_idx % mates.size()]
    var desired = target.global_position + Vector3(0, 2.4, 3.2).rotated(Vector3.UP, target.rotation.y)
    camera.global_position = camera.global_position.lerp(desired, 0.06)
    camera.look_at(target.head_point(), Vector3.UP)
    if G.controls.fire_just:
        spectate_idx += 1

func reset_for_round(pos: Vector3) -> void:
    super.reset_for_round(pos)
    stamina = G.tuning.stamina_max
    pitch = 0.0
    recoil = Vector2.ZERO
    bob = 0.0
    camera.top_level = false
    camera_pivot.rotation = Vector3.ZERO
    camera.position = Vector3(0.62, 0.20, 2.85)
    camera.rotation = Vector3.ZERO
    camera.current = true
    third_person = true
    if model_root != null:
        model_root.visible = true
    for i in range(weapons.size()):
        weapons[i].refill()
        if weapons[i].viewmodel != null:
            weapons[i].viewmodel.visible = false
    if build_sys != null:
        build_sys.reset_round()
    G.controls.set_capture(true)
