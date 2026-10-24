extends SceneTree
var world: Node3D
var creatures: Array = []
var camera: Camera3D
var frame := 0
var last_index := -1
var released := false
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
	world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	world.hunter.set_physics_process(false)
	world.hunter.global_position = Vector3(60,0,60)
	world.hunter.hide()
	world.hud.get_parent().hide()
	for foe in get_nodes_in_group("monsters"):
		foe.set_physics_process(false)
		foe.hide()
		if foe.data.pattern in ["mist","pulse"]:
			creatures.append(foe)
			foe.label.hide()
			foe.rotation = Vector3.ZERO
			foe.global_position = Vector3(0,0.05,-10)
	camera = Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(7,4.5,-17)
	camera.look_at(Vector3(0,1.5,-11))
	camera.make_current()
	physics_frame.connect(advance)
func advance() -> void:
	var index := mini(frame/240,1)
	var time := fmod(float(frame)/60,4.0)
	if index!=last_index:
		for effect in get_nodes_in_group("hazards"): effect.queue_free()
		last_index = index
		released = false
	for i in creatures.size(): creatures[i].visible = i==index
	var creature = creatures[index]
	var windup: float = creature.data.windup
	var phase := "windup"
	var clock := time
	if time>=windup+0.65+float(creature.data.recovery):
		phase = "idle"
		clock = 0
	elif time>=windup+0.65:
		phase = "recover"
		clock = time-windup-0.65
	elif time>=windup:
		phase = "active"
		clock = time-windup
	creature.CreatureModel.animate(creature.mesh,creature.data,0,phase,clock,0)
	creature.weak_marker.visible = phase=="windup"
	if phase=="active" and not released:
		released = true
		if creature.data.pattern=="mist": creature.spawn_hazard(Vector3(0,0,-14),4,6,9,"mist")
		else: creature.spawn_hazard(creature.global_position,creature.data.reach,0.7,creature.data.damage,"pulse")
	frame += 1
	if frame>=480:
		physics_frame.disconnect(advance)
		call_deferred("finish")
func finish() -> void:
	print("CAST_POSE_STUDY: two species; manual pose and effect study, not live AI combat")
	world.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit()
