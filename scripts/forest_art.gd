extends RefCounted
const Terrain = preload("res://scripts/forest_terrain.gd")
static var leaf_spray: ArrayMesh
static var fern_shape: ArrayMesh
static var leaf_material: ShaderMaterial
static var bark_material: ShaderMaterial

static func materials() -> void:
	if leaf_material==null:
		leaf_material = ShaderMaterial.new()
		leaf_material.shader = preload("res://shaders/forest_foliage.gdshader")
		bark_material = ShaderMaterial.new()
		bark_material.shader = preload("res://shaders/forest_bark.gdshader")

static func blade(st: SurfaceTool, start: Vector3, tip: Vector3, width: float, color: Color, wind_weight := 1.0) -> void:
	var direction := (tip-start).normalized()
	var side := Vector3(-direction.z,0,direction.x)*width
	var center := (start+tip)*0.5
	var ridge := center+Vector3.UP*width*0.15
	var points := [start,center+side,tip,center-side,ridge]
	var uv := [Vector2(0.5,0),Vector2(0,0.5),Vector2(0.5,1),Vector2(1,0.5),Vector2(0.5,0.5)]
	for index in [0,3,4,3,2,4,2,1,4,1,0,4]:
		st.set_uv(uv[index])
		st.set_color(Color(color.r,color.g,color.b,uv[index].y*wind_weight))
		st.add_vertex(points[index])

static func leaves() -> ArrayMesh:
	if leaf_spray!=null: return leaf_spray
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in 7:
		var angle := index*TAU/7
		var direction := Vector3(sin(angle),0,cos(angle))
		blade(st,direction*0.06,direction*(0.60+0.10*sin(index*7))+Vector3.UP*0.08,0.14,Color("405e32").lightened((index%3)*0.025))
	st.generate_normals()
	leaf_spray = st.commit()
	return leaf_spray

static func fern() -> ArrayMesh:
	if fern_shape!=null: return fern_shape
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for frond in 7:
		var angle := frond*TAU/7
		var direction := Vector3(sin(angle),0,cos(angle))
		var side := Vector3(-direction.z,0,direction.x)
		var previous := Vector3.ZERO
		for row in range(1,8):
			var t := row/8.0
			var center := direction*t*0.75+Vector3.UP*(sin(t*PI*0.7)*0.53)
			blade(st,previous,center,0.008,Color("49602e"),0.0)
			previous = center
			for sign in [-1,1]:
				var tip: Vector3 = center+side*sign*(1-t)*0.25+direction*0.10
				blade(st,center,tip,0.035,Color("456b37").lightened(t*0.08))
	st.generate_normals()
	fern_shape = st.commit()
	return fern_shape

static func tree(parent: Node3D, position: Vector3, height: float, seed_value: int) -> Node3D:
	materials()
	var root := Node3D.new()
	root.name = "BroadleafTree"
	root.position = position
	root.set_meta("trunk_height",height)
	root.add_to_group("forest_trees")
	parent.add_child(root)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var segments := 12
	for row in 7:
		for column in segments:
			var vertices := []
			for pair in [[row,column],[row+1,column],[row,column+1],[row+1,column+1]]:
				var t: float = float(pair[0])/7
				var angle: float = float(pair[1])/segments*TAU
				var radius := lerpf(0.31,0.055,t)
				vertices.append(Vector3(sin(angle)*radius+sin(t*2+seed_value)*t*0.11,t*height,cos(angle)*radius))
			for index in [0,1,2,2,1,3]:
				var vertex: Vector3 = vertices[index]
				st.set_uv(Vector2(float(column+(1 if index in [2,3] else 0))/segments,vertex.y/height))
				st.add_vertex(vertex)
	st.generate_normals()
	var trunk := MeshInstance3D.new()
	trunk.name = "TrunkSurface"
	trunk.mesh = st.commit()
	trunk.material_override = bark_material
	root.add_child(trunk)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value*739+41
	var centers: Array[Vector3] = []
	for index in 5:
		var angle := index*TAU/5+rng.randf_range(-0.3,0.3)
		var end := Vector3(sin(angle)*1.45,height*0.86+rng.randf_range(-0.5,0.9),cos(angle)*1.45)
		centers.append(end)
		var begin := Vector3(0,height*0.67,0)
		var branch := MeshInstance3D.new()
		var shape := CylinderMesh.new()
		shape.top_radius = 0.025
		shape.bottom_radius = 0.075
		shape.height = begin.distance_to(end)
		shape.radial_segments = 8
		branch.mesh = shape
		branch.position = (begin+end)*0.5
		branch.quaternion = Quaternion(Vector3.UP,(end-begin).normalized())
		branch.material_override = bark_material
		root.add_child(branch)
	var canopy := MultiMeshInstance3D.new()
	canopy.name = "LeafCanopy"
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = leaves()
	instances.instance_count = 180
	for index in instances.instance_count:
		var center := centers[index%5]+Vector3(rng.randf_range(-0.95,0.95),rng.randf_range(-0.7,0.8),rng.randf_range(-0.95,0.95))
		var basis := Basis.from_euler(Vector3(rng.randf_range(-0.8,0.8),rng.randf_range(0,TAU),rng.randf_range(-0.6,0.6))).scaled(Vector3.ONE*rng.randf_range(0.65,1.1))
		instances.set_instance_transform(index,Transform3D(basis,center))
		var tint := rng.randf_range(0.82,1.12)
		instances.set_instance_color(index,Color(tint,tint,0.96*tint,1))
	canopy.multimesh = instances
	canopy.material_override = leaf_material
	root.add_child(canopy)
	return root

static func clear_for_fern(position: Vector3) -> bool:
	if absf(position.x)<8 or absf(position.x-41)<2: return false
	for center in Terrain.CLEARINGS:
		if Vector2(position.x,position.z).distance_to(center)<10: return false
	return true

static func understory(parent: Node3D, original: Array[Vector3]) -> MultiMeshInstance3D:
	materials()
	var rng := RandomNumberGenerator.new()
	rng.seed = 69621
	var positions: Array[Vector3] = []
	for point in original:
		if clear_for_fern(point): positions.append(point)
	for index in 320:
		var point := Vector3(rng.randf_range(-56,56),0,rng.randf_range(-56,56))
		if clear_for_fern(point):
			point.y = Terrain.height_at(point.x,point.z)
			positions.append(point)
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = fern()
	instances.instance_count = positions.size()
	for index in positions.size():
		var p := positions[index]
		var dx := Terrain.height_at(p.x+0.1,p.z)-Terrain.height_at(p.x-0.1,p.z)
		var dz := Terrain.height_at(p.x,p.z+0.1)-Terrain.height_at(p.x,p.z-0.1)
		var normal := Vector3(-dx,0.2,-dz).normalized()
		var basis := Basis(Quaternion(Vector3.UP,normal))*Basis(Vector3.UP,rng.randf_range(0,TAU))
		basis = basis.scaled(Vector3.ONE*rng.randf_range(0.75,1.2))
		instances.set_instance_transform(index,Transform3D(basis,p))
		var tint := rng.randf_range(0.8,1.1)
		instances.set_instance_color(index,Color(tint,tint,tint,1))
	var node := MultiMeshInstance3D.new()
	node.name = "FernUnderstory"
	node.set_meta("root_positions",PackedVector3Array(positions))
	node.multimesh = instances
	node.material_override = leaf_material
	node.add_to_group("forest_understory")
	parent.add_child(node)
	return node

static func cliffs(parent: Node3D) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in 4:
		for column in range(-15,15):
			for row in 4:
				var points: Array[Vector3] = []
				for pair in [[column,row],[column+1,row],[column,row+1],[column+1,row+1]]:
					var u: float = pair[0]*4.0
					var level: int = pair[1]
					var distance: float = [0.0,0.3,5.0,15.0,35.0][level]
					var x := 59.5+distance
					var height := 8.5+sin(u*0.18+side)*1.4+sin(u*0.49)*0.6
					if level==2: height += 2.0
					if level==3: height += 4.0+sin(u*0.09)*3
					if level==4: height += sin(u*0.12)*4
					var position := Vector3(x,height,u).rotated(Vector3.UP,side*PI/2)
					if level==0: position.y = Terrain.height_at(position.x,position.z)-0.05
					points.append(position)
				for index in [0,2,1,1,2,3]: st.add_vertex(points[index])
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = "BoundaryCliffs"
	mesh.mesh = st.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/forest_cliff.gdshader")
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.add_to_group("forest_backdrop")
	return mesh

static func rock(parent: Node3D, size: Vector3) -> MeshInstance3D:
	var source := SphereMesh.new()
	source.radial_segments = 10
	source.rings = 5
	var arrays: Array = source.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in indices:
		var v := vertices[index]
		for axis in 3: v[axis] = signf(v[axis])*pow(absf(v[axis])*2,0.55)*0.5*size[axis]
		var tint := 0.5+sin(v.x*4+v.y*3+v.z*5)*0.13
		st.set_color(Color("4c594c").lerp(Color("74806a"),tint))
		st.add_vertex(v)
	st.generate_normals()
	var result := MeshInstance3D.new()
	result.name = "MossRock"
	result.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.64
	result.material_override = material
	parent.add_child(result)
	return result
