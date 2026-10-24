extends Node
## Foreign-object gating avoids highlighting the hunter's own overlapping limbs.
var hunter: CharacterBody3D
var parts: Array[MeshInstance3D] = []
var material: ShaderMaterial
var occluded := false
var visual_bounds := {}
func _ready() -> void:
	hunter = get_parent()
	material = ShaderMaterial.new()
	material.shader = preload("res://scripts/hunter_occlusion.gdshader")
	material.render_priority = 10
	for part in hunter.rig.root.find_children("SkinPart_*","MeshInstance3D",true,false):
		parts.append(part)
		part.material_overlay = material
func _physics_process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	occluded = false
	if is_instance_valid(camera) and hunter.combat.health>0:
		for height in [0.9,1.55]:
			var destination: Vector3 = hunter.global_position+Vector3.UP*height
			var query := PhysicsRayQueryParameters3D.create(camera.global_position,destination,3,[hunter.get_rid()])
			var hit := hunter.get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty() and hit.position.distance_to(destination)>0.15:
				occluded = true
				break
			# Large heads and tails extend outside conservative collision capsules.
			for monster in get_tree().get_nodes_in_group("monsters"):
				if not monster.is_visible_in_tree() or monster.global_position.distance_to(hunter.global_position)>24: continue
				var id: int = monster.get_instance_id()
				if not visual_bounds.has(id): visual_bounds[id] = monster.mesh.find_children("*","MeshInstance3D",true,false)
				for mesh in visual_bounds[id]:
					if not is_instance_valid(mesh) or not mesh.is_visible_in_tree(): continue
					if mesh.get_aabb().intersects_segment(mesh.to_local(camera.global_position),mesh.to_local(destination))!=null:
						occluded = true
						break
				if occluded: break
			if occluded: break
	material.set_shader_parameter("enabled",occluded)
