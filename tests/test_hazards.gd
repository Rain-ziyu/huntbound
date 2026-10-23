extends SceneTree
const Hazard = preload("res://scripts/hazard.gd")
var failed := 0
var checks := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failed += 1
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
	var cloud := Hazard.new()
	cloud.target = p
	world.add_child(cloud)
	cloud.set_physics_process(false)
	cloud.global_position = p.global_position
	p.combat.set_action("idle")
	var hp: float = p.combat.health
	cloud._physics_process(0.01)
	check(p.combat.health==hp-9,"inside mist takes damage")
	cloud._physics_process(0.2)
	check(p.combat.health==hp-9,"mist does not damage every frame")
	cloud._physics_process(0.61)
	check(p.combat.health==hp-18,"mist persists and repeats")
	p.global_position.x += 10
	cloud._physics_process(0.81)
	check(p.combat.health==hp-18,"leaving mist avoids damage")
	cloud._physics_process(6)
	check(cloud.is_queued_for_deletion(),"mist lifetime is bounded")
	for m in get_nodes_in_group("monsters"):
		if m.data.pattern in ["mist","pulse"]:
			p.global_position = m.global_position-m.global_basis.z*3
			m.phase = "active"
			m.attack_done = false
			m.target_point = p.global_position
			var before: int = get_nodes_in_group("hazards").size()
			m._physics_process(0.01)
			check(get_nodes_in_group("hazards").size()==before+1,"species creates actual zone: "+str(m.data.id))
			m._physics_process(0.01)
			check(get_nodes_in_group("hazards").size()==before+1,"one zone per action: "+str(m.data.id))
	print("HAZARD_CHECKS: ",checks," FAILURES: ",failed)
	world.queue_free()
	await process_frame
	quit(1 if failed else 0)
