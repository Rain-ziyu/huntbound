extends SceneTree
const Terrain = preload("res://scripts/forest_terrain.gd")
const Hazard = preload("res://scripts/hazard.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await create_timer(0.3).timeout
	world.hunter.set_physics_process(false)
	world.hunter.global_position = Vector3(60,0,60)
	world.hunter.hide()
	world.hud.get_parent().hide()
	for m in get_nodes_in_group("monsters"):
		m.set_physics_process(false)
		m.hide()
	var cloud := Hazard.new()
	var pulse := "--pulse" in OS.get_cmdline_user_args()
	if pulse:
		cloud.kind = "pulse"
		cloud.radius = 6.5
	cloud.target = world.hunter
	world.add_child(cloud)
	cloud.global_position = Vector3(38,Terrain.mesh_height_at(38,12)+0.05,12)
	cloud.set_physics_process(false)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(46,7,20)
	if pulse: camera.position = Vector3(49,10,23)
	camera.look_at(Vector3(38,0.3,12))
	camera.make_current()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var saved := root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Shubian-pulse-ground.png" if pulse else "res://../Shubian-mist-ground.png"))
	print("HAZARD_GROUND_CAPTURE: ",saved)
	world.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit(0 if saved==OK else 1)
