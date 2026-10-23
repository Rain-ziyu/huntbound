extends RefCounted
const V = preload("res://scripts/visuals.gd")
const H = preload("res://scripts/hunter_model.gd")

static func create(parent: Node3D, data: Dictionary) -> Node3D:
	var root := V.pivot(parent,"CreatureMesh",Vector3.ZERO)
	var s: float = data.size
	var c := Color(data.color)
	var quad: bool = "quadruped" in data.body
	var y := s*0.50 if quad else s*0.64
	V.piece(root,Vector3(0,y,0),Vector3(s*0.75,s*0.55,s*1.1),c,true)
	var neck := V.pivot(root,"Neck",Vector3(0,y,-s*0.40))
	V.piece(neck,Vector3(0,s*0.08,-s*0.13),Vector3(s*0.34,s*0.38,s*0.55),c,true)
	V.piece(neck,Vector3(0,s*0.14,-s*0.40),Vector3(s*0.40,s*0.32,s*0.52),c.lightened(0.1),true)
	V.piece(neck,Vector3(0,0,-s*0.49),Vector3(s*0.32,s*0.10,s*0.34),c.darkened(0.2),true)
	for side in [-1,1]:
		V.piece(neck,Vector3(side*s*0.19,s*0.18,-s*0.48),Vector3(0.11,0.10,0.11),Color("dba75d"),true)
		for front in ([false,true] if quad else [false]):
			var leg := V.pivot(root,("Front" if front else "Hind")+str(side),Vector3(side*s*0.29,y*0.9,-s*0.31 if front else s*0.28))
			H.tapered(leg,Vector3(0,-s*0.14,0),s*0.13,s*0.09,s*0.34,c.darkened(0.15))
			V.piece(leg,Vector3(0,-s*0.29,s*0.04),Vector3(s*0.19,s*0.18,s*0.20),c,true)
			H.tapered(leg,Vector3(0,-s*0.37,s*0.03),s*0.085,s*0.06,s*0.25,c)
			V.piece(leg,Vector3(0,-y*0.86,-s*0.10),Vector3(s*0.21,s*0.10,s*0.35),c.darkened(0.25),true)
		if not quad:
			V.piece(root,Vector3(side*s*0.28,y,-s*0.39),Vector3(s*0.12,s*0.30,s*0.16),c)
	var tail := V.pivot(root,"Tail",Vector3(0,y*0.85,s*0.45))
	for i in 5:
		var width := s*(0.24-i*0.037)
		V.piece(tail,Vector3(0,-s*i*0.015,s*i*0.20),Vector3(width,width,s*0.30),c,true)
	if data.id=="mossback":
		for i in 5:
			var plate := V.piece(root,Vector3(0,y+s*0.27,(i-2)*s*0.18),Vector3(s*0.70,s*0.16,s*0.22),c.darkened(0.28),true)
			plate.name = "ArmorPlate"+str(i)
	elif data.id=="thornhorn":
		for side in [-1,1]:
			var horn := H.tapered(neck,Vector3(side*s*0.17,s*0.43,-s*0.36),0.005,s*0.065,s*0.46,Color("c4b89a"))
			horn.rotation.x = -0.55
	elif data.id=="mistfrill":
		V.piece(neck,Vector3(0,s*0.24,0),Vector3(s*0.92,s*0.65,0.12),c.lightened(0.2),true)
	elif data.id=="reedclaw":
		for side in [-1,1]:
			V.piece(root,Vector3(side*s*0.29,y*0.12,-s*0.15),Vector3(s*0.08,s*0.15,s*0.35),Color("b6ba9b"))
	elif data.id=="stormcrest":
		for i in 5:
			H.tapered(root,Vector3(0,y+s*0.35,(i-2)*s*0.18),0.005,s*0.06,s*0.52,Color("78b9b5"))
	return root

static func animate(root: Node3D, data: Dictionary, gait: float, phase: String, clock: float, speed: float) -> void:
	for side in [-1,1]:
		for label in ["Front","Hind"]:
			var leg := root.get_node_or_null(label+str(side)) as Node3D
			if leg:
				var offset := PI if label=="Front" else 0.0
				leg.rotation.x = sin(gait+offset)*side*minf(0.45,speed*0.08)
	var tail := root.get_node("Tail") as Node3D
	tail.rotation.y = sin(gait*0.5)*0.12
	var neck := root.get_node("Neck") as Node3D
	neck.rotation.x = 0
	neck.rotation.y = 0
	if phase=="windup":
		var fraction := clampf(clock/float(data.windup),0,1)
		neck.rotation.x = (0.35 if data.pattern=="charge" else -0.20)*fraction
		root.position.y = -0.45*smoothstep(0,0.4,clock) if data.pattern=="pulse" else 0.0
	elif phase=="active":
		if data.pattern=="pulse": root.position.y = -0.45*(1-smoothstep(0,0.3,clock))
		if data.pattern=="sweep": neck.rotation.y = sin(clock/0.65*PI)*0.8
		if data.pattern=="leap": root.position.y = sin(clampf(clock/0.65,0,1)*PI)*1.0
	else: root.position.y = 0
	# Keep planted limb roots at their standing height while the charging torso lowers.
	var hip_height := float(data.size)*(0.50 if "quadruped" in data.body else 0.64)*0.9
	for side in [-1,1]:
		for label in ["Front","Hind"]:
			var leg := root.get_node_or_null(label+str(side)) as Node3D
			if leg: leg.position.y = hip_height-minf(root.position.y,0)
