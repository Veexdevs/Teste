extends Node3D
## Construcao: preview, validacao de espaco, tempo de montagem e cargas.

const FortScript = preload("res://game/entities/fortification.gd")

var player: Node3D
var active = false
var selected = "sandbag"
var charges = {"sandbag": 1, "hesco": 0, "wire": 1, "shield": 0}
var ghost: MeshInstance3D
var ghost_mesh: BoxMesh
var ghost_mat: StandardMaterial3D
var place_pos = Vector3.ZERO
var place_yaw = 0.0
var valid = false
var progress = 0.0
var building = false
var order = ["sandbag", "hesco", "wire", "shield"]

func setup(p: Node3D) -> void:
    player = p
    ghost_mesh = BoxMesh.new()
    ghost = MeshInstance3D.new()
    ghost.mesh = ghost_mesh
    ghost_mat = G.materials.ghost(Color(0.25, 1.0, 0.35))
    ghost.material_override = ghost_mat
    ghost.visible = false
    G.world.add_child(ghost)

func add_charges(kind: String, n: int) -> void:
    charges[kind] = int(charges.get(kind, 0)) + n

func cycle() -> void:
    var i = order.find(selected)
    selected = order[(i + 1) % order.size()]
    G.audio.play("ui", -12.0)
    G.hud.flash("FORTIFICACAO: " + str(G.fortifications[selected].name))

func toggle() -> void:
    active = not active
    building = false
    progress = 0.0
    ghost.visible = active
    G.audio.play("ui", -10.0)
    G.hud.set_build_mode(active, selected)

func update(delta: float) -> void:
    if not active or player == null or not player.alive:
        if ghost != null:
            ghost.visible = false
        return
    ghost.visible = true
    var cfg: Dictionary = G.fortifications[selected]
    var size: Vector3 = cfg.size
    var cam: Camera3D = player.camera
    var from = cam.global_position
    var fwd = -cam.global_transform.basis.z
    var to = from + fwd * 4.2
    var space = player.get_world_3d().direct_space_state
    var q = PhysicsRayQueryParameters3D.create(from, to)
    q.collision_mask = G.L_WORLD | G.L_FORT
    q.exclude = [player.get_rid()]
    var hit = space.intersect_ray(q)
    var p = to
    if not hit.is_empty():
        p = hit.position
    p.y = 0.0
    if G.controls.build_rotate and not G.is_mobile():
        place_yaw += PI * 0.25
    if G.controls.touch_rotate:
        place_yaw += PI * 0.25
        G.controls.touch_rotate = false
    if G.is_mobile():
        place_yaw = -player.global_rotation.y + PI
    var center = p + Vector3(0, size.y * 0.5, 0)
    var shape = BoxShape3D.new()
    shape.size = size * 0.92
    var params = PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = Transform3D(Basis.from_euler(Vector3(0, place_yaw, 0)), center)
    params.collision_mask = G.L_WORLD | G.L_CHARACTER | G.L_FORT
    params.exclude = [player.get_rid()]
    var overlaps = space.intersect_shape(params, 2)
    valid = overlaps.is_empty() and charges.get(selected, 0) > 0
    valid = valid and (p.distance_to(player.global_position) > 1.15)
    place_pos = p
    ghost_mesh.size = size
    ghost.position = center
    ghost.rotation.y = place_yaw
    var c = Color(0.25, 1.0, 0.35) if valid else Color(1.0, 0.25, 0.20)
    ghost_mat.albedo_color = Color(c.r, c.g, c.b, 0.35)
    var want = G.controls.build_place or (G.controls.fire and G.is_mobile())
    if want and valid:
        if not building:
            building = true
            progress = 0.0
        progress += delta
        G.hud.set_build_progress(progress / float(cfg.build), str(cfg.name))
        if progress >= float(cfg.build):
            _place()
            building = false
            progress = 0.0
            G.hud.set_build_progress(0.0, "")
    else:
        building = false
        progress = 0.0
        G.hud.set_build_progress(0.0, "")
    if G.controls.build_place:
        G.controls.build_place = false

func _place() -> void:
    var f = FortScript.new()
    G.world.add_child(f)
    f.init(selected, place_pos, place_yaw, player.team)
    charges[selected] = int(charges.get(selected, 0)) - int(G.fortifications[selected].charges)
    G.audio.play_at("build", place_pos, -3.0)
    G.hud.flash("COBERTURA MONTADA - " + str(G.fortifications[selected].name))
    G.fx.impact(place_pos + Vector3(0, 0.4, 0), Vector3.UP, "wood")
    if charges[selected] <= 0:
        for k in order:
            if int(charges.get(k, 0)) > 0:
                selected = k
                G.hud.set_build_mode(active, selected)
                break

func reset_round() -> void:
    active = false
    building = false
    progress = 0.0
    if ghost != null:
        ghost.visible = false
    G.hud.set_build_mode(false, selected)
