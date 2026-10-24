extends Node3D
const Visuals = preload("res://scripts/visuals.gd")
var shooter: CharacterBody3D
var direction := Vector3.FORWARD
var speed := 27.0
var remaining := 16.0
var amount := 36.0
var finished := false
var arrival_cancelled := false
var visual: Node3D

func _ready() -> void:
	visual = Visuals.trident(self)
	visual.rotation.x = -PI/2
	look_at(global_position+direction)
	add_to_group("projectiles")

func _physics_process(delta: float) -> void:
	if finished: return
	if not is_instance_valid(shooter):
		finished = true
		queue_free()
		return
	var distance := minf(remaining,speed*delta)
	var end := global_position+direction*distance
	var query := PhysicsRayQueryParameters3D.create(global_position,end)
	if is_instance_valid(shooter): query.exclude = [shooter.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var impact_origin := global_position
		global_position = hit.position
		if hit.collider.has_method("receive_strike"):
			var part: String = preload("res://scripts/monster_parts.gd").at_point(hit.collider,hit.position)
			var result: Dictionary = hit.collider.receive_strike(amount,impact_origin,"throw",part)
			shooter.show_hit_feedback(hit.position,result,"throw")
		finish()
		return
	global_position = end
	remaining -= distance
	if remaining<=0: finish()

func cancel_arrival() -> void:
	arrival_cancelled = true

func finish() -> void:
	if finished: return
	finished = true
	if is_instance_valid(shooter) and shooter.projectile==self: shooter.finish_throw(global_position-direction*0.6,not arrival_cancelled)
	queue_free()
