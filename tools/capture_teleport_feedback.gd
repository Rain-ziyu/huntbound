extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await create_timer(0.3).timeout
	var p = world.hunter
	p.set_physics_process(false)
	for m in get_nodes_in_group("monsters"): m.set_physics_process(false)
	world.hud.get_parent().hide()
	p.global_position = Vector3(0,0.05,-10)
	await physics_frame
	p.finish_throw(Vector3(0,0,-14))
	for effect in get_nodes_in_group("teleport_feedback"): effect.set_process(false)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(7,4,-7)
	camera.look_at(Vector3(0,1,-12))
	camera.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Shubian-teleport-feedback.png"))
	world.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit()
