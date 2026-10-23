extends RefCounted
const V = preload("res://scripts/visuals.gd")
const Skinning = preload("res://scripts/hunter_skin.gd")

static func tapered(parent: Node3D, pos: Vector3, top: float, bottom: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = top
	shape.bottom_radius = bottom
	shape.height = height
	shape.radial_segments = 10
	mesh.mesh = shape
	mesh.material_override = V.mat(color)
	mesh.position = pos
	parent.add_child(mesh)
	return mesh

static func create(parent: Node3D) -> Dictionary:
	var root := V.pivot(parent,"HunterRig",Vector3.ZERO)
	var green := Color("4b5d42")
	var dark := Color("303834")
	var armor := Color("6a756b")
	var skin := Color("b99a7c")
	tapered(root,Vector3(0,1.22,0),0.21,0.16,0.48,dark)
	tapered(root,Vector3(0,0.94,0),0.18,0.21,0.14,Color("765543"))
	var head := V.piece(root,Vector3(0,1.68,0),Vector3(0.29,0.37,0.28),skin,true)
	head.name = "Head"
	V.piece(root,Vector3(0,1.82,0.025),Vector3(0.31,0.20,0.29),Color("262d29"),true)
	V.piece(root,Vector3(0,1.85,0.16),Vector3(0.15,0.16,0.15),Color("262d29"),true)
	for side in [-1,1]:
		V.piece(root,Vector3(side*0.057,1.70,-0.127),Vector3(0.025,0.018,0.018),Color("26302b"),true)
		# Short shoulder cloth panels leave a spine-width equipment channel.
		var cape := tapered(root,Vector3(side*0.19,1.38,0.045),0.12,0.20,0.29,green)
		cape.scale.z = 0.7
		cape.rotation.z = side*0.24
		V.piece(root,Vector3(side*0.23,1.49,0),Vector3(0.16,0.09,0.25),armor,true)
		V.piece(root,Vector3(side*0.13,0.82,0.11),Vector3(0.16,0.27,0.07),Color("7d735e"))
	V.piece(root,Vector3(0.21,1.03,0),Vector3(0.13,0.14,0.09),Color("776b51"))
	V.piece(root,Vector3(0,1.30,0.15),Vector3(0.085,0.33,0.07),armor)
	var joints := {}
	var arms := {}
	var legs := {}
	for side in [-1,1]:
		var shoulder := V.pivot(root,"Arm"+str(side),Vector3(side*0.27,1.43,0))
		var upper := tapered(root,Vector3.ZERO,0.085,0.065,1,dark)
		var lower := tapered(root,Vector3.ZERO,0.065,0.075,1,armor)
		var hand := V.piece(root,Vector3.ZERO,Vector3(0.095,0.12,0.09),skin,true)
		arms[side] = {"shoulder":shoulder,"upper":upper,"lower":lower,"hand":hand}
		joints["arm"+str(side)] = shoulder
		var leg := V.pivot(root,"Leg"+str(side),Vector3(side*0.14,0.89,0))
		var thigh := tapered(leg,Vector3(0,-0.215,0),0.105,0.08,0.43,dark)
		var knee := V.pivot(leg,"Knee",Vector3(0,-0.43,0))
		V.piece(knee,Vector3(0,0,-0.035),Vector3(0.17,0.17,0.16),armor,true)
		var shin := tapered(knee,Vector3(0,-0.18,0),0.08,0.065,0.36,dark)
		V.piece(knee,Vector3(0,-0.17,-0.07),Vector3(0.14,0.26,0.08),armor)
		var ankle := V.pivot(knee,"Ankle",Vector3(0,-0.36,0))
		var boot := V.piece(ankle,Vector3(0,-0.025,-0.06),Vector3(0.18,0.15,0.30),dark,true)
		legs[side] = {"hip":leg,"knee":knee,"ankle":ankle,"thigh":thigh,"shin":shin,"boot":boot}
		joints["leg"+str(side)] = leg
	var rig := {"root":root,"joints":joints,"arms":arms,"legs":legs,"weapon":V.trident(root)}
	rig.weapon.name = "Trident"
	pose_arms(rig,false,0)
	rig.skinning = Skinning.bind(rig)
	if ResourceLoader.exists("res://resources/animations/trident_library.tres"):
		var player := AnimationPlayer.new()
		player.name = "AnimationPreview"
		root.add_child(player)
		player.add_animation_library("",load("res://resources/animations/trident_library.tres"))
	return rig

static func segment(mesh: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var axis := end-start
	mesh.position = (start+end)*0.5
	mesh.quaternion = Quaternion(Vector3.UP,axis.normalized())
	mesh.scale.y = axis.length()

static func pose_arms(rig: Dictionary, armed: bool, gait: float) -> void:
	for side in [-1,1]:
		var arm: Dictionary = rig.arms[side]
		var shoulder: Vector3 = arm.shoulder.position
		var target := shoulder+Vector3(0,-0.66,sin(gait)*side*0.12)
		if armed:
			# Anatomical left stays head-side, right stays butt-side through rotation.
			target = rig.weapon.transform*Vector3(0,0.18 if side==-1 else -0.28,0)
		var offset := target-shoulder
		var distance := offset.length()
		var middle := (shoulder+target)*0.5
		var bend := Vector3(side*0.6,-0.7,0.3)
		var unit := offset.normalized()
		bend = (bend-unit*bend.dot(unit)).normalized()
		var height := sqrt(maxf(0,0.39*0.39-pow(distance*0.5,2)))
		var elbow := middle+bend*height
		segment(arm.upper,shoulder,elbow)
		segment(arm.lower,elbow,target)
		arm.hand.position = target
	Skinning.update(rig)

static func pose_legs(rig: Dictionary, action: String, elapsed: float, armed: bool, gait: float, speed: float, delta: float) -> void:
	var drop := 0.09 if armed else 0.015
	if action in ["guard","reply"]: drop = 0.13
	if action in ["plant","wait","counter_window"]: drop = 0.18
	if action=="dodge": drop = 0.22
	if action=="hurt": drop = 0.16
	var body: Node3D = rig.root
	body.position.y = lerpf(body.position.y,-drop,minf(1,delta*14)) if delta>0 else -drop
	for side in [-1,1]:
		var leg: Dictionary = rig.legs[side]
		var stance := -0.16 if side==-1 else 0.14
		if not armed: stance = 0
		if action in ["guard","reply"]: stance *= 1.4
		var lift := 0.0
		if speed>0.1 and action!="dodge":
			stance = sin(gait)*side*minf(0.28,speed*0.055)
			lift = maxf(0,cos(gait)*side)*minf(0.14,speed*0.025)
		var target := Vector3(leg.hip.position.x,0.10-body.position.y+lift,stance)
		if action=="finisher" and side==1:
			var chamber := smoothstep(0.60,0.80,elapsed)
			var extension := smoothstep(0.80,0.95,elapsed)
			var weight := chamber*(1-smoothstep(1.02,1.32,elapsed))
			target.y += lerpf(0.55,0.62,extension)*weight
			target.z = lerpf(target.z,lerpf(-0.18,-0.72,extension),weight)
		pose_leg(leg,target)

static func pose_leg(leg: Dictionary, target: Vector3) -> void:
	var offset: Vector3 = target-leg.hip.position
	var distance := clampf(Vector2(offset.y,offset.z).length(),0.075,0.7899)
	var angle := atan2(-offset.z,-offset.y)
	var hip_bend := acos(clampf((0.43*0.43+distance*distance-0.36*0.36)/(2*0.43*distance),-1,1))
	leg.hip.rotation.x = angle+hip_bend
	leg.knee.rotation.x = -acos(clampf((distance*distance-0.43*0.43-0.36*0.36)/(2*0.43*0.36),-1,1))
	leg.ankle.rotation.x = -leg.hip.rotation.x-leg.knee.rotation.x
