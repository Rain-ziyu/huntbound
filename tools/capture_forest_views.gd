extends SceneTree
const Terrain = preload("res://scripts/forest_terrain.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await create_timer(0.5).timeout
	world.hunter.set_physics_process(false)
	for monster in get_nodes_in_group("monsters"): monster.set_physics_process(false)
	for child in world.get_children():
		if child is CanvasLayer: child.hide()
	var original := root.get_camera_3d()
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	camera.fov = 62
	var views := [
		{"id":"overview","position":Vector3(0,10,26),"target":Vector3(0,2,-12)},
		{"id":"grove","position":Vector3(-40,Terrain.height_at(-40,5)+1.8,5),"target":Vector3(-48,3.0,-3)},
		{"id":"stream","position":Vector3(46,Terrain.height_at(46,10)+2,10),"target":Vector3(41,0,-8)}
	]
	for view in views:
		camera.position = view.position
		camera.look_at(view.target)
		await create_timer(0.25).timeout
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Shubian-forest-"+str(view.id)+".png"))
		print("FOREST_VIEW: ",view.id," ",error)
		if error!=OK: quit(1); return
	original.make_current()
	for frame in 60: await process_frame
	var samples: Array[float] = []
	var draw_calls := 0.0
	var primitives := 0.0
	for frame in 120:
		var before := Time.get_ticks_usec()
		await process_frame
		samples.append((Time.get_ticks_usec()-before)/1000.0)
		draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var total := 0.0
	for value in samples: total += value
	samples.sort()
	var report := {"scope":"1280x720 graphical third person idle view after warmup; actors frozen; includes frame pacing; not combat stress or human smoothness acceptance","mean_frame_ms":snappedf(total/samples.size(),0.01),"p95_frame_ms":snappedf(samples[113],0.01),"mean_draw_calls":roundi(draw_calls/120),"mean_primitives":roundi(primitives/120),"trees":get_nodes_in_group("forest_trees").size(),"ferns":get_nodes_in_group("forest_understory")[0].multimesh.instance_count}
	var file := FileAccess.open("res://../Shubian-forest-render-check.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("FOREST_RENDER_CHECK: ",JSON.stringify(report))
	world.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit()
