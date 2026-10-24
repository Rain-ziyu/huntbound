extends RefCounted
## Single skinned hand piece: palm, four curled digits and opposing thumb.
static func create(parent: Node3D, side: int) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var palm := SphereMesh.new()
	palm.radial_segments = 16
	palm.rings = 8
	palm.radius = 0.5
	palm.height = 1
	var arrays := palm.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for index in indices:
		st.set_color(Color("485247"))
		st.add_vertex(points[index]*Vector3(0.045,0.10,0.065)+Vector3(0.057,0,0))
	for digit in 4:
		var path: Array[Vector3] = []
		for step in 13:
			var angle := lerpf(-0.55,4.0,float(step)/12)
			path.append(Vector3(cos(angle)*0.043,(digit-1.5)*0.023,sin(angle)*0.043))
		tube(st,path,0.010,Color("6d7566"))
	var thumb: Array[Vector3] = [Vector3(0.057,-0.047,0.018),Vector3(0.035,-0.058,0.040),Vector3(0,-0.055,0.047),Vector3(-0.034,-0.043,0.030)]
	if side==1:
		for i in thumb.size(): thumb[i].y = -thumb[i].y
	tube(st,thumb,0.012,Color("57614f"))
	st.generate_normals()
	var hand := MeshInstance3D.new()
	hand.name = "GripHandLeft" if side==-1 else "GripHandRight"
	hand.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.94
	hand.material_override = material
	parent.add_child(hand)
	return hand
static func tube(st: SurfaceTool, path: Array[Vector3], radius: float, color: Color) -> void:
	var rings: Array[PackedVector3Array] = []
	for i in path.size():
		var tangent := (path[mini(i+1,path.size()-1)]-path[maxi(i-1,0)]).normalized()
		var u := tangent.cross(Vector3.UP).normalized()
		var v := tangent.cross(u).normalized()
		var ring := PackedVector3Array()
		for j in 10: ring.append(path[i]+radius*(u*cos(TAU*j/10)+v*sin(TAU*j/10)))
		rings.append(ring)
	for i in path.size()-1:
		for j in 10:
			var k := (j+1)%10
			for point in [rings[i][j],rings[i][k],rings[i+1][j],rings[i][k],rings[i+1][k],rings[i+1][j]]:
				st.set_color(color)
				st.add_vertex(point)
	for row in [0,path.size()-1]:
		for j in 10:
			var k := (j+1)%10
			for point in ([path[row],rings[row][k],rings[row][j]] if row==0 else [path[row],rings[row][j],rings[row][k]]):
				st.set_color(color)
				st.add_vertex(point)
static func orient(hand: MeshInstance3D, elbow: Vector3, grip_axis: Vector3) -> void:
	var y := grip_axis.normalized()
	var x := elbow-hand.position
	x = (x-y*x.dot(y)).normalized()
	if x.length_squared()<0.01: x = y.cross(Vector3.FORWARD).normalized()
	if x.length_squared()<0.01: x = y.cross(Vector3.RIGHT).normalized()
	hand.basis = Basis(x,y,x.cross(y)).orthonormalized()
