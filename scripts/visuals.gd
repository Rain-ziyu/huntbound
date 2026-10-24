extends RefCounted
## Articulated procedural mesh blockout. Final costume meshes remain a separate deliverable.
static func mat(color: Color, glow := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.65
	if glow:
		m.emission_enabled = true
		m.emission = color
	return m

static func piece(parent: Node3D, pos: Vector3, size: Vector3, color: Color, round_shape := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	if round_shape:
		var shape := SphereMesh.new()
		shape.radial_segments = 12
		shape.rings = 6
		mesh.mesh = shape
	else: mesh.mesh = BoxMesh.new()
	mesh.scale = size
	mesh.position = pos
	mesh.material_override = mat(color)
	parent.add_child(mesh)
	return mesh

static func pivot(parent: Node3D, label: String, pos: Vector3) -> Node3D:
	var p := Node3D.new()
	p.name = label
	p.position = pos
	parent.add_child(p)
	return p

static func trident(parent: Node3D, spectral := false) -> Node3D:
	return preload("res://scripts/trident_mesh.gd").create(parent,spectral)

static func hunter(parent: Node3D) -> Dictionary:
	var root := pivot(parent,"HunterRig",Vector3.ZERO)
	piece(root,Vector3(0,1.22,0),Vector3(0.42,0.54,0.24),Color("343f37"))
	piece(root,Vector3(0,1.72,0),Vector3(0.29,0.36,0.29),Color("b89b7f"),true)
	piece(root,Vector3(0,1.86,0.025),Vector3(0.31,0.16,0.30),Color("252a26"),true)
	# Two short independent cape panels; no cloth over the central draw channel.
	for side in [-1,1]:
		var cape := piece(root,Vector3(side*0.20,1.38,0.12),Vector3(0.24,0.32,0.12),Color("526046"))
		cape.rotation.z = side * 0.24
		piece(root,Vector3(side*0.19,0.89,0.08),Vector3(0.19,0.30,0.14),Color("726956"))
	piece(root,Vector3(0,0.95,0),Vector3(0.45,0.08,0.28),Color("714235"))
	var joints := {}
	for side in [-1,1]:
		var arm := pivot(root,"Arm"+str(side),Vector3(side*0.30,1.43,0))
		piece(arm,Vector3(0,-0.23,0),Vector3(0.14,0.46,0.15),Color("6b756d"))
		piece(arm,Vector3(0,-0.50,-0.06),Vector3(0.12,0.14,0.12),Color("b89b7f"),true)
		var leg := pivot(root,"Leg"+str(side),Vector3(side*0.13,0.88,0))
		piece(leg,Vector3(0,-0.35,0),Vector3(0.19,0.70,0.20),Color("333a36"))
		piece(leg,Vector3(0,-0.57,-0.08),Vector3(0.21,0.27,0.10),Color("647269"))
		piece(leg,Vector3(0,-0.82,-0.06),Vector3(0.22,0.14,0.33),Color("333833"))
		joints["arm"+str(side)] = arm
		joints["leg"+str(side)] = leg
	var weapon := trident(root)
	return {"root":root,"joints":joints,"weapon":weapon}

static func creature(parent: Node3D, data: Dictionary) -> Node3D:
	var root := pivot(parent,"CreatureMesh",Vector3.ZERO)
	var s: float = data.size
	var c := Color(data.color)
	var quad: bool = "quadruped" in data.body
	piece(root,Vector3(0,s*0.58,0),Vector3(s*0.70,s*0.58,s*1.15),c,true)
	piece(root,Vector3(0,s*0.74,-s*0.67),Vector3(s*0.44,s*0.40,s*0.54),c.lightened(0.18),true)
	for side in [-1,1]:
		piece(root,Vector3(side*s*0.15,s*0.82,-s*0.88),Vector3(0.12,0.12,0.12),Color("e7b46a"),true)
		for z in ([s*0.34,-s*0.38] if quad else [s*0.24]):
			piece(root,Vector3(side*s*0.28,s*0.24,z),Vector3(s*0.22,s*0.48,s*0.23),c.darkened(0.2))
	var tail := piece(root,Vector3(0,s*0.5,s*0.90),Vector3(s*0.19,s*0.16,s*0.85),c)
	tail.rotation.x = -0.12
	if data.id == "mossback":
		for i in 4: piece(root,Vector3(0,s*0.88,(i-1.5)*s*0.22),Vector3(s*0.66,s*0.13,s*0.20),c.darkened(0.25))
	elif data.id == "thornhorn":
		for side in [-1,1]:
			var horn := piece(root,Vector3(side*s*0.22,s*0.94,-s*0.86),Vector3(0.12,s*0.42,0.12),Color("c1b18b"))
			horn.rotation.x = -0.65
	elif data.id == "mistfrill":
		piece(root,Vector3(0,s*0.90,-s*0.45),Vector3(s*0.9,s*0.70,0.15),c.lightened(0.3),true)
	elif data.id == "stormcrest":
		for i in 5:
			piece(root,Vector3(0,s*1.0,(i-2)*s*0.18),Vector3(0.14,s*0.40,0.25),Color("8cd5c6"))
	return root
