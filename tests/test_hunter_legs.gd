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
	for action in ["idle","guard","plant","dodge","heavy"]:
		p.combat.set_action(action)
		p.combat.drawn = true
		p.combat.elapsed = 0.2
		p.animate(0,0)
		for side in [-1,1]:
			var leg: Dictionary = p.rig.legs[side]
			var sole: Vector3 = p.to_local(leg.ankle.to_global(Vector3(0,-0.1,0)))
			check(absf(sole.y)<0.002,"stationary sole stays on ground: "+action)
			check(leg.knee.rotation.x< -0.1,"stance bends knee: "+action)
			check(absf(leg.hip.global_position.distance_to(leg.knee.global_position)-0.43)<0.001 and absf(leg.knee.global_position.distance_to(leg.ankle.global_position)-0.36)<0.001,"limbs keep length: "+action)
	for phase in [0.0,PI/2,PI,PI*1.5]:
		p.combat.set_action("idle")
		p.walk_clock = phase
		p.animate(0,4.5)
		var lifted := 0
		for side in [-1,1]:
			var sole: Vector3 = p.to_local(p.rig.legs[side].ankle.to_global(Vector3(0,-0.1,0)))
			check(sole.y>=-0.002,"walking sole avoids flat floor penetration")
			if sole.y>0.02: lifted += 1
		if phase==0 or is_equal_approx(phase,PI): check(lifted==1,"walk alternates one swing foot")
	p.combat.set_action("finisher")
	p.combat.elapsed = 0.95
	p.animate(0,0)
	var kick: Vector3 = p.to_local(p.weapon_contact_points("finisher",1)[0])
	check(kick.z< -0.8 and kick.y>0.6,"finisher extends actual kicking toe forward and upward")
	check((-p.rig.legs[1].boot.global_basis.y.normalized()).dot(p.rig.root.global_basis*Vector3.FORWARD)>0.70,"front kick presents the sole toward the target")
	var support: Vector3 = p.to_local(p.rig.legs[-1].ankle.to_global(Vector3(0,-0.1,0)))
	check(absf(support.y)<0.002,"kick leaves support foot planted")
	var monster = get_nodes_in_group("monsters")[0]
	p.global_position = Vector3.ZERO
	p.rig.root.rotation.y = 0
	monster.global_position = Vector3(0,0,-1.8)
	monster.rotation.y = PI/2
	var health: float = monster.health
	p.on_strike(1)
	p.update_weapon_contacts()
	check(monster.health<health,"second finisher beat damages through actual forward foot contact")
	p.combat.elapsed = 1.4
	p.animate(0,0)
	var recovered: Vector3 = p.to_local(p.rig.legs[1].ankle.to_global(Vector3(0,-0.1,0)))
	check(absf(recovered.y)<0.002,"kicking foot recovers to ground")
	check(p.rig.legs[1].boot.global_basis.y.normalized().dot(Vector3.UP)>0.9999,"recovered kick restores a flat sole")
	print("LEG_CHECKS: ",checks," FAILURES: ",failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
