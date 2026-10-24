extends SceneTree
const Model = preload("res://scripts/creature_model.gd")
var stage: Node3D
var tails: Array[Node3D] = []
var frame := 0
var running := false
func _initialize() -> void: call_deferred("run")
func run() -> void:
	stage = Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("96aaa4")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.55
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50,-25,0)
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	stage.add_child(sun)
	Model.V.piece(stage,Vector3(0,-0.15,1),Vector3(22,0.3,18),Color("596d64"))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/monsters.json"))
	for side in [-1,1]:
		var holder := Node3D.new()
		stage.add_child(holder)
		holder.position.x = side*3.2
		var model := Model.create(holder,data.species[3])
		tails.append(model.get_node("Tail"))
		var label := Label3D.new()
		label.text = "整段摆动对照" if side==-1 else "骨骼弯曲"
		label.position = Vector3(0,4,0)
		label.font_size = 38
		label.pixel_size = 0.012
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		holder.add_child(label)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0,13,17)
	camera.look_at(Vector3(0,1.4,1.0))
	camera.fov = 47
	camera.current = true
	var title := Label.new()
	title.text = "戍边 · 尾部骨骼动作对照（非实战回放）"
	title.position = Vector2(20,18)
	title.add_theme_font_size_override("font_size",26)
	root.add_child(title)
	for warmup in 30: await process_frame
	running = true
func _process(_delta: float) -> bool:
	if not running: return false
	var time := float(frame)/60
	for i in 2:
		tails[i].rotation.y = sin(time*2)*0.12
		if i==1: Model.TailSkin.animate(tails[i],time*3,"active",fmod(time,0.65))
	frame += 1
	if frame>=240:
		running = false
		call_deferred("finish")
	return false
func finish() -> void:
	print("TAIL_SKIN_STUDY: 240 frames; visual comparison only")
	stage.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit()
