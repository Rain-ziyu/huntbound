extends SceneTree
const Hazard = preload("res://scripts/hazard.gd")
var checks := 0
var failures := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
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
	var first := Hazard.new()
	first.target = p
	world.add_child(first)
	first.set_physics_process(false)
	first.set_process(false)
	first.global_position = p.global_position
	var second := Hazard.new()
	second.target = p
	world.add_child(second)
	second.set_physics_process(false)
	second.set_process(false)
	check(first.mist_material!=second.mist_material,"independent clouds own independent fade state")
	var ring := first.boundary.mesh as TorusMesh
	check(is_equal_approx((ring.inner_radius+ring.outer_radius)*0.5,first.radius),"danger boundary is centered on actual damage radius")
	check(first.find_children("*","CollisionObject3D",true,false).is_empty(),"mist visuals do not add blocking collision")
	var hp: float = p.combat.health
	var timer := first.clock
	first.lifetime = 0.3
	first._process(0.2)
	check(is_equal_approx(first.mist_material.get_shader_parameter("density"),0.5),"near-expiry fog fades")
	check(second.mist_material.get_shader_parameter("density")==1.0,"one cloud fading does not fade another")
	check(p.combat.health==hp and first.clock==timer and is_equal_approx(first.lifetime,0.3),"visual animation does not change damage or lifetime clocks")
	p.global_position = first.global_position+Vector3(first.radius-0.01,0,0)
	check(first.contains_target(),"inside boundary remains harmful even when fog fades")
	p.global_position = first.global_position+Vector3(first.radius+0.01,0,0)
	check(not first.contains_target(),"outside boundary remains safe")
	var pulse := Hazard.new()
	pulse.kind = "pulse"
	world.add_child(pulse)
	pulse.set_physics_process(false)
	pulse._process(1)
	check(pulse.mist_material==null and pulse.boundary==null,"mist animation leaves pulse behavior independent")
	print("MIST_VISUAL_CHECKS: ",checks," FAILURES: ",failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
