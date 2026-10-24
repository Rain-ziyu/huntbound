extends SceneTree
var world: Node3D
var monster: CharacterBody3D
var camera: Camera3D
var frame := 0
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
	world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	world.hunter.set_physics_process(false)
	world.hunter.hide()
	world.hud.get_parent().hide()
	for foe in get_nodes_in_group("monsters"):
		foe.set_physics_process(false)
		foe.hide()
	monster = get_nodes_in_group("monsters")[0]
	monster.show()
	monster.label.hide()
	monster.weak_marker.hide()
	monster.global_position = Vector3(0,0.05,-10)
	monster.rotation = Vector3.ZERO
	camera = Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(7,4.5,-17)
	camera.look_at(Vector3(0,1.5,-11))
	camera.make_current()
	physics_frame.connect(advance)
func advance() -> void:
	var time := fmod(float(frame)/60,3.15)
	var phase := "windup"
	var clock := time
	if time>=1.75:
		phase = "recover"
		clock = time-1.75
	elif time>=1.1:
		phase = "active"
		clock = time-1.1
	monster.CreatureModel.animate(monster.mesh,monster.data,0,phase,clock,0)
	frame += 1
	if frame>=378:
		physics_frame.disconnect(advance)
		call_deferred("finish")
func finish() -> void:
	print("HEAD_SWEEP_STUDY: two cycles; presentation only, no combat controller")
	world.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit()
