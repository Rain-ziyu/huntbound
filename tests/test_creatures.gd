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
	for m in monsters:
		m.set_physics_process(false)
		check(m.mesh.has_node("Neck") and m.mesh.has_node("Tail"),"neck and tail rig: "+str(m.data.id))
		var quad: bool = "quadruped" in m.data.body
		check(m.mesh.has_node("Front1")==quad,"correct limb plan: "+str(m.data.id))
		m.CreatureModel.animate(m.mesh,m.data,1.0,"idle",0.3,4)
		check(absf(m.mesh.get_node("Hind1").rotation.x)>0.05,"walking leg moves")
	var m = monsters[0]
	m.global_position = Vector3(0,0,-16)
	m.rotation.y = PI/2 # Keep the long tail on the monster's side of the wall.
	p.global_position = Vector3(0,0.05,-13)
	p.rig.root.rotation.y = 0
	await physics_frame
	check(m.clear_line_to(p.global_position),"open attack line")
	world.obstacle(Vector3(0,1.5,-13.8),Vector3(3,3,0.15),Color.GRAY)
	await physics_frame
	await physics_frame
	check(not m.clear_line_to(p.global_position),"wall blocks creature attack line")
	var hp: float = m.health
	p.combat.set_action("light")
	p.combat.advance(0.3)
	p.animate(0,0)
	p.update_weapon_contacts()
	check(m.health==hp,"player melee cannot cross wall")
	print("CREATURE_CHECKS: ",checks," FAILURES: ",failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
