extends "res://tests/replay_encounter.gd"
## Fixed button schedule, no enemy phase/clock/weakpoint reads during decisions.
var next_button := 0.20
var next_guard := 1.0
var next_dodge := 2.0
var button_index := 0
var damage_events := 0
var previous_health := 240.0
func setup() -> void:
	await super.setup()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	fighter.camera_manual_time = 0
func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	fighter._unhandled_input(event)
func click(right: bool, combo: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT if right else MOUSE_BUTTON_LEFT
	event.ctrl_pressed = combo
	event.pressed = true
	fighter._unhandled_input(event)
	event.pressed = false
	fighter._unhandled_input(event)
func control() -> void:
	if result_saved: return
	elapsed += 1.0/60
	if fighter.combat.health<previous_health: damage_events += 1
	previous_health = fighter.combat.health
	# Health is observed only to end/report the trial, never to select an action.
	if fighter.combat.health<=0 or monster.health<=0 or elapsed>=60:
		finish_trial()
		return
	Input.action_press("move_forward")
	if elapsed>=next_guard:
		key(KEY_Q)
		next_guard += 2.1
	if elapsed>=next_dodge:
		key(KEY_SPACE)
		next_dodge += 3.7
	if elapsed>=next_button:
		var slot := button_index%5
		click(slot in [1,3],slot==4)
		button_index += 1
		next_button += 0.24
func finish_trial() -> void:
	result_saved = true
	Input.action_release("move_forward")
	var outcome := "defeat" if fighter.combat.health<=0 else ("victory" if monster.health<=0 else "timeout")
	var report := {"completed":true,"species":monster.data.id,"outcome":outcome,"seconds":snappedf(elapsed,0.01),"player_health":fighter.combat.health,"monster_health":monster.health,"contacts":observed_contacts,"weak_contacts":observed_weak_contacts,"damage_events":damage_events,"attack_clicks":button_index,"input_profile":"fixed_v1: hold forward with normal camera lock; alternating mouse every .24s, Ctrl-left every fifth click, Q every 2.1s, dodge every 3.7s","scope":"one live monster, controlled initial placement and target lock, other four AIs frozen; no enemy phase or weakness reads to select input, no injected combat resources; not human difficulty acceptance"}
	print("FIXED_INPUT_REPLAY: ",JSON.stringify(report))
	world.queue_free()
	await process_frame
	quit()
