extends CharacterBody3D
const Combat = preload("res://scripts/combat/trident_combat.gd")
const Visuals = preload("res://scripts/visuals.gd")
var combat = Combat.new()
var rig: Dictionary
var mount: Node3D
var yaw := 0.0
var pitch := -0.25
var walk_clock := 0.0
var heavy_held := -1.0
var lock_target: Node3D
var message := "观察金色预警后躲避或格挡。"
var ghosts: Array[Node3D] = []

func _ready() -> void:
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.8
	col.shape = shape
	col.position.y = 0.9
	add_child(col)
	rig = Visuals.hunter(self)
	mount = Node3D.new()
	get_parent().add_child.call_deferred(mount)
	var arm := SpringArm3D.new()
	arm.spring_length = 5.8
	arm.margin = 0.2
	arm.add_excluded_object(get_rid())
	mount.add_child(arm)
	var camera := Camera3D.new()
	camera.fov = 68
	camera.current = true
	arm.add_child(camera)
	combat.strike.connect(on_strike)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for i in 5:
		var ghost := Visuals.trident(rig.root,true)
		ghost.position = Vector3((i-2)*0.23,1.35,0.38)
		ghost.rotation.z = (i-2)*-0.17
		ghost.scale = Vector3.ONE*0.65
		ghosts.append(ghost)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x*0.003
		pitch = clampf(pitch-event.relative.y*0.0025,-0.9,0.25)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
			KEY_Q: combat.request("guard")
			KEY_E: combat.request("pull")
			KEY_R: combat.request("sheathe")
			KEY_SPACE: combat.request("plant" if event.ctrl_pressed else "dodge")
			KEY_CTRL:
				if combat.action=="wait": combat.request("counter_window")
			KEY_F5: get_tree().reload_current_scene()
	if event is InputEventMouseButton:
		if event.pressed and event.button_index==MOUSE_BUTTON_MIDDLE:
			lock_target = nearest_monster() if not is_instance_valid(lock_target) else null
		if event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
			var next := "light"
			if event.alt_pressed: next = "turn"
			elif event.ctrl_pressed: next = "flash" if combat.flash_window>0 else "fourfold"
			elif combat.guard_reward>0: next = "reply"
			combat.request(next)
		if event.button_index==MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if event.ctrl_pressed: combat.request("spin")
				else: heavy_held = 0
			elif heavy_held>=0:
				combat.request("throw" if heavy_held>=0.45 else "heavy")
				heavy_held = -1

func nearest_monster() -> Node3D:
	var result: Node3D
	var distance := 24.0
	for m in get_tree().get_nodes_in_group("monsters"):
		var d: float = global_position.distance_to(m.global_position)
		if m.health>0 and d<distance:
			distance = d
			result = m
	return result

func _physics_process(delta: float) -> void:
	if heavy_held>=0: heavy_held += delta
	combat.advance(delta)
	if is_instance_valid(lock_target) and lock_target.health<=0: lock_target = null
	var input := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W): input.z -= 1
	if Input.is_physical_key_pressed(KEY_S): input.z += 1
	if Input.is_physical_key_pressed(KEY_A): input.x -= 1
	if Input.is_physical_key_pressed(KEY_D): input.x += 1
	var direction := input.normalized().rotated(Vector3.UP,yaw)
	var speed := 6.3 if Input.is_physical_key_pressed(KEY_SHIFT) else 4.5
	if combat.action!="idle": speed *= 0.22
	if combat.action in ["plant","wait","counter_window","hurt"] or combat.health<=0: speed = 0
	velocity.x = direction.x*speed
	velocity.z = direction.z*speed
	if combat.action=="dodge":
		var dash: Vector3 = direction if direction.length()>0 else -rig.root.basis.z
		velocity.x = dash.x*9
		velocity.z = dash.z*9
	if combat.action=="flash" and combat.elapsed<0.23:
		velocity.x = -rig.root.basis.z.x*13
		velocity.z = -rig.root.basis.z.z*13
	if not is_on_floor(): velocity.y -= 24*delta
	move_and_slide()
	if is_instance_valid(lock_target):
		var offset := lock_target.global_position-global_position
		rig.root.rotation.y = lerp_angle(rig.root.rotation.y,atan2(-offset.x,-offset.z),delta*10)
	elif direction.length()>0.1:
		rig.root.rotation.y = lerp_angle(rig.root.rotation.y,atan2(-direction.x,-direction.z),delta*12)
	mount.position = global_position+Vector3(0,1.5,0)
	mount.rotation = Vector3(pitch,yaw,0)
	animate(delta,direction.length()*speed)
	if global_position.y < -15: global_position = Vector3(0,2,8)

func animate(delta: float, speed: float) -> void:
	walk_clock += delta*speed*2.6
	for side in [-1,1]:
		rig.joints["leg"+str(side)].rotation.x = sin(walk_clock)*side*minf(speed*0.1,0.45)
		rig.joints["arm"+str(side)].rotation.x = -0.85 if combat.drawn else -sin(walk_clock)*side*minf(speed*0.08,0.3)
	var w: Node3D = rig.weapon
	w.visible = true
	w.position = Vector3(0.24,1.05,-0.45) if combat.drawn else Vector3(0,1.05,0.26)
	w.rotation = Vector3(-PI/2,0,-0.15) if combat.drawn else Vector3(0,0,0.35)
	if combat.action!="idle":
		var t: float = combat.elapsed
		var p := clampf(t/float(Combat.MOVES[combat.action].duration),0,1)
		match combat.action:
			"light","flash","fourfold":
				var pulse := sin(p*PI) if combat.action!="fourfold" else sin(p*PI*4)
				w.position.z -= maxf(0,pulse)*0.8
				w.rotation.x -= 0.18
			"heavy","turn","spin","finisher":
				w.rotation.y = -1.5+p*(TAU if combat.action in ["turn","spin","finisher"] else 3)
				if combat.action=="finisher" and p>0.55: rig.joints["leg1"].rotation.x = -sin((p-0.55)/0.45*PI)*1.3
			"guard","reply":
				w.rotation.y = clampf(t/0.18,0,1)*PI
				w.position.z += 0.55
				if combat.action=="reply": w.position.z -= sin(p*PI)*0.8
			"plant","wait","counter_window":
				w.position = Vector3(0,1.0,-0.7)
				w.rotation = Vector3(0,0,PI)
			"throw": w.visible = t<0.38
	for i in ghosts.size(): ghosts[i].visible = i<combat.shadow_lifetimes.size()

func take_damage(amount: float, origin: Vector3, blockable: bool) -> void:
	var direction := (origin-global_position).normalized()
	var result: String = combat.receive_damage(amount,blockable,direction.dot(-rig.root.global_basis.z)>0.15)
	message = {"counter":"反击成功！旋转踢击，不消耗枪影。","guarded":"格挡成功：左键反击，再 Ctrl+左键闪刺。","immune":"免伤","armored":"霸体承伤：动作继续","hurt":"受击！注意预警与站位。"}.get(result,result)

func on_strike(_beat: int) -> void:
	var action: String = combat.action
	var reach: float = Combat.MOVES[action].reach
	var hit := false
	for m in get_tree().get_nodes_in_group("monsters"):
		var offset: Vector3 = m.global_position-global_position
		offset.y = 0
		var angle: float = offset.normalized().dot(-rig.root.global_basis.z)
		var broad := action in ["heavy","turn","spin","finisher"]
		if offset.length() <= reach+float(m.data.size)*0.30 and (broad or angle>0.55):
			var result: Dictionary = m.receive_strike(combat.damage(),global_position,action)
			if result.hit:
				hit = true
				combat.confirm_hit()
				message = ("弱点！ " if result.weak else "命中 ")+str(roundi(result.damage))
	if action=="throw":
		var motion: Vector3 = -rig.root.global_basis.z*(10 if not hit else 6)
		var collision := move_and_collide(motion,true)
		if collision: motion = collision.get_travel()*0.90
		global_position += motion
		message = "投掷后移至安全落点" if motion.length()>0.5 else "落点受阻"
