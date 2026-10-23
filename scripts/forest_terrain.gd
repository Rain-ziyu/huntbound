extends Node3D
const Visuals = preload("res://scripts/visuals.gd")
const CLEARINGS := [Vector2(0,-16),Vector2(-26,-22),Vector2(26,-22),Vector2(-25,24),Vector2(25,24)]
const HALF := 60
const STEP := 2
var terrain_body: StaticBody3D

static func height_at(x: float, z: float) -> float:
	var height := 1.8+sin(x*0.10)*cos(z*0.08)*1.3+sin(z*0.19+x*0.04)*0.4
	var blend := smoothstep(6,13,absf(x))
	for center in CLEARINGS:
		blend = minf(blend,smoothstep(9,16,Vector2(x,z).distance_to(center)))
	height *= blend
	var river := 1.0-smoothstep(1.8,5.0,absf(x-41))
	return lerpf(height,-0.45,river)

func _ready() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-HALF,HALF,STEP):
		for x in range(-HALF,HALF,STEP):
			var a := Vector3(x,height_at(x,z),z)
			var b := Vector3(x+STEP,height_at(x+STEP,z),z)
			var c := Vector3(x,height_at(x,z+STEP),z+STEP)
			var d := Vector3(x+STEP,height_at(x+STEP,z+STEP),z+STEP)
			for point in [a,b,c,b,d,c]:
				var moss := 0.5+sin(point.x*0.38+point.z*0.23)*0.18
				var color := Color("344d39").lerp(Color("64734d"),moss)
				if absf(point.x)<6: color = Color("4a5141")
				if absf(point.x-41)<4: color = Color("4a514c")
				surface.set_color(color)
				surface.add_vertex(point)
	surface.generate_normals()
	var ground := MeshInstance3D.new()
	ground.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.72
	ground.material_override = material
	add_child(ground)
	terrain_body = StaticBody3D.new()
	terrain_body.name = "TerrainCollision"
	terrain_body.collision_layer = 2
	var collision := CollisionShape3D.new()
	collision.shape = ground.mesh.create_trimesh_shape()
	terrain_body.add_child(collision)
	add_child(terrain_body)
	var water := Visuals.piece(self,Vector3(41,-0.12,0),Vector3(3.4,0.03,118),Color("4b8884"))
	var water_mat := water.material_override as StandardMaterial3D
	water_mat.roughness = 0.18
	water_mat.metallic = 0.35
	water.name = "ShallowStream"
	add_to_group("terrain")
