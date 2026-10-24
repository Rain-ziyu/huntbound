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
	var index := 0
	for m in get_nodes_in_group("monsters"):
		m.set_physics_process(false)
		m.global_position = Vector3(80+index*12,0,80)
		index += 1
	await physics_frame
	await physics_frame
	for m in get_nodes_in_group("monsters"):
		if m.data.pattern not in ["charge","leap"]: continue
		m.global_position = Vector3(0,0,-16)
		m.rotation = Vector3.ZERO
		m.phase = "idle"
		m.clock = 0
		m.stagger = 0
		m.rear_attack = false
		p.global_position = m.global_position+Vector3(0,0,-2.8)
		p.combat.health = 240
		p.combat.set_action("idle")
		m.velocity = Vector3.ZERO
		await physics_frame
		await physics_frame
		m.set_physics_process(true)
		for frame in 150:
			await physics_frame
			if m.phase=="windup" and m.clock>float(m.data.windup)*0.78: break
		check(m.phase=="windup","natural lunge windup: "+m.data.id)
		var locked: Vector3 = m.target_point
		p.global_position += Vector3(6,0,0)
		for frame in 60:
			await physics_frame
			if m.phase=="active": break
		check(m.phase=="active" and m.target_point.distance_to(locked)<0.001,"late sidestep does not retarget lunge")
		var last_z: float = m.global_position.z
		var minimum := last_z
		var monotonic := true
		for frame in 60:
			await physics_frame
			minimum = minf(minimum,m.global_position.z)
			if m.global_position.z>last_z+0.005: monotonic = false
			last_z = m.global_position.z
			if m.phase=="recover": break
		m.set_physics_process(false)
		print("LUNGE_PATH: ",m.data.id," locked=",locked," end=",m.global_position," min_z=",minimum," direction=",m.lunge_direction)
		check(monotonic,"committed lunge never reverses after passing target: "+m.data.id)
		check(minimum<locked.z-0.8,"lunge continues past abandoned target point")
		check(absf(m.global_position.x)<0.05,"lunge does not steer sideways after lock")
		check(p.combat.health==240,"late sidestep avoids actual lunge hit")
		check(m.phase=="recover" and m.exposed>0,"missed lunge exposes recovery weakness")
		m.global_position = Vector3(0,0,-16)
		m.rotation = Vector3.ZERO
		m.velocity = Vector3.ZERO
		m.phase = "idle"
		m.clock = 0
		p.global_position = Vector3(0,0,-18.8)
		p.combat.health = 240
		p.combat.set_action("idle")
		await physics_frame
		await physics_frame
		m.set_physics_process(true)
		for frame in 180:
			await physics_frame
			if m.phase=="recover": break
		m.set_physics_process(false)
		check(is_equal_approx(p.combat.health,240-float(m.data.damage)),"staying in path takes exactly one normal lunge hit")
		check(m.phase=="recover","connected lunge also ends in recovery")
		m.global_position = Vector3(40,0,40)
	print("COMMITTED_LUNGE_CHECKS: ",checks," FAILURES: ",failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
