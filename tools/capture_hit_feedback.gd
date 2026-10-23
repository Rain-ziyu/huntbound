extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	var p = world.hunter
	p.set_physics_process(false)
	p.set_process(false)
	for m in get_nodes_in_group("monsters"): m.set_physics_process(false)
	for child in world.get_children():
		if child is CanvasLayer: child.hide()
	var monster = get_nodes_in_group("monsters")[0]
	p.global_position = Vector3(0,0.05,8)
	p.rig.root.rotation.y = 0
	monster.global_position = Vector3(0,0.05,6)
	monster.rotation.y = PI/2
	monster.label.hide()
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(7,4,11)
	camera.look_at(Vector3(0,1.4,6.8))
	camera.fov = 43
	camera.current = true
	p.combat.set_action("light")
	p.combat.elapsed = 0.25
	p.animate(0,0)
	p.on_strike(0)
	p.update_weapon_contacts()
	var effects := get_nodes_in_group("hit_feedback")
	if effects.is_empty():
		printerr("CAPTURE_FAILED: expected actual contact")
		quit(1)
		return
	for effect in effects:
		effect.set_process(false)
		effect.advance_visual(0.04)
	monster.set_process(false)
	monster._process(0.02)
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Shubian-hit-feedback.png"))
	print("HIT_FEEDBACK_CAPTURE: ",result)
	# Let the short sound finish and remove the scene before exiting.
	await create_timer(0.7).timeout
	world.queue_free()
	await process_frame
	quit(0 if result==OK else 1)
