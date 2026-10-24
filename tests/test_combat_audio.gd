extends SceneTree
const Audio = preload("res://scripts/combat_audio.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var waves: Array[PackedByteArray] = []
	for kind in ["warning","guard","hurt"]:
		var stream := Audio.synthesize(kind)
		var peak := 0
		for i in stream.data.size()/2: peak = maxi(peak,absi(stream.data.decode_s16(i*2)))
		check(stream.mix_rate==22050 and stream.format==AudioStreamWAV.FORMAT_16_BITS,"valid PCM: "+kind)
		check(peak>1000 and peak<32767,"audible signal without clipped samples: "+kind)
		check(absf(stream.get_length()-(0.36 if kind=="warning" else 0.18))<0.001,"bounded cue length: "+kind)
		waves.append(stream.data)
	check(waves[0]!=waves[1] and waves[1]!=waves[2],"three event sounds differ")
	var world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	var p = world.hunter
	p.set_physics_process(false)
	for m in get_nodes_in_group("monsters"): m.set_physics_process(false)
	p.combat.set_action("guard")
	p.combat.advance(0.2)
	p.take_damage(20,p.global_position-Vector3.FORWARD,false)
	check(get_nodes_in_group("combat_audio").size()==1,"real damage emits one cue")
	p.combat.set_action("guard")
	p.combat.advance(0.2)
	p.take_damage(20,p.global_position- p.rig.root.global_basis.z,true)
	var cues := get_nodes_in_group("combat_audio")
	check(cues.size()==2 and cues[-1].cue=="guard","successful frontal guard emits guard cue")
	p.combat.set_action("reply")
	p.take_damage(20,p.global_position,true)
	check(get_nodes_in_group("combat_audio").size()==2,"immune damage emits no false hurt cue")
	var m = get_nodes_in_group("monsters")[0]
	m.global_position = Vector3(0,0.05,-10)
	p.global_position = Vector3(0,0.05,-7)
	m.phase = "idle"
	m.stagger = 0
	m.rear_cooldown = 0
	await physics_frame
	await physics_frame
	m._physics_process(0.016)
	check(m.phase=="windup" and get_nodes_in_group("combat_audio").size()==3,"live AI attack entry emits one warning")
	m._physics_process(0.016)
	check(get_nodes_in_group("combat_audio").size()==3,"continued windup does not repeat warning every frame")
	for cue in get_nodes_in_group("combat_audio"):
		check(cue is AudioStreamPlayer3D and cue.max_distance<=28,"spatial distance is bounded")
		cue._process(0.6)
	await process_frame
	await process_frame
	check(get_nodes_in_group("combat_audio").is_empty(),"cues clean up even with headless playback disabled")
	print("COMBAT_AUDIO_CHECKS: ",checks," FAILURES: ",failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
