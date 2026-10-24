extends SceneTree
const Model = preload("res://scripts/hunter_model.gd")
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	var p = world.hunter
	p.set_physics_process(false)
	for m in get_nodes_in_group("monsters"): m.set_physics_process(false)
	for slope in [Vector2(0.35,0),Vector2(0,0.35),Vector2(0,-0.35)]:
		var sample := func(point: Vector3) -> float: return point.x*slope.x+point.z*slope.y
		for action in ["idle","guard","plant","finisher"]:
			for frame in 90:
				Model.pose_legs(p.rig,action,0.95,true,0,0,1.0/60,sample)
			var supported := true
			for side in [-1,1]:
				if action=="finisher" and side==1: continue
				var leg: Dictionary = p.rig.legs[side]
				var sole: Vector3 = p.rig.root.transform*(leg.hip.transform*leg.knee.transform*leg.ankle.transform*Vector3(0,-0.1,0))
				# Sole coordinates are in actor space; yaw is zero in this fixture.
				supported = supported and absf(sole.y-sample.call(sole))<0.003
			check(supported,"support feet fit slope: "+action+str(slope))
			check(p.rig.root.position.y> -0.30,"body offset does not accumulate over frames")
	var ramp := StaticBody3D.new()
	ramp.collision_layer = 2
	ramp.position = Vector3(100,-0.1,0)
	ramp.rotation.z = 0.3
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10,0.2,10)
	collider.shape = box
	ramp.add_child(collider)
	world.add_child(ramp)
	p.global_position = Vector3(100,0,0)
	p.rig.root.rotation = Vector3.ZERO
	await physics_frame
	await physics_frame
	for x in [-0.14,0.14]:
		var actual: float = p.foot_ground_height(Vector3(x,0,0))
		var expected: float = -0.1+0.1/cos(0.3)+x*tan(0.3)
		check(absf(actual-expected)<0.002,"real collision ray samples ramp")
	for frame in 30:
		p.velocity = Vector3(0,-1,0)
		p.move_and_slide()
		await physics_frame
	check(p.is_on_floor(),"actor actually grounded on slope")
	p.combat.drawn = true
	p.combat.set_action("guard")
	for frame in 90: p.animate(1.0/60,0)
	for side in [-1,1]:
		var ankle: Node3D = p.rig.legs[side].ankle
		var sole := ankle.to_global(Vector3(0,-0.1,0))
		var expected: float = -0.1+0.1/cos(0.3)+(sole.x-100)*tan(0.3)
		check(absf(sole.y-expected)<0.003,"runtime animation samples real ramp under each foot")
	p.global_position.y = 3
	check(is_zero_approx(p.foot_ground_height(Vector3.ZERO)),"missing nearby ground returns no offset")
	print("FOOT_GROUND_CHECKS: ",checks," FAILURES: ",failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
