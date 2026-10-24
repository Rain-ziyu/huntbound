extends SceneTree
var world: Node3D
var creatures: Array = []
var frame := 0
var study_camera: Camera3D
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
		if foe.data.pattern in ["charge","leap"]:
			creatures.append(foe)
			foe.show()
			foe.label.hide()
			foe.weak_marker.hide()
			foe.rotation = Vector3.ZERO
	var camera := Camera3D.new()
	study_camera = camera
	world.add_child(camera)
	camera.position = Vector3(13,9,-27)
	camera.look_at(Vector3(0,1,-13))
	camera.make_current()
	physics_frame.connect(advance)
func advance() -> void:
	var time := fmod(float(frame)/60,3.5)
	for i in creatures.size():
		var creature = creatures[i]
		creature.visible = i==mini(frame/210,1)
		var windup: float = creature.data.windup
		var speed := 13.0 if creature.data.pattern=="charge" else 10.0
		var travel := clampf(time-windup,0,0.65)
		creature.global_position = Vector3(0,0.05,-10-travel*speed)
		var phase := "windup"
		var clock := time
		if time>=windup+0.65:
			phase = "recover"
			clock = time-windup-0.65
		elif time>=windup:
			phase = "active"
			clock = time-windup
		var gait: float = travel*float(creature.data.speed)*1.2*creature.CreatureModel.GAIT_PER_METER
		creature.CreatureModel.animate(creature.mesh,creature.data,gait,phase,clock,speed if phase=="active" else 0)
	var selected = creatures[mini(frame/210,1)]
	study_camera.position = selected.global_position+Vector3(7,4.5,-7)
	study_camera.look_at(selected.global_position+Vector3(0,1.3,-0.5))
	frame += 1
	if frame>=420:
		physics_frame.disconnect(advance)
		call_deferred("finish")
func finish() -> void:
	print("LUNGE_POSE_STUDY: two species, one close-up cycle each; visual study, not live AI combat")
	world.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit()
