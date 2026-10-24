extends SceneTree
const Outfit = preload("res://scripts/hunter_outfit.gd")
const Model = preload("res://scripts/hunter_model.gd")
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
	var profile := Outfit.loft(holder,"NormalProbe",[Vector4(0,0.1,0.1,0),Vector4(1,0.1,0.1,0)],Color.WHITE)
	var arrays: Array = profile.mesh.surface_get_arrays(0)
	var alignment := 0.0
	for index in 28*6:
		var point: Vector3 = arrays[Mesh.ARRAY_VERTEX][index]
		var normal: Vector3 = arrays[Mesh.ARRAY_NORMAL][index]
		alignment += Vector3(point.x,0,point.z).normalized().dot(normal)
	check(alignment/(28*6)>0.9,"profile mesh normals face outward")
	var rig := Model.create(holder)
	check(rig.root.has_node("Head") and rig.root.has_node("HairCap"),"head and hair are separate editable meshes")
	check(rig.root.has_node("RainCape1") and rig.root.has_node("RainCape-1"),"split cape panels exist")
	check(rig.weapon.has_node("CenterBlade") and rig.weapon.has_node("Hook1") and rig.weapon.has_node("Hook-1"),"three blade silhouettes exist")
	check(rig.weapon.has_node("Grip") and rig.weapon.has_node("Butt") and rig.weapon.has_node("JadeCell"),"grip butt and jade insert remain separate")
	var grip: MeshInstance3D = rig.weapon.get_node("Grip")
	check(grip.position.y-grip.mesh.height/2<=-0.28 and grip.position.y+grip.mesh.height/2>=0.18,"existing hand grip points fit new wrapped handle")
	check(is_equal_approx(rig.weapon.get_node("TipContact").position.y,1.2) and is_equal_approx(rig.weapon.get_node("ButtContact").position.y,-0.98),"combat endpoints preserved in model markers")
	Model.pose_legs(rig,"finisher",0.95,true,0,0,0)
	check(rig.skirts[1].rotation.x>0.4,"coat panel opens with kicking thigh")
	Model.pose_arms(rig,false,0)
	for side in [-1,1]:
		check(rig.arms[side].elbow.position.distance_to(rig.arms[side].hand.position)>0.38,"relaxed arm remains full length")
	print("COSTUME_CHECKS: ",checks," FAILURES: ",failures)
	holder.queue_free()
	await process_frame
	quit(1 if failures else 0)
