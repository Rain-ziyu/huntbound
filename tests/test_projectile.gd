extends SceneTree
var checks := 0
var failures := 0
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
	var monsters := get_nodes_in_group("monsters")
	for m in monsters: m.set_physics_process(false)
	var m = monsters[0]
	m.global_position = Vector3(0,0,-16)
	p.global_position = Vector3(0,0.05,-10)
	p.rig.root.rotation.y = 0
	await physics_frame
	var hp: float = m.health
	p.combat.set_action("throw")
	p.on_strike(0)
	check(is_instance_valid(p.projectile),"throw creates physical visual projectile")
	var shot = p.projectile
	shot.set_physics_process(false)
	check(m.health==hp,"throw does not apply instant ranged damage")
	for i in 40:
		if shot.finished: break
		shot._physics_process(0.025)
	check(shot.finished and m.health<hp,"flight ray collides and damages creature")
	check(p.global_position.z < -10 and p.global_position.z > -16,"arrival stops before monster capsule")
	await process_frame
	world.obstacle(Vector3(10,2,2),Vector3(8,4,0.5),Color.GRAY)
	p.global_position = Vector3(10,0.05,8)
	await physics_frame
	p.finish_throw(Vector3(10,0,-10))
	check(p.global_position.z>2.3,"capsule sweep prevents wall crossing")
	p.combat.set_action("hurt")
	var before: Vector3 = p.global_position
	p.finish_throw(Vector3(30,0,20))
	check(p.global_position==before,"interrupted throw cannot teleport")
	print("PROJECTILE_CHECKS: ",checks," FAILURES: ",failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
