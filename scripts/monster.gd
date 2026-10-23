extends CharacterBody3D
const Visuals = preload("res://scripts/visuals.gd")
const Hazard = preload("res://scripts/hazard.gd")
var data: Dictionary
var target: CharacterBody3D
var health := 0.0
var phase := "idle"
var clock := 0.0
var stagger := 0.0
var target_point := Vector3.ZERO
var mesh: Node3D
var tell: MeshInstance3D
var label: Label3D
var attack_done := false
var disrupted := 0.0
var exposed := 0.0

func _ready() -> void:
	collision_mask = 3
	health = float(data.health)
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = float(data.size)*0.34
	shape.height = float(data.size)*1.1
	collider.shape = shape
	collider.position.y = shape.height/2
	add_child(collider)
	mesh = Visuals.creature(self,data)
	tell = Visuals.piece(self,Vector3(0,0.05,0),Vector3(float(data.reach)*1.8,0.025,float(data.reach)*1.8),Color("b48848"),true)
	tell.visible = false
	label = Label3D.new()
	label.position.y = float(data.size)*1.5
	label.font_size = 42
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	add_to_group("monsters")

func _physics_process(delta: float) -> void:
	if health <= 0:
		mesh.rotation.z = lerpf(mesh.rotation.z,1.35,delta*3)
		tell.visible = false
		label.text = str(data.name)+" 已击退"
		return
	label.text = "%s  %d/%d\n%s" % [data.name,ceili(health),int(data.health),data.weakness]
	stagger = maxf(0,stagger-delta)
	exposed = maxf(0,exposed-delta)
	if not is_on_floor(): velocity.y -= 25*delta
	if stagger > 0:
		phase = "recover"
		clock = 0
		tell.visible = false
		velocity.x = move_toward(velocity.x,0,8*delta)
		velocity.z = move_toward(velocity.z,0,8*delta)
		move_and_slide()
		return
	if not is_instance_valid(target): return
	var offset := target.global_position-global_position
	offset.y = 0
	var distance := offset.length()
	clock += delta
	velocity.x = 0
	velocity.z = 0
	if phase == "idle":
		if distance < 20 and target.combat.health > 0:
			if distance > float(data.reach)*0.82:
				rotation.y = lerp_angle(rotation.y,atan2(-offset.x,-offset.z),delta*2.5)
				velocity += offset.normalized()*float(data.speed)
			else:
				phase = "windup"
				clock = 0
				target_point = target.global_position
				attack_done = false
	elif phase == "windup":
		tell.visible = true
		tell.material_override = Visuals.mat(Color("71cce4") if data.pattern=="pulse" else (Color("93ae55") if data.pattern=="mist" else Color("c39a55")))
		if clock < float(data.windup)*0.7:
			target_point = target.global_position
			rotation.y = lerp_angle(rotation.y,atan2(-offset.x,-offset.z),delta*2)
		mesh.rotation.x = sin(clock*12)*0.05
		if clock >= float(data.windup):
			phase = "active"
			clock = 0
	elif phase == "active":
		if data.pattern=="mist" and not attack_done:
			attack_done = true
			spawn_hazard(target_point,4.0,6.0,9.0,"mist")
		elif data.pattern=="pulse" and not attack_done:
			attack_done = true
			spawn_hazard(global_position,float(data.reach),0.7,float(data.damage),"pulse")
		if data.pattern in ["charge","leap"]:
			var direction := (target_point-global_position).normalized()
			direction.y = 0
			velocity += direction*(13 if data.pattern == "charge" else 10)
		if not attack_done:
			var forward := offset.normalized().dot(-global_basis.z)>-0.15
			if distance < float(data.reach) and forward and (data.pattern not in ["charge","leap"] or distance < 3.8):
				attack_done = true
				target.take_damage(float(data.damage),global_position,data.pattern not in ["mist","pulse"])
		if clock > 0.65:
			phase = "recover"
			clock = 0
			tell.visible = false
			exposed = float(data.recovery)
	elif phase == "recover":
		mesh.rotation.x = lerpf(mesh.rotation.x,0,delta*6)
		if clock >= float(data.recovery):
			phase = "idle"
			clock = 0
	move_and_slide()

func spawn_hazard(point: Vector3, radius: float, duration: float, amount: float, kind: String) -> void:
	var hazard := Hazard.new()
	hazard.target = target
	hazard.radius = radius
	hazard.lifetime = duration
	hazard.damage = amount
	hazard.kind = kind
	hazard.interval = 0.8 if kind=="mist" else 2.0
	get_parent().add_child(hazard)
	hazard.global_position = Vector3(point.x,preload("res://scripts/forest_terrain.gd").height_at(point.x,point.z)+0.05,point.z)

func receive_strike(amount: float, origin: Vector3, action: String) -> Dictionary:
	if health <= 0: return {"hit":false}
	var toward := (origin-global_position).normalized()
	var dot_front := toward.dot(-global_basis.z)
	var weak: bool = (data.weak_side == "rear" and dot_front < -0.3) or (data.weak_side == "flank" and absf(dot_front)<0.65 and exposed>0) or (data.weak_side == "front" and dot_front>0.2 and phase=="windup")
	var factor := float(data.weak_multiplier) if weak else (float(data.front_armor) if dot_front > 0.4 else 1.0)
	health = maxf(0,health-amount*factor)
	if weak and data.id == "mistfrill" and phase == "windup": stagger = 1.8
	if weak and data.id == "stormcrest" and phase == "windup":
		disrupted += amount
		if disrupted >= 90:
			stagger = 2.5
			disrupted = 0
	if action in ["spin","finisher"]:
		stagger = 1.3 if action=="spin" else 2.2
		velocity.y = 4.0
		velocity += -toward*4
	elif action == "pull":
		velocity += toward*4
		stagger = maxf(stagger,0.30)
	elif action == "reply": stagger = maxf(stagger,0.45)
	return {"hit":true,"weak":weak,"damage":amount*factor}
