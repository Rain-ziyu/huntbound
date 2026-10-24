extends Node3D
## Short-lived visual snapshot; owns no collision, damage, resources or combat clock.
var source: Node3D
var departure := Transform3D.IDENTITY
var arrival := Transform3D.IDENTITY
var age := 0.0
var lifetime := 0.35
var material: StandardMaterial3D
var ghosts: Array[Node3D] = []
var rings: Array[MeshInstance3D] = []
func _ready() -> void:
	add_to_group("teleport_feedback")
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.48,0.86,0.79,0.28)
	for index in 2:
		var snapshot: Node3D = source.duplicate(0)
		snapshot.name = "DepartureGhost" if index==0 else "ArrivalGhost"
		add_child(snapshot)
		snapshot.global_transform = departure if index==0 else arrival
		for part in snapshot.find_children("*","MeshInstance3D",true,false):
			part.material_override = material
			part.material_overlay = null
			part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ghosts.append(snapshot)
		var ring := MeshInstance3D.new()
		var shape := TorusMesh.new()
		shape.inner_radius = 0.57
		shape.outer_radius = 0.63
		shape.rings = 24
		shape.ring_segments = 12
		ring.mesh = shape
		ring.material_override = material
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
		ring.global_position = (departure.origin if index==0 else arrival.origin)+Vector3.UP*0.12
		rings.append(ring)
	var distance := departure.origin.distance_to(arrival.origin)
	for index in 3:
		var streak := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3(0.022,0.022,distance)
		streak.mesh = shape
		streak.material_override = material
		streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(streak)
		streak.global_position = (departure.origin+arrival.origin)*0.5+Vector3.UP*(0.7+index*0.18)
		streak.look_at(arrival.origin+Vector3.UP*(0.7+index*0.18))
func _process(delta: float) -> void:
	age += delta
	var progress := clampf(age/lifetime,0,1)
	material.albedo_color.a = 0.28*pow(1-progress,2)
	for ring in rings: ring.scale = Vector3.ONE*(0.8+progress*0.8)
	if age>=lifetime: queue_free()
