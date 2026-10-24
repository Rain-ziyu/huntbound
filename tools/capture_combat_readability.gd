extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await create_timer(0.3).timeout
	var p = world.hunter
	p.set_physics_process(false)
	for monster in get_nodes_in_group("monsters"): monster.set_physics_process(false)
	var m = get_nodes_in_group("monsters")[0]
	p.global_position = m.global_position+Vector3(0,0,2.2)
	p.lock_target = m
	m.rotation.y = PI
	m.phase = "windup"
	m.clock = m.data.windup*0.8
	m.rear_attack = false
	m.CreatureModel.animate(m.mesh,m.data,0,m.phase,m.clock,0)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = p.global_position+Vector3(0,2.8,5)
	camera.look_at(m.global_position+Vector3(0,1.5,0))
	camera.make_current()
	world.combat_hud.update_state(p,0)
	m.update_nameplate()
	await process_frame
	await RenderingServer.frame_post_draw
	var saved := root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Shubian-combat-readable.png"))
	print("COMBAT_READABILITY_CAPTURE: ",saved," locked_nameplate_hidden=",not m.label.visible)
	world.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit(0 if saved==OK else 1)
