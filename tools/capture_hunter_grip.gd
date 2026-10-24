extends SceneTree
const H = preload("res://scripts/hunter_model.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("59665e")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.65
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation = Vector3(-0.7,-0.5,0)
	stage.add_child(light)
	var rig := H.create(stage)
	rig.weapon.position = Vector3(0,1.15,-0.4)
	rig.weapon.rotation = Vector3(0,0,PI/2)
	H.pose_arms(rig,true,0)
	H.pose_legs(rig,"idle",0,true,0,0,0)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(-0.8,1.65,-1.7)
	camera.look_at(Vector3(0,1.18,-0.35))
	camera.fov = 38
	camera.current = true
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Shubian-hunter-grip.png"))
	stage.queue_free()
	await process_frame
	quit()
