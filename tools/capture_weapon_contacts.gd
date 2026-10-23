extends SceneTree
## Engine-rendered inspection of the actual blade/butt contact samples, not final VFX.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	var p = world.hunter
	p.set_physics_process(false)
	for m in get_nodes_in_group("monsters"): m.set_physics_process(false)
	for child in world.get_children():
		if child is CanvasLayer: child.hide()
	p.combat.drawn = true
	p.mount.position = p.global_position+Vector3(0,1.0,0)
	p.mount.rotation = Vector3(-0.10,PI/2-0.35,0)
	root.get_camera_3d().fov = 30
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var label := Label.new()
	label.position = Vector2(24,24)
	label.add_theme_font_size_override("font_size",26)
	layer.add_child(label)
	for action in ["heavy","reply","pull","finisher"]:
		var markers := Node3D.new()
		world.add_child(markers)
		p.combat.set_action(action)
		var beat := 1 if action=="finisher" else 0
		var hit: float = p.Combat.MOVES[action].hits[beat]
		for sample in 13:
			p.combat.elapsed = hit+sample*0.01
			p.animate(0,0)
			for point in p.weapon_contact_points(action,beat):
				p.Visuals.piece(markers,point,Vector3.ONE*0.035,Color("eac46b") if action=="reply" else Color("77ded1"),true)
		p.combat.elapsed = hit+0.06
		p.animate(0,0)
		label.text = "SHUBIAN / CONTACT INSPECTION / "+action.to_upper()+"\nDots = active-frame contact samples (0.12 s)"
		await process_frame
		await RenderingServer.frame_post_draw
		var destination := ProjectSettings.globalize_path("res://../Shubian-contact-"+action+".png")
		var error := root.get_texture().get_image().save_png(destination)
		print("CONTACT_CAPTURE: ",action," ",error)
		if error!=OK:
			quit(1)
			return
		markers.queue_free()
		await process_frame
	quit()
