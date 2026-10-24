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
	p.combat.set_action("light")
	p.pitch = -0.25
	var tips: Array[Vector3] = []
	for time in [0.0,0.11,0.25,0.34,0.66]:
		p.combat.elapsed = time
		p.animate(0,0)
		tips.append(p.rig.weapon.transform*p.rig.weapon.get_node("TipContact").position)
	check(tips[2].y>tips[1].y+0.25,"light thrust rises from low preparation into contact")
	check(tips[2].z<tips[1].z-0.12,"light thrust advances from preparation into contact")
	check(tips[3].y>tips[2].y,"light continues upward through contact window")
	check(tips[4].distance_to(tips[0])<0.001,"light returns to neutral weapon pose at recovery end")
	print("LIGHT_TRAJECTORY_CHECKS: ",checks," FAILURES: ",failures," TIPS: ",tips)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
