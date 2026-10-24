extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	world.hunter.set_physics_process(false)
	world.hunter.set_process_unhandled_input(false)
	world.hud.get_parent().hide()
	var monster: CharacterBody3D
	for m in get_nodes_in_group("monsters"):
		m.set_physics_process(false)
		m.hide()
		if m.data.id=="thornhorn": monster = m
	monster.show()
	monster.global_position = Vector3(0,0,-16)
	monster.rotation = Vector3.ZERO
	monster.label.text = "棘角奔龙 · 冲锋路径示意\n锁定后横向避开 · 非完整实战回放"
	world.hunter.global_position = Vector3(0,0,-18.8)
	monster.lunge_tell.configure(monster.global_position,Vector3.FORWARD,float(monster.data.size)*0.34+0.32,13*0.65+3.8)
	monster.lunge_tell.show()
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = monster.global_position+Vector3(8,11,6)
	camera.look_at(monster.global_position+Vector3(0,0,-4))
	camera.fov = 58
	camera.current = true
	for frame in 30: await process_frame
	# The hunter's deferred spring-arm mount registers its camera after scene creation.
	camera.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Shubian-lunge-warning.png"))
	print("LUNGE_WARNING_CAPTURE: ",result)
	world.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit(0 if result==OK else 1)
