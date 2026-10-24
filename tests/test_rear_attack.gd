extends SceneTree
const Contact = preload("res://scripts/tail_contact.gd")
var checks := 0
var failures := 0
var world: Node3D
var fighter: CharacterBody3D
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)
func _initialize() -> void: call_deferred("run")
func prepare(m: CharacterBody3D) -> void:
	m.phase = "idle"
	m.rear_attack = false
	m.rear_cooldown = 0
	m.clock = 0
	m.stagger = 0
	m.rotation = Vector3.ZERO
	m.velocity = Vector3.ZERO
	fighter.global_position = m.global_position+Vector3(0,0,3.2)
	fighter.combat.health = 240
	fighter.combat.stamina = 100
	fighter.combat.guard_reward = 0
	fighter.combat.set_action("idle")
	fighter.rig.root.rotation.y = 0
	m.set_physics_process(true)
func until_active(m: CharacterBody3D) -> void:
	for frame in 150:
		await physics_frame
		if m.phase=="active": return
func finish_hit(m: CharacterBody3D) -> void:
	for frame in 30: await physics_frame
	m.set_physics_process(false)
func run() -> void:
	var rings: Array[Vector4] = [Vector4(0,1,0.1,0),Vector4(2,1,0.1,0)]
	var before := Transform3D(Basis.IDENTITY,Vector3(-2,0,0))
	var after := Transform3D(Basis.IDENTITY,Vector3(2,0,0))
	var feet := Vector3(0,0,1)
	check(not Contact.touches(rings,before,before,feet),"tail starts clear of capsule")
	check(not Contact.touches(rings,after,after,feet),"tail ends clear of capsule")
	check(Contact.touches(rings,before,after,feet),"swept tail catches crossing between disjoint poses")
	check(not Contact.touches(rings,before,after,feet+Vector3.UP*4),"sweep rejects vertically separated capsule")
	world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	fighter = world.hunter
	fighter.set_physics_process(false)
	for m in get_nodes_in_group("monsters"): m.set_physics_process(false)
	for m in get_nodes_in_group("monsters"):
		if not m.data.has("rear_attack"): continue
		prepare(m)
		await physics_frame
		await physics_frame
		check(m.rear_attack and m.phase=="windup","live AI chooses rear attack: "+m.data.id)
		check(m.rear_tell.visible and not m.tell.visible,"rear sector warning replaces front warning")
		if m.data.id=="mossback" and "--capture" in OS.get_cmdline_user_args():
			world.hud.get_parent().hide()
			var camera := Camera3D.new()
			world.add_child(camera)
			camera.global_position = m.global_position+Vector3(7,8,9)
			camera.look_at(m.global_position+Vector3(0,0.5,1.5))
			camera.fov = 48
			camera.current = true
			for frame in 24: await physics_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Shubian-rear-warning.png"))
			print("REAR_WARNING_CAPTURE: saved; capture mode exits before full checks")
			world.queue_free()
			await process_frame
			await RenderingServer.frame_post_draw
			quit(1 if failures else 0)
			return
		var yaw: float = m.rotation.y
		await until_active(m)
		check(absf(m.rotation.y-yaw)<0.001,"rear windup holds orientation")
		for frame in 4: await physics_frame
		check(fighter.combat.health==240,"center target is safe before visible tail arrives")
		await finish_hit(m)
		check(is_equal_approx(fighter.combat.health,240-float(m.data.rear_attack.damage)),"rear attack deals one live hit")
		check(m.rear_contains(m.global_position+Vector3(0,0,3)) and not m.rear_contains(m.global_position+Vector3(0,0,-3)),"rear cone excludes front")
		check(not m.rear_contains(m.global_position+Vector3(0,3,3)),"rear cone excludes high target")
		check(not m.rear_contains(m.global_position+Vector3(0,0,10)),"rear cone excludes distant target")
		m.set_physics_process(true)
		for frame in 200:
			await physics_frame
			if m.phase=="windup" and not m.rear_attack: break
		m.set_physics_process(false)
		check(m.phase=="windup" and not m.rear_attack and m.rear_cooldown>0,"cooldown forces next attack back to primary move")
		prepare(m)
		await until_active(m)
		fighter.global_position = m.global_position+Vector3(3.2,0,0)
		await finish_hit(m)
		check(fighter.combat.health==240,"leaving warned sector avoids live hit")
		prepare(m)
		await until_active(m)
		fighter.combat.request("guard")
		fighter.combat.advance(0.2)
		await finish_hit(m)
		check(fighter.combat.health==240 and fighter.combat.guard_reward>0,"facing guard blocks tail and earns reply")
		prepare(m)
		await until_active(m)
		m.receive_strike(1,fighter.global_position,"reply","tail")
		await finish_hit(m)
		check(fighter.combat.health==240 and not m.rear_tell.visible,"reply interruption cancels pending tail damage")
		check(m.rear_cooldown>0,"rear action has cooldown")
		prepare(m)
		await until_active(m)
		var wall := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(4,3,0.2)
		shape.shape = box
		wall.add_child(shape)
		world.add_child(wall)
		wall.global_position = m.global_position+Vector3(0,1,2)
		await finish_hit(m)
		check(fighter.combat.health==240,"solid cover blocks tail damage")
		wall.queue_free()
		await physics_frame
		prepare(m)
		await until_active(m)
		fighter.global_position = m.global_position+Vector3(3.2,0,0)
		for frame in 45: await physics_frame
		m.set_physics_process(false)
		check(m.phase=="recover" and m.exposed>0 and not m.rear_tell.visible,"tail recovery exposes pursuit window")
		prepare(m)
		fighter.global_position = m.global_position+Vector3(sin(1.15)*3.2,0,cos(1.15)*3.2)
		await until_active(m)
		check(m.rear_attack and m.rear_contains(fighter.global_position),"edge target remains inside broad warning sector")
		await finish_hit(m)
		check(fighter.combat.health==240,"warning sector alone does not deal damage without tail contact")
	print("REAR_ATTACK_CHECKS: ",checks," FAILURES: ",failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
