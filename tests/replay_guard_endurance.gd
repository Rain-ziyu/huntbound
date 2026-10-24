extends "res://tests/replay_encounter.gd"
var minimum_stamina := 100.0
var blocks := 0
var damage_events := 0
var last_health := 240.0
var had_reward := false
func control() -> void:
	if result_saved: return
	elapsed += 1.0/60
	var c = fighter.combat
	minimum_stamina = minf(minimum_stamina,c.stamina)
	if c.health<last_health: damage_events += 1
	last_health = c.health
	if c.guard_reward>0 and not had_reward: blocks += 1
	had_reward = c.guard_reward>0
	if c.health<=0 or elapsed>=60:
		result_saved = true
		var pressure: bool = minimum_stamina<15 and damage_events>=3
		var passed: bool = not "--expect-pressure" in OS.get_cmdline_user_args() or pressure
		var result := {"passed":passed,"pressure_observed":pressure,"seconds":elapsed,"health":c.health,"stamina":c.stamina,"minimum_stamina":minimum_stamina,"blocks":blocks,"damage_events":damage_events,"monster_health":monster.health,"scope":"repeated guard requests when idle, no movement or attacks, no AI phase timing, no injected health damage or stamina"}
		FileAccess.open("res://../Shubian-guard-endurance.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
		print("GUARD_ENDURANCE_REPLAY: ",JSON.stringify(result))
		world.queue_free()
		await process_frame
		quit(0 if passed else 1)
		return
	if c.action=="idle": c.request("guard")
