extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ",label)
func _initialize() -> void: call_deferred("run")
func key(shift := false, echo := false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_TAB
	event.pressed = true
	event.shift_pressed = shift
	event.echo = echo
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
func run() -> void:
	var world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	var p = world.hunter
	p.set_physics_process(false)
	var monsters := get_nodes_in_group("monsters")
	for m in monsters: m.set_physics_process(false)
	p.global_position = Vector3(0,0.05,-10)
	var placements := [Vector3(-3,0.05,-15),Vector3(3,0.05,-16),Vector3(0,0.05,-21),Vector3(0,0.05,20),Vector3(0,0.05,-50)]
	for i in monsters.size(): monsters[i].global_position = placements[i]
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0,4,-3)
	camera.look_at(Vector3(0,1,-16))
	camera.make_current()
	await physics_frame
	await physics_frame
	var candidates: Array = p.lock_candidates()
	check(candidates.size()==3,"only nearby on-screen creatures are candidates")
	check(candidates==[monsters[0],monsters[2],monsters[1]],"cycle order follows camera left to right")
	p.camera_manual_time = 0.6
	await key()
	check(p.lock_target==monsters[0],"Tab from unlocked selects nearest visible creature")
	check(p.camera_manual_time==0,"explicit target acquisition releases old manual camera grace")
	await key()
	check(p.lock_target==monsters[2],"Tab reaches next screen target")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Shubian-target-switch.png"))

	await key()
	check(p.lock_target==monsters[1],"Tab reaches rightmost target")
	await key()
	check(p.lock_target==monsters[0],"cycle wraps")
	await key(true)
	check(p.lock_target==monsters[1],"Shift Tab reverses cycle")
	await key(false,true)
	check(p.lock_target==monsters[1],"key repeat does not cycle repeatedly")
	monsters[1].health = 0
	await key()
	check(p.lock_target==monsters[0],"defeated current target is replaced by nearest eligible target")
	monsters[2].global_position = Vector3(0,0.05,8)
	await physics_frame
	await physics_frame
	check(p.lock_candidates()==[monsters[0]],"living in-range target behind camera is excluded")
	p.cycle_lock()
	check(p.lock_target==monsters[0],"one candidate remains selected")
	for expected in [null,monsters[0]]:
		var middle := InputEventMouseButton.new()
		middle.button_index = MOUSE_BUTTON_MIDDLE
		middle.pressed = true
		Input.parse_input_event(middle)
		await process_frame
		middle = middle.duplicate()
		middle.pressed = false
		Input.parse_input_event(middle)
		await process_frame
		check(p.lock_target==expected,"middle button retains unlock and reacquire behavior")

	p.combat.set_action("heavy")
	var elapsed: float = p.combat.elapsed
	var hp: float = p.combat.health
	var stamina: float = p.combat.stamina
	p.cycle_lock()
	check(p.combat.action=="heavy" and p.combat.elapsed==elapsed,"target switch preserves attack timing")
	check(p.combat.health==hp and p.combat.stamina==stamina,"target switch costs no combat resources")
	world.obstacle(Vector3(0,3,-13),Vector3(16,7,0.5),Color.GRAY)
	await physics_frame
	await physics_frame
	check(p.lock_candidates().is_empty(),"opaque wall excludes covered targets")
	p.cycle_lock()
	check(p.lock_target==null,"no visible target clears selection")
	p.lock_target = monsters[4]
	p._physics_process(1.0/60)
	check(p.lock_target==null,"existing lock releases beyond 30 metres")
	p.lock_target = monsters[1]
	p._physics_process(1.0/60)
	check(p.lock_target==null,"existing lock releases defeated creature")
	p.combat.health = 0
	check(p.lock_candidates().is_empty(),"defeated hunter cannot acquire targets")
	print("TARGET_SWITCH_CHECKS: ",checks," FAILURES: ",failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
