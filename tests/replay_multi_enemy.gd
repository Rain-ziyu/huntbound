extends SceneTree
## Two live AIs; fixture placement only, no injected health, damage or action clocks.
var world: Node3D
var fighter: CharacterBody3D
var foes: Array = []
var elapsed := 0.0
var attacks := {}
var warnings := {}
var phases := {}
var guard_rewards := 0
var damage_events := 0
var previous_health := 240.0
var observed_reward := false
var dead_frames := 0
var stop_positions: Array[Vector3] = []
var failures := 0
var checks := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ",label)
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
	world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	fighter = world.hunter
	for m in get_nodes_in_group("monsters"):
		m.set_physics_process(false)
		if m.data.id in ["mossback","reedclaw"]: foes.append(m)
	fighter.global_position = Vector3(0,0.05,-10)
	for i in foes.size():
		var m = foes[i]
		m.global_position = Vector3(0,0.05,-13 if i==0 else -7)
		m.rotation.y = PI if i==0 else 0.0
		attacks[m.data.id] = 0
		warnings[m.data.id] = 0
		phases[m.data.id] = "idle"
	fighter.lock_target = foes[0]
	await physics_frame
	await physics_frame
	for m in foes: m.set_physics_process(true)
	physics_frame.connect(control)
func control() -> void:
	elapsed += 1.0/60.0
	var c = fighter.combat
	for m in foes:
		var id: String = m.data.id
		if m.phase=="active" and phases[id]!="active": attacks[id] += 1
		if m.tell.visible or m.rear_tell.visible or m.lunge_tell.visible: warnings[id] += 1
		phases[id] = m.phase
	if c.guard_reward>0 and not observed_reward: guard_rewards += 1
	observed_reward = c.guard_reward>0
	if c.health<previous_health: damage_events += 1
	previous_health = c.health
	# Guard briefly, then deliberately remain exposed to validate death under pressure.
	if elapsed<8 and c.action=="idle": c.request("guard")
	if c.health<=0:
		dead_frames += 1
		if dead_frames==60:
			for m in foes: stop_positions.append(m.global_position)
		if dead_frames>=120:
			finish()
	elif elapsed>45: finish()
func finish() -> void:
	physics_frame.disconnect(control)
	for m in foes:
		check(attacks[m.data.id]>=2,str(m.data.id)+" independently commits repeated attacks")
		check(warnings[m.data.id]>0,str(m.data.id)+" displays its own warnings")
	check(guard_rewards>0,"front guard succeeds during simultaneous encounter")
	check(damage_events>=3,"live encounter applies repeated damage without permanent immunity")
	check(fighter.combat.health==0,"unprotected hunter can be defeated by combined pressure")
	for i in foes.size():
		check(foes[i].phase=="idle" and not foes[i].tell.visible and not foes[i].lunge_tell.visible and not foes[i].rear_tell.visible,"defeated hunter stops enemy attacks and warnings")
		check(stop_positions.size()==foes.size() and foes[i].global_position.distance_to(stop_positions[i])<0.02,"enemy remains stopped after hunter defeat")
	var result := {"checks":checks,"failures":failures,"seconds":elapsed,"attacks":attacks,"warning_frames":warnings,"guard_rewards":guard_rewards,"damage_events":damage_events,"health":fighter.combat.health,"scope":"two live AIs, stationary guard then deliberate exposure; not a victory or human difficulty test"}
	FileAccess.open("res://../Shubian-multi-enemy.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("MULTI_ENEMY_REPLAY: ",JSON.stringify(result))
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
