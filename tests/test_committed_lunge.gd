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
		check(m.lunge_tell.visible and not m.tell.visible,"lane warning replaces circular tell")
		check(m.lunge_tell.contains(locked),"warning includes locked target")
		check(not m.lunge_tell.contains(m.global_position+Vector3(m.lunge_tell.half_width+0.2,0,-2)),"lateral escape lies outside warning")
		var origin: Vector3 = m.lunge_tell.start
		p.global_position += Vector3(6,0,0)
		for frame in 60:
			await physics_frame
			if m.phase=="active": break
		check(m.phase=="active" and m.target_point.distance_to(locked)<0.001,"late sidestep does not retarget lunge")
		var last_z: float = m.global_position.z
		var minimum := last_z
		var monotonic := true
		var warning_covers := true
		for frame in 60:
			await physics_frame
			minimum = minf(minimum,m.global_position.z)
			if m.global_position.z>last_z+0.005: monotonic = false
			warning_covers = warning_covers and m.lunge_tell.contains(m.global_position+m.lunge_direction*3.7)
			last_z = m.global_position.z
			if m.phase=="recover": break
		m.set_physics_process(false)
		print("LUNGE_PATH: ",m.data.id," locked=",locked," end=",m.global_position," min_z=",minimum," direction=",m.lunge_direction)
		check(monotonic,"committed lunge never reverses after passing target: "+m.data.id)
		check(minimum<locked.z-0.8,"lunge continues past abandoned target point")
		check(absf(m.global_position.x)<0.05,"lunge does not steer sideways after lock")
		check(p.combat.health==240,"late sidestep avoids actual lunge hit")
		check(m.phase=="recover" and m.exposed>0,"missed lunge exposes recovery weakness")
		check(is_zero_approx(m.wall_stun),"ordinary floor contact does not cause wall stun")
		check(warning_covers and m.lunge_tell.start.distance_to(origin)<0.001,"fixed warning covers whole committed attack travel")
		check(not m.lunge_tell.visible,"warning hides on recovery")
		check(not m.lunge_contains(m.global_position+Vector3(m.lunge_tell.half_width+0.1,0,-2)),"lunge damage excludes lateral escape")
		check(not m.lunge_contains(m.global_position+Vector3(0,3,-2)),"lunge damage excludes vertical separation")
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
		check(is_zero_approx(m.wall_stun),"hitting hunter capsule does not count as wall")
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
		for frame in 150:
			await physics_frame
			if m.phase=="windup" and m.clock>float(m.data.windup)*0.78: break
		p.global_position.x = m.lunge_tell.half_width+0.15
		check(not m.lunge_tell.contains(p.global_position),"small late sidestep leaves visible lane")
		for frame in 100:
			await physics_frame
			if m.phase=="recover": break
		m.set_physics_process(false)
		check(p.combat.health==240,"just outside visible lane avoids actual attack damage")
		var wall = world.obstacle(Vector3(0,1.5,-20.5),Vector3(8,3,0.4),Color.GRAY)
		m.global_position = Vector3(0,0,-16)
		m.rotation = Vector3.ZERO
		m.velocity = Vector3.ZERO
		m.phase = "idle"
		m.clock = 0
		p.global_position = Vector3(0,0,-18.8)
		p.combat.health = 240
		p.combat.set_action("idle")
		var hp: float = m.health
		await physics_frame
		await physics_frame
		m.set_physics_process(true)
		for frame in 150:
			await physics_frame
			if m.phase=="windup" and m.clock>float(m.data.windup)*0.78: break
		p.global_position.x = 6
		for frame in 100:
			await physics_frame
			if m.wall_stun>0: break
		check(m.wall_stun>0 and m.phase=="recover" and m.stagger>0,"real solid wall stops lunge and staggers creature")
		check(m.global_position.z> -20.2,"creature does not pass through wall")
		check(Vector2(m.velocity.x,m.velocity.z).length()<0.001,"wall impact cancels horizontal drive")
		check(not m.lunge_tell.visible,"impact hides obsolete attack warning")
		check(m.health==hp and p.combat.health==240,"environment impact causes no invented damage")
		var result: Dictionary = m.receive_strike(10,p.global_position,"light","flank")
		check(result.weak and result.damage>10,"wall recovery exposes real flank weakness")
		for frame in 40: await physics_frame
		check(is_zero_approx(m.wall_stun) and is_zero_approx(m.stagger) and m.phase=="recover" and m.exposed>0,"brief stun expires into ordinary punishable recovery")
		m.set_physics_process(false)
		wall.queue_free()
		await physics_frame
		m.global_position = Vector3(40,0,40)
	print("COMMITTED_LUNGE_CHECKS: ",checks," FAILURES: ",failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
