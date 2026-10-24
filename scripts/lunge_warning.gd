extends MeshInstance3D
const Terrain = preload("res://scripts/forest_terrain.gd")
var start := Vector3.ZERO
var direction := Vector3.FORWARD
var half_width := 1.0
var length := 1.0
func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(0.90,0.62,0.24,0.30)
	material_override = material
	visible = false
func configure(origin: Vector3, forward: Vector3, width: float, distance: float) -> void:
	if mesh!=null and start.distance_squared_to(origin)<0.0001 and direction.distance_squared_to(forward)<0.0001 and is_equal_approx(half_width,width) and is_equal_approx(length,distance): return
	start = origin
	direction = forward
	half_width = width
	length = distance
	var side := Vector3(forward.z,0,-forward.x)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := ceili(distance)
	for step in steps:
		var near := lerpf(-0.32,distance,float(step)/steps)
		var far := lerpf(-0.32,distance,float(step+1)/steps)
		var points := [origin+forward*near-side*width,origin+forward*near+side*width,origin+forward*far-side*width,origin+forward*far+side*width]
		for i in [0,2,1,1,2,3]:
			var point: Vector3 = points[i]
			point.y = Terrain.height_at(point.x,point.z)+0.08
			st.add_vertex(point)
	st.generate_normals()
	mesh = st.commit()
func contains(point: Vector3) -> bool:
	var offset := point-start
	var along := offset.dot(direction)
	var side := Vector3(direction.z,0,-direction.x)
	return along>= -0.32 and along<=length and absf(offset.dot(side))<=half_width
