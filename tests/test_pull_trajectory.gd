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
	for m in get_nodes_in_group("monsters"): m.set_physics_process(false)
	p.combat.set_action("pull")
	p.pitch = -0.25
	var tips: Array[Vector3] = []
	for time in [0.0,0.22,0.40,0.58,0.86]:
		p.combat.elapsed = time
		p.animate(0,0)
		tips.append(p.rig.weapon.transform*p.rig.weapon.get_node("TipContact").position)
	p.combat.set_action("idle")
	p.combat.drawn = true
	p.animate(0,0)
	var neutral: Vector3 = p.rig.weapon.transform*p.rig.weapon.get_node("TipContact").position
	check(tips[0].distance_to(neutral)<0.001,"pull begins from neutral")
	check(tips[4].distance_to(neutral)<0.001,"pull recovers to neutral")
	check(tips[2].z>tips[1].z+0.10,"hook draws backward through contact")
	check(tips[3].z>tips[2].z+0.10,"hook follows through toward hunter")
	print("PULL_TRAJECTORY_CHECKS: ",checks," FAILURES: ",failures," TIPS: ",tips)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
