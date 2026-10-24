extends SceneTree
## Deterministic controller smoke replay, not a human difficulty or animation acceptance test.
var elapsed := 0.0
var decisions := 0
var world: Node3D
var fighter: CharacterBody3D
var monster: CharacterBody3D
var last_attack := "heavy"
var result_saved := false
var controller_name := "stationary_guard"
var observed_contacts := 0
var observed_weak_contacts := 0
var observed_parts := {}

func _initialize() -> void: call_deferred("setup")
func setup() -> void:
	world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	fighter = world.hunter
	var creatures := get_nodes_in_group("monsters")
	monster = creatures[0]
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--species="):
			for creature in creatures:
				if creature.data.id==argument.trim_prefix("--species="): monster = creature
	for creature in creatures:
		if creature!=monster: creature.set_physics_process(false)
	fighter.global_position = monster.global_position+Vector3(0,0,3.2)
	fighter.lock_target = monster
	fighter.hit_confirmed.connect(func(_action: String, _beat: int, victim: Node3D, result: Dictionary):
		if victim!=monster: return
		observed_contacts += 1
		if result.weak: observed_weak_contacts += 1
		observed_parts[result.part] = int(observed_parts.get(result.part,0))+1
	)
	physics_frame.connect(control)

func control() -> void:
	if result_saved: return
	elapsed += 1.0/60.0
	var c = fighter.combat
	if c.health<=0 or monster.health<=0 or elapsed>=120:
		result_saved = true
		var result := {"species":monster.data.id,"controller":controller_name,"simulation_seconds":snappedf(elapsed,0.01),"player_health":c.health,"monster_health":monster.health,"actions":decisions,"outcome":"victory" if monster.health<=0 else ("defeat" if c.health<=0 else "timeout"),"scope":"state-aware deterministic controller; no human difficulty or animation approval"}
		result["contacts"] = observed_contacts
		result["weak_contacts"] = observed_weak_contacts
		result["parts"] = observed_parts
		var required := "--require-weakness" in OS.get_cmdline_user_args()
		var passed: bool = monster.health<=0 and observed_contacts>0 and (not required or observed_weak_contacts>0)
		result["passed"] = passed
		var file := FileAccess.open("res://../Shubian-encounter-"+controller_name+"-"+str(monster.data.id)+".json",FileAccess.WRITE)
		file.store_string(JSON.stringify(result,"  "))
		print("ENCOUNTER_REPLAY: ",JSON.stringify(result))
		for action in ["move_left","move_right","move_forward","move_back","sprint"]: Input.action_release(action)
		await create_timer(0.25).timeout
		world.queue_free()
		await process_frame
		quit(0 if passed else 1)
		return
	if c.action in ["hurt","finisher","fourfold","spin","flash"]: return
	if c.action!="idle" and c.elapsed<float(c.MOVES[c.action].chain): return
	var next := ""
	if c.guard_reward>0: next = "reply"
	elif c.flash_window>0: next = "flash"
	elif monster.phase=="windup" and monster.clock>0.35: next = "guard"
	elif monster.phase in ["recover","idle"]:
		if not c.shadow_lifetimes.is_empty(): next = "spin"
		else: next = "light" if last_attack=="heavy" else "heavy"
	if next!="" and c.request(next):
		decisions += 1
		if next in ["light","heavy"]: last_attack = next
