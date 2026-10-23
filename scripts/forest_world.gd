extends Node3D
const Visuals = preload("res://scripts/visuals.gd")
const Hunter = preload("res://scripts/player.gd")
const Monster = preload("res://scripts/monster.gd")
const Terrain = preload("res://scripts/forest_terrain.gd")
var hunter: CharacterBody3D
var hud: Label

func obstacle(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = pos
	Visuals.piece(body,Vector3.ZERO,size,color)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _ready() -> void:
	var env := WorldEnvironment.new()
	var atmosphere := Environment.new()
	atmosphere.background_mode = Environment.BG_COLOR
	atmosphere.background_color = Color("819e97")
	atmosphere.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	atmosphere.ambient_light_color = Color("b4d1c5")
	atmosphere.ambient_light_energy = 0.75
	atmosphere.fog_enabled = true
	atmosphere.fog_light_color = Color("7f9c92")
	atmosphere.fog_density = 0.008
	env.environment = atmosphere
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-25,0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	add_child(sun)
	add_child(Terrain.new())
	for side in [-1,1]:
		obstacle(Vector3(side*60,4,0),Vector3(1,8,120),Color("3f5348"))
		obstacle(Vector3(0,4,side*60),Vector3(120,8,1),Color("3f5348"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 37214
	var positions := [Vector3(0,1,-16),Vector3(-26,1,-22),Vector3(26,1,-22),Vector3(-25,1,24),Vector3(25,1,24)]
	for i in 110:
		var pos := Vector3(rng.randf_range(-56,56),0,rng.randf_range(-56,56))
		var clearing := absf(pos.x)<12
		for encounter in positions:
			if pos.distance_to(encounter)<9: clearing = true
		if clearing: continue
		pos.y = Terrain.height_at(pos.x,pos.z)
		var height := rng.randf_range(7,13)
		obstacle(pos+Vector3(0,height/2,0),Vector3(0.65,height,0.65),Color("4b5040"))
		Visuals.piece(self,pos+Vector3(0,height,0),Vector3(6,4,6),Color("365c43"),true)
		Visuals.piece(self,pos+Vector3(1,height-2,0),Vector3(5,3,5),Color("3c6748"),true)
	for i in 65:
		var pos := Vector3(rng.randf_range(-55,55),0,rng.randf_range(-55,55))
		pos.y = Terrain.height_at(pos.x,pos.z)
		if absf(pos.x)>7: Visuals.piece(self,pos+Vector3(0,0.25,0),Vector3(1.5,0.5,1.4),Color("4d7351"),true)
	for i in 24:
		var pos := Vector3(rng.randf_range(-55,55),0,rng.randf_range(-55,55))
		var safe := absf(pos.x)>13
		for encounter in positions:
			if pos.distance_to(encounter)<10: safe = false
		if not safe or absf(pos.x-41)<5: continue
		pos.y = Terrain.height_at(pos.x,pos.z)
		var radius := rng.randf_range(0.8,1.7)
		obstacle(pos+Vector3(0,radius*0.45,0),Vector3(radius*1.8,radius,radius*1.5),Color("5a665e"))
	hunter = Hunter.new()
	hunter.position = Vector3(0,1,8)
	add_child(hunter)
	var database: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/monsters.json"))
	for i in database.species.size():
		var monster := Monster.new()
		monster.data = database.species[i]
		monster.target = hunter
		monster.position = positions[i]
		add_child(monster)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(22,18)
	hud.add_theme_font_size_override("font_size",21)
	hud.add_theme_color_override("font_shadow_color",Color.BLACK)
	hud.add_theme_constant_override("shadow_offset_x",2)
	hud.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(hud)
	var info := Label.new()
	info.position = Vector2(22,550)
	info.add_theme_font_size_override("font_size",17)
	info.text = "WASD 移动 / 鼠标视角 / Shift 奔跑 / 空格闪避 / 中键锁定 / Esc 鼠标\n左键轻击 / 右键短按横扫、长按松开投掷瞬移 / E 回拉 / Alt+左键转身\nQ 格挡 → 左键反击 → Ctrl+左键闪刺得枪影 / R 收枪\nCtrl+左键四连刺 / Ctrl+右键旋转 / Ctrl+空格插地 → 再按 Ctrl 反击\nF5 重试 · 模型与动作初稿，尚非最终美术和手感"
	layer.add_child(info)
	print("SHUBIAN_FOREST_READY: hunter + five monster species")
	if "--capture" in OS.get_cmdline_user_args(): capture.call_deferred()

func _process(_delta: float) -> void:
	var c = hunter.combat
	hud.text = "戍边 · 湿林战斗原型\n生命 %d / 240   耐力 %d   枪影 %d / 5\n动作：%s  %.2fs\n%s" % [int(c.health),int(c.stamina),c.shadow_lifetimes.size(),c.action,c.elapsed,hunter.message]
	if c.health<=0: hud.text += "\n任务失败 · F5 重试"
	var defeated := 0
	for monster in get_tree().get_nodes_in_group("monsters"):
		if monster.health<=0: defeated += 1
	hud.text += "\n击退 %d / 5" % defeated
	if defeated==5 and c.health>0: hud.text += "\n林地已清理 · F5 重新挑战"
	if is_instance_valid(hunter.lock_target) and hunter.lock_target.health>0:
		var m = hunter.lock_target
		hud.text += "\n锁定：%s  %d/%d\n%s\n对策：%s" % [m.data.name,ceili(m.health),int(m.data.health),m.data.trait,m.data.weakness]

func capture() -> void:
	await get_tree().create_timer(1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Shubian-forest-prototype.png"))
	get_tree().quit()
