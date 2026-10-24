extends SceneTree
var world: Node3D
var hunter: CharacterBody3D
var monster: CharacterBody3D
var frame := 0
var on_screen := 0
var maximum_error := 0.0
var initial_yaw := 0.0
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
	world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	hunter = world.hunter
	monster = get_nodes_in_group("monsters")[0]
	for m in get_nodes_in_group("monsters"):
		if m!=monster:
			m.set_physics_process(false)
			m.hide()
	var terrain = preload("res://scripts/forest_terrain.gd")
	monster.global_position.y = terrain.mesh_height_at(monster.global_position.x,monster.global_position.z)+0.01
	monster.velocity = Vector3.ZERO
	await physics_frame
	await physics_frame
	monster.set_physics_process(false)
	monster.CreatureModel.animate(monster.mesh,monster.data,0,"idle",0,0,monster.foot_ground_height,monster.foot_ground_normal)
	hunter.global_position = monster.global_position+Vector3(0,0,6)
	hunter.lock_target = monster
	hunter.yaw = 0
	hunter.pitch = -0.25
	hunter.camera_manual_time = 0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	initial_yaw = hunter.yaw
	await physics_frame
	await physics_frame
	physics_frame.connect(control)
func control() -> void:
	Input.action_press("move_right")
	Input.action_press("move_forward",0.15)
	var offset := monster.global_position-hunter.global_position
	maximum_error = maxf(maximum_error,absf(wrapf(hunter.yaw-atan2(-offset.x,-offset.z),-PI,PI)))
	if hunter.camera.is_position_in_frustum(monster.global_position+Vector3.UP*float(monster.data.size)*0.6): on_screen += 1
	frame += 1
	if frame>=300:
		physics_frame.disconnect(control)
		call_deferred("finish")
func finish() -> void:
	for action in ["move_right","move_forward"]: Input.action_release(action)
	var passed: bool = on_screen>=frame-2 and maximum_error<0.25 and absf(wrapf(hunter.yaw-initial_yaw,-PI,PI))>1
	print("LOCK_CAMERA_REPLAY: passed=",passed," target_visible_frames=",on_screen,"/",frame," max_heading_error=",maximum_error,"; stationary creature, ordinary movement inputs, not combat or human handfeel acceptance")
	world.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit(0 if passed else 1)
