extends CharacterBody3D
const Visuals = preload("res://scripts/visuals.gd")
const Hazard = preload("res://scripts/hazard.gd")
const CreatureModel = preload("res://scripts/creature_model.gd")
const Parts = preload("res://scripts/monster_parts.gd")
var armor_integrity := 200.0
var route := PackedVector3Array()
var route_time := 0.0
var gait := 0.0
var weak_marker: MeshInstance3D
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
var impact_time := 0.0
var impact_material: StandardMaterial3D
var impact_meshes: Array[MeshInstance3D] = []

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
	mesh = CreatureModel.create(self,data)
	impact_material = Visuals.mat(Color.WHITE,true)
	impact_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	impact_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for part in mesh.find_children("*","MeshInstance3D",true,false): impact_meshes.append(part)
	var s: float = data.size
	var marker_pos := Vector3(0,s*0.58,s*0.48)
	if data.id=="stormcrest": marker_pos = Vector3(0,s*1.12,s*0.15)
	if data.weak_side=="front": marker_pos = Vector3(0,s*0.78,-s*0.70)
	elif data.weak_side=="flank": marker_pos = Vector3(s*0.37,s*0.58,0)
	weak_marker = Visuals.piece(mesh,marker_pos,Vector3(0.22,0.22,0.22),Color("e6c57c"),true)
	weak_marker.material_override = Visuals.mat(Color("e6c57c"),true)
	tell = Visuals.piece(self,Vector3(0,0.05,0),Vector3(float(data.reach)*2,0.025,float(data.reach)*2),Color("b48848"),true)
	tell.visible = false
	label = Label3D.new()
	label.position.y = float(data.size)*1.5
	label.font_size = 42
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	add_to_group("monsters")

func show_impact(weak: bool) -> void:
	impact_time = 0.12
	impact_material.albedo_color = Color(1.0,0.77,0.30,0.32) if weak else Color(0.58,0.95,0.88,0.24)
	impact_material.emission = impact_material.albedo_color
	for part in impact_meshes: part.material_overlay = impact_material

func _process(delta: float) -> void:
	if impact_time<=0: return
	impact_time = maxf(0,impact_time-delta)
	impact_material.albedo_color.a = minf(impact_material.albedo_color.a,impact_time*2.7)
	if impact_time==0:
		for part in impact_meshes: part.material_overlay = null

func _physics_process(delta: float) -> void:
	if health <= 0:
		collision_layer = 0
		collision_mask = 0
		weak_marker.visible = false
		mesh.rotation.z = lerpf(mesh.rotation.z,1.35,delta*3)
		tell.visible = false
		label.text = str(data.name)+" 已击退"
		return
	label.text = "%s  %d/%d\n%s" % [data.name,ceili(health),int(data.health),data.weakness]
	weak_marker.visible = data.weak_side=="rear" or (data.weak_side=="front" and phase=="windup") or (data.weak_side=="flank" and exposed>0)
	if data.id=="stormcrest": weak_marker.visible = phase=="windup"
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
	if target.combat.health<=0:
		phase = "idle"
		tell.visible = false
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return
	var offset := target.global_position-global_position
	offset.y = 0
	var distance := offset.length()
	clock += delta
	route_time -= delta
	velocity.x = 0
	velocity.z = 0
	if phase == "idle":
		if distance < 20 and target.combat.health > 0:
			if distance > float(data.reach)*0.82 or not clear_line_to(target.global_position):
				if route_time<=0:
					route = get_parent().navigation.path(global_position,target.global_position,float(data.size)*0.34)
					route_time = 0.6
				while not route.is_empty() and Vector2(route[0].x-global_position.x,route[0].z-global_position.z).length()<0.75: route.remove_at(0)
				var chase := Vector3.ZERO
				if not route.is_empty():
					chase = route[0]-global_position
					chase.y = 0
					chase = chase.normalized()
				rotation.y = lerp_angle(rotation.y,atan2(-chase.x,-chase.z),delta*2.5)
				velocity += chase*float(data.speed)
			else:
				phase = "windup"
				clock = 0
				target_point = target.global_position
				attack_done = false
				disrupted = 0
	elif phase == "windup":
		tell.visible = true
		tell.material_override.albedo_color = Color("71cce4") if data.pattern=="pulse" else (Color("93ae55") if data.pattern=="mist" else Color("c39a55"))
		if clock < float(data.windup)*0.7:
			target_point = target.global_position
			rotation.y = lerp_angle(rotation.y,atan2(-offset.x,-offset.z),delta*2)
		if data.pattern=="mist":
			tell.scale = Vector3(8,0.025,8)
			tell.global_position = Vector3(target_point.x,preload("res://scripts/forest_terrain.gd").height_at(target_point.x,target_point.z)+0.08,target_point.z)
		mesh.rotation.x = sin(clock*12)*0.05
		if clock >= float(data.windup):
			phase = "active"
			clock = 0
	elif phase == "active":
		if data.pattern=="mist" and not attack_done:
			attack_done = true
			if clear_line_to(target_point): spawn_hazard(target_point,4.0,6.0,9.0,"mist")
		elif data.pattern=="pulse" and not attack_done:
			attack_done = true
			spawn_hazard(global_position,float(data.reach),0.7,float(data.damage),"pulse")
		if data.pattern in ["charge","leap"]:
			var direction := (target_point-global_position).normalized()
			direction.y = 0
			velocity += direction*(13 if data.pattern == "charge" else 10)
		if not attack_done:
			var forward := offset.normalized().dot(-global_basis.z)>-0.15
			if distance < float(data.reach) and forward and clear_line_to(target.global_position) and (data.pattern not in ["charge","leap"] or distance < 3.8):
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
	gait += delta*Vector2(velocity.x,velocity.z).length()*1.7
	CreatureModel.animate(mesh,data,gait,phase,clock,Vector2(velocity.x,velocity.z).length())

func spawn_hazard(point: Vector3, radius: float, duration: float, amount: float, kind: String) -> void:
	var hazard := Hazard.new()
	hazard.target = target
	hazard.source_actor = self
	hazard.radius = radius
	hazard.lifetime = duration
	hazard.damage = amount
	hazard.kind = kind
	hazard.interval = 0.8 if kind=="mist" else 2.0
	get_parent().add_child(hazard)
	hazard.global_position = Vector3(point.x,preload("res://scripts/forest_terrain.gd").height_at(point.x,point.z)+0.05,point.z)

func clear_line_to(point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,point+Vector3.UP)
	query.exclude = [get_rid(),target.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func receive_strike(amount: float, origin: Vector3, action: String, part := "") -> Dictionary:
	if health <= 0: return {"hit":false}
	var toward := (origin-global_position).normalized()
	var dot_front := toward.dot(-global_basis.z)
	var weak: bool = (data.weak_side == "rear" and dot_front < -0.3) or (data.weak_side == "flank" and absf(dot_front)<0.65 and exposed>0) or (data.weak_side == "front" and dot_front>0.2 and phase=="windup")
	if part!="":
		weak = (data.weak_side=="rear" and part=="tail") or (data.weak_side=="flank" and part=="flank" and exposed>0) or (data.weak_side=="front" and part=="head" and phase=="windup")
		if data.id=="stormcrest": weak = part=="spine" and phase=="windup"
	var factor := float(data.weak_multiplier) if weak else (float(data.front_armor) if dot_front > 0.4 and armor_integrity>0 else 1.0)
	if data.id=="mossback" and part=="body": armor_integrity = maxf(0,armor_integrity-amount)
	if data.id=="mossback" and armor_integrity<=0:
		for i in 5:
			var plate := mesh.get_node_or_null("ArmorPlate"+str(i)) as MeshInstance3D
			if plate: plate.visible = false
	health = maxf(0,health-amount*factor)
	show_impact(weak)
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
	elif action == "reply":
		velocity += -toward*5
		stagger = maxf(stagger,0.45)
	return {"hit":true,"weak":weak,"damage":amount*factor,"part":part if part!="" else "legacy-direction","armor_broken":armor_integrity<=0}
