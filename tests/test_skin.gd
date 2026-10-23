extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var model = load("res://assets/models/hunter-forest-v1.tscn").instantiate()
	root.add_child(model)
	await process_frame
	var skeleton := model.get_node("Skeleton3D") as Skeleton3D
	check(skeleton.get_bone_count()>20,"model has saved skeletal structure")
	var bound := 0
	var descendants := 0
	for bone in skeleton.get_bone_count():
		if skeleton.get_bone_parent(bone)>0: descendants += 1
	for child in skeleton.get_children():
		if child is MeshInstance3D:
			check(child.skin!=null and child.skin.get_bind_count()==skeleton.get_bone_count(),"skin binds available")
			var arrays: Array = child.mesh.surface_get_arrays(0)
			check(arrays[Mesh.ARRAY_BONES].size()==arrays[Mesh.ARRAY_VERTEX].size()*4,"vertex bone indices stored")
			var sum := 0.0
			for weight in arrays[Mesh.ARRAY_WEIGHTS]: sum += weight
			check(is_equal_approx(sum,float(arrays[Mesh.ARRAY_VERTEX].size())),"weights normalized")
			bound += 1
	check(bound>20 and descendants>=4,"arm hand hierarchy and bound meshes")
	var player := model.get_node("AnimationPreview") as AnimationPlayer
	check(player.get_animation_list().size()==17,"all seventeen preview clips saved")
	player.play("heavy")
	player.advance(0)
	var before: Quaternion = model.get_node("Trident").quaternion
	player.advance(0.45)
	var after: Quaternion = model.get_node("Trident").quaternion
	check(before.angle_to(after)>0.1,"saved clip actually animates the weapon")
	print("SKIN_CHECKS: ",checks," FAILURES: ",failures)
	model.queue_free()
	await process_frame
	quit(1 if failures else 0)
