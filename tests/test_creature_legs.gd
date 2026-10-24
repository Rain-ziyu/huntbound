extends SceneTree
const Model = preload("res://scripts/creature_model.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	var database: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/monsters.json"))
	for species in database.species:
		var model := Model.create(holder,species)
		var saved = load("res://assets/models/"+str(species.id)+"-v1.tscn").instantiate()
		holder.add_child(saved)
		for side in [-1,1]:
			var saved_leg: Node3D = saved.get_node("Hind"+str(side))
			var skeleton := saved_leg.get_node_or_null("LegSkeleton") as Skeleton3D
			check(skeleton!=null and skeleton.get_bone_count()==3,"saved model retains leg bones")
			if skeleton:
				var foot: MeshInstance3D = skeleton.get_node("Skin_Foot")
				check(foot.skin!=null and foot.skin.get_bind_count()==3 and foot.skeleton==NodePath(".."),"saved model retains ankle skin")
		for gait in [0.0,PI/2,PI,PI*1.5]:
			for frame in 30: Model.animate(model,species,gait,"idle",0,4)
			check(model.position.y> -0.25,"body height does not accumulate over frames")
			for side in [-1,1]:
				var leg: Node3D = model.get_node("Hind"+str(side))
				var skeleton: Skeleton3D = leg.get_node("LegSkeleton")
				var hip := skeleton.get_bone_global_pose(0)
				var knee := skeleton.get_bone_global_pose(1)
				var ankle := skeleton.get_bone_global_pose(2)
				check(absf(hip.origin.distance_to(knee.origin)-skeleton.get_bone_rest(1).origin.length())<0.001 and absf(knee.origin.distance_to(ankle.origin)-skeleton.get_bone_rest(2).origin.length())<0.001,"two leg segments retain lengths")
				check(ankle.basis.y.dot(Vector3.UP)>0.999,"ankle levels foot through knee bends")
				var foot: MeshInstance3D = leg.get_node("Foot")
				var sole := leg.to_global(ankle*skeleton.get_bone_global_rest(2).affine_inverse()*(foot.transform*Vector3(0,-0.5,0)))
				check(sole.y>= -0.002,"animated foot avoids flat floor penetration")
				check(absf(skeleton.get_bone_pose_rotation(1).get_angle())>0.02,"walking bends actual knee bone")
		Model.animate(model,species,0,"idle",0,0)
		for phase in ["idle","windup"]:
			Model.animate(model,species,0,phase,float(species.windup),0)
			for side in [-1,1]:
				var leg: Node3D = model.get_node("Hind"+str(side))
				var skeleton: Skeleton3D = leg.get_node("LegSkeleton")
				var foot: MeshInstance3D = leg.get_node("Foot")
				var sole := leg.to_global(skeleton.get_bone_global_pose(2)*skeleton.get_bone_global_rest(2).affine_inverse()*(foot.transform*Vector3(0,-0.5,0)))
				check(absf(sole.y)<0.002,"idle or lowered charging torso keeps planted feet on flat floor")
		for leg_name in ["Hind-1","Hind1","Front-1","Front1"]:
			var leg := model.get_node_or_null(leg_name) as Node3D
			if not leg: continue
			var skeleton: Skeleton3D = leg.get_node("LegSkeleton")
			check(skeleton.get_bone_count()==3 and skeleton.get_bone_parent(2)==1,"hip knee ankle chain exists")
			var rendered: MeshInstance3D = skeleton.get_node("Skin_LegSurface")
			var arrays := rendered.mesh.surface_get_arrays(0)
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var normalized := true
			for i in range(0,weights.size(),4): normalized = normalized and absf(weights[i]+weights[i+1]-1)<0.0001
			check(normalized and not leg.get_node("LegSurface").visible and rendered.visible,"leg uses normalized blended skin")
			check(skeleton.has_node("Skin_Foot") and skeleton.has_node("Skin_Claw0"),"foot and claws are attached to ankle skin")
	print("CREATURE_LEG_CHECKS: ",checks," FAILURES: ",failures)
	holder.queue_free()
	await process_frame
	quit(1 if failures else 0)
