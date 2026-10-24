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
	p.global_position = Vector3(0,0.05,0)
	p.combat.set_action("light")
	p.combat.elapsed = 0.25
	p.animate(0,0)
	p.combat.shadow_lifetimes.assign([180.0])
	p.on_strike(0)
	p.lock_target = get_nodes_in_group("monsters")[0]
	p.take_damage(1000,Vector3.FORWARD,false)
	for frame in 60: p.animate(1.0/60,0)
	check(p.combat.health==0 and p.rig.root.rotation.z< -1.5,"defeated hunter falls onto side")
	check(p.lock_target==null and p.strike_windows.is_empty(),"defeat clears targeting and uncommitted melee windows")
	check(not p.ghosts.any(func(g): return g.visible),"defeat removes floating shadow visuals")
	var before: Transform3D = p.rig.root.transform
	p.combat.advance(2)
	for frame in 60: p.animate(1.0/60,0)
	check(p.rig.root.transform.is_equal_approx(before),"hurt clock ending cannot stand defeated hunter up")
	check(not p.combat.request("light"),"defeated hunter cannot restart combat")
	var minimum := INF
	for point in p.defeat.corners:
		minimum = minf(minimum,p.rig.root.to_global(point).y)
	check(minimum>=-0.001,"authored corpse mesh bounds stay above flat ground")
	for side in [-1,1]:
		var arm: Dictionary = p.rig.arms[side]
		check(absf(arm.upper.scale.y-0.39)<0.002 and absf(arm.lower.scale.y-0.39)<0.002,"defeat grip retains fixed arm lengths")
	world.combat_hud.update_state(p,0)
	check("F5" in world.combat_hud.status.text,"failure keeps retry instruction")
	var before_position: Vector3 = p.global_position
	var before_facing: float = p.rig.root.rotation.y
	Input.action_press("move_forward")
	p._physics_process(1.0/60)
	Input.action_release("move_forward")
	check(Vector2(p.global_position.x,p.global_position.z).distance_to(Vector2(before_position.x,before_position.z))<0.001,"movement input cannot move corpse")
	check(is_equal_approx(p.rig.root.rotation.y,before_facing),"movement input cannot rotate corpse after hurt ends")
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	p._unhandled_input(right)
	check(p.heavy_held<0,"defeated input cannot charge another throw")
	current_scene = world
	var retry := InputEventKey.new()
	retry.physical_keycode = KEY_F5
	retry.pressed = true
	p._unhandled_input(retry)
	for frame in 120:
		if is_instance_valid(current_scene) and current_scene!=world and current_scene.get("hunter")!=null: break
		await process_frame
	var ready: bool = is_instance_valid(current_scene) and current_scene!=world and current_scene.get("hunter")!=null
	check(ready,"F5 completes deferred scene replacement")
	if ready:
		var fresh = current_scene.hunter
		check(fresh.combat.health==240 and not fresh.defeat.started,"F5 creates fresh live hunter after defeat")
		check(not fresh.combat.drawn and fresh.rig.weapon.position.distance_to(Vector3(0,1.05,0.26))<0.001,"F5 restores initialized back-carried weapon")
		world = current_scene
	print("PLAYER_DEFEAT_CHECKS: ",checks," FAILURES: ",failures)
	if is_instance_valid(world): world.queue_free()
	await process_frame
	quit(1 if failures else 0)
