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
func sole(leg: Node3D) -> Vector3:
	var skeleton: Skeleton3D = leg.get_node("LegSkeleton")
	var foot: MeshInstance3D = leg.get_node("Foot")
	return leg.to_global(skeleton.get_bone_global_pose(2)*skeleton.get_bone_global_rest(2).affine_inverse()*(foot.transform*Vector3(0,-0.5,0)))
func run() -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	var database: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/monsters.json"))
	for data in database.species:
		var model := Model.create(holder,data)
		for slope in [Vector2(0.2,0),Vector2(0,0.2),Vector2(0,-0.2)]:
			var ground := func(point: Vector3) -> float: return point.x*slope.x+point.z*slope.y
			for frame in 60: Model.animate(model,data,0,"idle",0,0,ground)
			check(model.position.y>= -0.35,"downhill body offset remains bounded")
			for name in ["Hind-1","Hind1","Front-1","Front1"]:
				var leg := model.get_node_or_null(name) as Node3D
				if leg==null: continue
				var point := sole(leg)
				check(absf(point.y-ground.call(point))<0.003,"stationary foot center fits slope: "+str(data.id)+name)
			Model.animate(model,data,0,"idle",0,4,ground)
			for side in [-1,1]:
				var point := sole(model.get_node("Hind"+str(side)))
				check(point.y-ground.call(point)>= -0.003,"walking foot center stays above slope")
	var world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	world.hunter.set_physics_process(false)
	for m in get_nodes_in_group("monsters"): m.set_physics_process(false)
	var monster = get_nodes_in_group("monsters")[0]
	var ramp := StaticBody3D.new()
	ramp.collision_layer = 2
	ramp.position = Vector3(100,-0.1,0)
	ramp.rotation.z = 0.15
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(20,0.2,20)
	collider.shape = shape
	ramp.add_child(collider)
	world.add_child(ramp)
	monster.global_position = Vector3(100,0.2,0)
	monster.rotation = Vector3.ZERO
	await physics_frame
	await physics_frame
	for frame in 60:
		monster.velocity = Vector3(0,-1,0)
		monster.move_and_slide()
		await physics_frame
	check(monster.is_on_floor(),"actual creature capsule stands on ramp")
	for frame in 60: monster._physics_process(1.0/60)
	for side in [-1,1]:
		var point := sole(monster.mesh.get_node("Hind"+str(side)))
		var height: float = -0.1+0.1/cos(0.15)+(point.x-100)*tan(0.15)
		check(absf(point.y-height)<0.003,"actual collision probe supports creature foot on ramp")
	check(is_zero_approx(monster.foot_ground_height(Vector3(160,0,0))),"missing ground gives no invented support height")
	print("CREATURE_GROUND_CHECKS: ",checks," FAILURES: ",failures)
	holder.queue_free()
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
