extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await create_timer(0.5).timeout
	var p = world.hunter
	p.yaw = 0
	p.pitch = -0.25
	await physics_frame
	await physics_frame
	var cue = p.get_node("OcclusionVisibility")
	cue._physics_process(0)
	print("SPAWN_VISIBILITY_DIAGNOSTIC: gate=",cue.occluded," camera=",p.camera.global_position," hunter=",p.global_position)
	for height in [0.9,1.55]:
		var destination: Vector3 = p.global_position+Vector3.UP*height
		var query := PhysicsRayQueryParameters3D.create(p.camera.global_position,destination,3,[p.get_rid()])
		var hit: Dictionary = p.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty(): print("SPAWN_RAY_HIT: ",hit.collider.get_class()," ",hit.collider.name," at ",hit.position)
	checks += 1
	if cue.occluded:
		failures += 1
		printerr("FAIL: unobstructed initial hunter should not enable silhouette")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Shubian-spawn-visibility.png"))
	print("SPAWN_VISIBILITY_CHECKS: ",checks," FAILURES: ",failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
