extends CharacterBody3D
signal hit_confirmed(action: String, beat: int, target: Node3D, result: Dictionary)
const Combat = preload("res://scripts/combat/trident_combat.gd")
const Visuals = preload("res://scripts/visuals.gd")
const Projectile = preload("res://scripts/trident_projectile.gd")
const HunterModel = preload("res://scripts/hunter_model.gd")
const Parts = preload("res://scripts/monster_parts.gd")
const HitFeedback = preload("res://scripts/hit_feedback.gd")
var combat = Combat.new()
var rig: Dictionary
var mount: Node3D
var yaw := 0.0
var pitch := -0.25
var motion_epoch := 0
var walk_clock := 0.0
var heavy_held := -1.0
var lock_target: Node3D
var message := "观察金色预警后躲避或格挡。"
var ghosts: Array[Node3D] = []
var projectile: Node3D
var pose_action := ""
var pose_from := Transform3D.IDENTITY
var pose_blend := 1.0
var strike_windows: Array[Dictionary] = []
var camera: Camera3D
var shake_time := 0.0
var shake_strength := 0.0

func _ready() -> void:
	var keys := {"move_forward":KEY_W,"move_back":KEY_S,"move_left":KEY_A,"move_right":KEY_D,"sprint":KEY_SHIFT}
	for label in keys:
		if not InputMap.has_action(label):
			InputMap.add_action(label)
			var binding := InputEventKey.new()
			binding.physical_keycode = keys[label]
			InputMap.action_add_event(label,binding)
	collision_mask = 3
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.8
	col.shape = shape
	col.position.y = 0.9
	add_child(col)
	rig = HunterModel.create(self)
	mount = Node3D.new()
	get_parent().add_child.call_deferred(mount)
	var arm := SpringArm3D.new()
	arm.spring_length = 5.8
	arm.margin = 0.2
	arm.collision_mask = 3
	arm.add_excluded_object(get_rid())
	mount.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 68
	camera.current = true
	arm.add_child(camera)
	combat.strike.connect(on_strike)
	combat.action_changed.connect(on_action_changed)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for i in 5:
		var ghost := Visuals.trident(rig.root,true)
		ghost.position = Vector3((i-2)*0.23,1.35,0.38)
		ghost.rotation.z = (i-2)*-0.17
		ghost.scale = Vector3.ONE*0.65
		ghosts.append(ghost)

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(projectile):
		if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]: return
		if event is InputEventKey and (event.physical_keycode in [KEY_Q,KEY_E,KEY_R] or (event.physical_keycode==KEY_SPACE and event.ctrl_pressed)): return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		apply_look(event.relative)
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

func apply_look(relative: Vector2) -> void:
	yaw -= relative.x*0.003
	pitch = clampf(pitch-relative.y*0.0025,-0.9,0.65)

func on_action_changed(next: String) -> void:
	strike_windows.clear()
	if not is_instance_valid(lock_target) and next not in ["idle","hurt","dodge","wait","counter_window"]:
		rig.root.rotation.y = yaw

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
	var axis := Input.get_vector("move_left","move_right","move_forward","move_back")
	var input := Vector3(axis.x,0,axis.y)
	var direction := input.normalized().rotated(Vector3.UP,yaw)
	var speed := 6.3 if Input.is_action_pressed("sprint") else 4.5
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
	elif direction.length()>0.1 and combat.action=="idle":
		rig.root.rotation.y = lerp_angle(rig.root.rotation.y,atan2(-direction.x,-direction.z),delta*12)
	mount.position = global_position+Vector3(0,1.5,0)
	# Keep the orbit above the floor while the nearby weapon aims at elevated parts.
	var orbit_pitch := pitch*0.2 if pitch>0 else pitch
	mount.rotation = Vector3(orbit_pitch,yaw,0)
	animate(delta,direction.length()*speed)
	update_weapon_contacts()
	if global_position.y < -15:
		global_position = Vector3(0,2,8)
		motion_epoch += 1

func animate(delta: float, speed: float) -> void:
	if combat.action!=pose_action:
		pose_from = rig.weapon.transform
		pose_action = combat.action
		pose_blend = 0.0
	walk_clock += delta*speed*2.6
	for side in [-1,1]:
		rig.joints["arm"+str(side)].rotation.x = -0.85 if combat.drawn else -sin(walk_clock)*side*minf(speed*0.08,0.3)
	var w: Node3D = rig.weapon
	w.visible = not is_instance_valid(projectile)
	w.position = Vector3(0,1.20,-0.32) if combat.drawn else Vector3(0,1.05,0.26)
	w.rotation = Vector3(-PI/2,0,-0.15) if combat.drawn else Vector3(0,0,0.35)
	if combat.action!="idle":
		var t: float = combat.elapsed
		var p := clampf(t/float(Combat.MOVES[combat.action].duration),0,1)
		match combat.action:
			"light","flash","fourfold":
				var pulse := 0.0
				for hit_time in Combat.MOVES[combat.action].hits:
					pulse = maxf(pulse,exp(-pow((t-float(hit_time))/0.09,2)))
				w.position.z -= pulse*0.15
				w.rotation.x += 0.18+clampf(pitch+0.25,-0.4,0.85)
			"pull":
				# Catch with the backward-facing side teeth, then draw the head toward the hip.
				w.position.z += lerpf(-0.12,0.20,smoothstep(0.22,0.58,t))
				w.rotation.x += 0.12
			"heavy","turn","spin","finisher":
				w.rotation.y = -1.5+p*(TAU if combat.action in ["turn","spin","finisher"] else 3)
				if combat.action in ["heavy","turn"]: w.rotation.x += clampf(pitch+0.25,-0.4,0.85)*1.22
			"guard","reply":
				w.rotation.y = PI if combat.action=="reply" else clampf(t/0.18,0,1)*PI
				w.position.z += 0.55
				if combat.action=="reply": w.position.z -= sin(p*PI)*0.18
			"plant","wait","counter_window":
				w.position = Vector3(0,1.15,-0.35)
				w.rotation = Vector3(0,0,PI)
			"throw": w.visible = t<0.38
	if delta>0:
		pose_blend = minf(1,pose_blend+delta/0.10)
		w.transform = pose_from.interpolate_with(w.transform,smoothstep(0,1,pose_blend))
	for i in ghosts.size(): ghosts[i].visible = i<combat.shadow_lifetimes.size()
	HunterModel.pose_legs(rig,combat.action,combat.elapsed,combat.drawn,walk_clock,speed,delta,foot_ground_height if is_on_floor() else Callable(),foot_ground_normal if is_on_floor() else Callable())
	HunterModel.pose_torso(rig,combat.action,combat.elapsed,walk_clock,speed,delta)
	HunterModel.pose_arms(rig,combat.drawn and not is_instance_valid(projectile),walk_clock)

func foot_ground_height(local_point: Vector3) -> float:
	var hit := foot_ground_sample(local_point)
	return 0.0 if hit.is_empty() else hit.position.y-global_position.y

func foot_ground_normal(local_point: Vector3) -> Vector3:
	var hit := foot_ground_sample(local_point)
	return Vector3.UP if hit.is_empty() else rig.root.global_basis.inverse()*hit.normal

func foot_ground_sample(local_point: Vector3) -> Dictionary:
	var point: Vector3 = rig.root.to_global(local_point)
	point.y = global_position.y
	var probe := PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.5,point-Vector3.UP*0.5,2)
	var hit := get_world_3d().direct_space_state.intersect_ray(probe)
	if hit.is_empty() or hit.normal.y<0.72: return {}
	return hit

func take_damage(amount: float, origin: Vector3, blockable: bool, interrupt := true) -> void:
	var direction := (origin-global_position).normalized()
	var result: String = combat.receive_damage(amount,blockable,direction.dot(-rig.root.global_basis.z)>0.15,interrupt)
	message = {"counter":"反击成功！旋转踢击，不消耗枪影。","guarded":"格挡成功：左键反击，再 Ctrl+左键闪刺。","immune":"免伤","armored":"霸体承伤：动作继续","hurt":"受击！注意预警与站位。"}.get(result,result)
	if result=="ongoing": message = "毒雾持续伤害：离开绿色区域！"
	if result in ["hurt","armored"]: trigger_camera_impact(0.04)
	elif result in ["guarded","counter"]: trigger_camera_impact(0.02)

func trigger_camera_impact(strength: float) -> void:
	shake_time = 0.16
	shake_strength = maxf(shake_strength,strength)

func _process(delta: float) -> void:
	shake_time = maxf(0,shake_time-delta)
	var envelope := shake_time/0.16
	camera.h_offset = sin(shake_time*170)*shake_strength*envelope
	camera.v_offset = cos(shake_time*145)*shake_strength*envelope*0.65
	if shake_time==0: shake_strength = 0

func show_hit_feedback(point: Vector3, result: Dictionary) -> void:
	if not result.get("hit",false): return
	var effect := HitFeedback.new()
	effect.damage = result.damage
	effect.weak = result.weak
	get_parent().add_child(effect)
	effect.global_position = point
	trigger_camera_impact(0.028 if result.weak else 0.014)

func on_strike(_beat: int) -> void:
	var action: String = combat.action
	if action=="throw":
		if is_instance_valid(projectile): return
		var shot := Projectile.new()
		shot.shooter = self
		shot.direction = -rig.root.global_basis.z
		shot.amount = combat.damage()
		projectile = shot
		get_parent().add_child(shot)
		shot.global_position = global_position+Vector3(0,1.1,0)
		shot.look_at(shot.global_position+shot.direction)
		return
	strike_windows.append({"action":action,"beat":_beat,"ends":combat.elapsed+0.12,"previous":weapon_contact_points(action,_beat),"victims":{}})

func weapon_contact_points(action: String, beat: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	if action=="finisher" and beat==1:
		# Use the kicking foot rather than granting another full circular weapon hit.
		points.append(rig.legs[1].ankle.to_global(Vector3(0,-0.025,-0.18)))
	elif action=="reply":
		for label in ["ButtContact","ButtNeckContact"]: points.append(rig.weapon.get_node(label).global_position)
	elif action=="pull":
		for label in ["LeftHookContact","RightHookContact"]: points.append(rig.weapon.get_node(label).global_position)
	else:
		for label in ["TipContact","BladeContact","HeadBaseContact","LeftProngContact","RightProngContact","LeftHookContact","RightHookContact"]: points.append(rig.weapon.get_node(label).global_position)
	return points

func update_weapon_contacts() -> void:
	for window in strike_windows.duplicate():
		if window.action!=combat.action or combat.elapsed>float(window.ends) or combat.health<=0:
			strike_windows.erase(window)
			continue
		var points := weapon_contact_points(window.action,window.beat)
		var previous: PackedVector3Array = window.previous
		if previous.is_empty(): previous = points
		var radius := 0.16 if window.action=="finisher" and window.beat==1 else 0.075
		for m in get_tree().get_nodes_in_group("monsters"):
			if m.health<=0 or window.victims.has(m.get_instance_id()): continue
			var contact := {}
			for index in points.size():
				var candidate := Parts.sweep(m,previous[index],points[index],radius)
				if candidate.is_empty() and index>0: candidate = Parts.sweep(m,points[index-1],points[index],radius)
				if not candidate.is_empty():
					contact = candidate
					break
			if contact.is_empty(): continue
			var query := PhysicsRayQueryParameters3D.create(global_position+Vector3(0,1.15,0),contact.point)
			query.exclude = [get_rid(),m.get_rid()]
			if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
			window.victims[m.get_instance_id()] = true
			var result: Dictionary = m.receive_strike(combat.damage(),global_position,window.action,contact.part)
			if result.hit:
				combat.confirm_hit()
				show_hit_feedback(contact.point,result)
				hit_confirmed.emit(window.action,window.beat,m,result)
				message = ("弱点！ " if result.weak else "命中 ")+str(roundi(result.damage))+" · "+str(result.part)
		window.previous = points

func finish_throw(point: Vector3) -> void:
	projectile = null
	if combat.health<=0 or combat.action=="hurt":
		message = "投掷被打断，武器收回"
		return
	var motion := Vector3(point.x-global_position.x,0,point.z-global_position.z)
	var collision := move_and_collide(motion,true)
	if collision: motion = collision.get_travel()*0.90
	var candidate := global_position+motion
	var probe := PhysicsRayQueryParameters3D.create(candidate+Vector3(0,4,0),candidate-Vector3(0,6,0))
	probe.exclude = [get_rid()]
	probe.collision_mask = 2
	var floor_hit := get_world_3d().direct_space_state.intersect_ray(probe)
	if floor_hit.is_empty() or floor_hit.normal.y<0.72:
		message = "落点悬空或过陡，取消瞬移"
		return
	# Require body clearance above the proposed floor before changing position.
	candidate.y = floor_hit.position.y+0.05
	var body_probe := PhysicsShapeQueryParameters3D.new()
	body_probe.shape = get_child(0).shape
	body_probe.transform = Transform3D(Basis.IDENTITY,candidate+Vector3(0,0.9,0))
	body_probe.exclude = [get_rid()]
	if not get_world_3d().direct_space_state.intersect_shape(body_probe,1).is_empty():
		message = "落点空间不足，取消瞬移"
		return
	global_position = candidate
	motion_epoch += 1
	message = "投掷命中落点，已移至安全位置" if motion.length()>0.5 else "落点受阻，武器收回"
