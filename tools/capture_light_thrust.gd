extends SceneTree
const Player = preload("res://scripts/player.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(800,600)
	root.content_scale_size = Vector2i(800,600)
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("58655c")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.6
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation = Vector3(-0.8,-0.4,0)
	stage.add_child(light)
	Player.Visuals.piece(stage,Vector3(0,-0.12,0),Vector3(10,0.2,10),Color("7b887b"))
	var p := Player.new()
	p.set_physics_process(false)
	stage.add_child(p)
	p.set_physics_process(false)
	await process_frame
	await process_frame
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(3.8,2,0.6)
	camera.look_at(Vector3(0,1,-0.6))
	camera.fov = 35
	camera.current = true
	var layer := CanvasLayer.new()
	stage.add_child(layer)
	var label := Label.new()
	label.position = Vector2(20,20)
	label.add_theme_font_size_override("font_size",24)
	layer.add_child(label)
	var sheet := Image.create(2400,600,false,Image.FORMAT_RGB8)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	p.yaw = 0
	var heavy := "--heavy" in OS.get_cmdline_user_args()
	var pull := "--pull" in OS.get_cmdline_user_args()
	p.combat.set_action("pull" if pull else ("heavy" if heavy else "light"))
	p.rig.root.rotation.y = 0
	for i in 3:
		var t: float = ([0.22,0.40,0.58] if pull else ([0.18,0.43,0.60] if heavy else [0.11,0.25,0.34]))[i]
		p.combat.elapsed = t
		p.animate(0,0)
		label.text = ["01 / PREPARE","02 / CONTACT","03 / FOLLOW THROUGH"][i]+" / %.2f s" % t
		await process_frame
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var frame := root.get_texture().get_image()
		frame.resize(800,600)
		frame.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(frame,Rect2i(0,0,800,600),Vector2i(i*800,0))
	sheet.save_png(ProjectSettings.globalize_path("res://../Shubian-pull-motion.png" if pull else ("res://../Shubian-heavy-sweep.png" if heavy else "res://../Shubian-light-thrust.png")))
	stage.queue_free()
	await process_frame
	quit()
