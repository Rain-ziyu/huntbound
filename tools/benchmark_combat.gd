extends "res://tests/replay_weapon_sequence.gd"
## Native rendered real-time replay. No fixed-FPS or movie capture allowed.
var started_us := 0
var previous_us := 0
var timings: Array[float] = []
var steady: Array[float] = []
var stalls: Array[Dictionary] = []
var maximum_physics_ms := 0.0
var maximum_process_ms := 0.0
func setup() -> void:
	if DisplayServer.get_name()=="headless":
		printerr("Benchmark requires native rendering")
		quit(2)
		return
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await super.setup()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	fighter.camera_manual_time = 0
	started_us = Time.get_ticks_usec()
	previous_us = started_us
	process_frame.connect(sample_frame)
func sample_frame() -> void:
	var now := Time.get_ticks_usec()
	var frame_ms := (now-previous_us)/1000.0
	previous_us = now
	timings.append(frame_ms)
	if now-started_us>=2000000: steady.append(frame_ms)
	if frame_ms>33.33: stalls.append({"ms":snappedf(frame_ms,0.01),"action":fighter.combat.action,"wall_seconds":(now-started_us)/1000000.0})
	if now-started_us>=2000000:
		maximum_physics_ms = maxf(maximum_physics_ms,Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
		maximum_process_ms = maxf(maximum_process_ms,Performance.get_monitor(Performance.TIME_PROCESS)*1000)
func stats(values: Array[float]) -> Dictionary:
	if values.is_empty(): return {}
	var sorted := values.duplicate()
	sorted.sort()
	var total := 0.0
	var slow := 0
	for value in sorted:
		total += value
		if value>33.33: slow += 1
	return {"frames":sorted.size(),"mean_ms":total/sorted.size(),"p95_ms":sorted[int((sorted.size()-1)*0.95)],"p99_ms":sorted[int((sorted.size()-1)*0.99)],"max_ms":sorted[-1],"over_33ms":slow}
func finish_sequence() -> void:
	var report := {"all_frames":stats(timings),"after_two_seconds":stats(steady),"stalls":stalls,"steady_maximum_physics_ms":maximum_physics_ms,"steady_maximum_process_ms":maximum_process_ms,"viewport":str(root.get_visible_rect().size),"adapter":RenderingServer.get_video_adapter_name(),"vsync_disabled":true,"wall_seconds":(Time.get_ticks_usec()-started_us)/1000000.0,"simulation_seconds":elapsed,"scope":"native uncapped single-monster real combat sequence, other four AI frozen, full forest drawn; local hardware only, excludes initial scene load, not a full-map or human smoothness acceptance"}
	var path := "res://../verification/combat-performance-"+str(int(Time.get_unix_time_from_system()))+".json"
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("COMBAT_PERFORMANCE: ",JSON.stringify(report))
	print("COMBAT_PERFORMANCE_FILE: ",ProjectSettings.globalize_path(path))
	super.finish_sequence()
