extends Node3D
const Visuals = preload("res://scripts/visuals.gd")
var shooter: CharacterBody3D
var direction := Vector3.FORWARD
var speed := 27.0
var remaining := 16.0
var amount := 36.0
var finished := false
var visual: Node3D

func _ready() -> void:
	visual = Visuals.trident(self)
	visual.rotation.x = -PI/2
	look_at(global_position+direction)
	add_to_group("projectiles")

func _physics_process(delta: float) -> void:
	if finished: return
	var distance := minf(remaining,speed*delta)
	var end := global_position+direction*distance
	var query := PhysicsRayQueryParameters3D.create(global_position,end)
	if is_instance_valid(shooter): query.exclude = [shooter.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit.position
		if hit.collider.has_method("receive_strike"):
			hit.collider.receive_strike(amount,shooter.global_position,"throw")
		finish()
		return
	global_position = end
	remaining -= distance
	if remaining<=0: finish()

func finish() -> void:
	if finished: return
	finished = true
	if is_instance_valid(shooter): shooter.finish_throw(global_position-direction*0.6)
	queue_free()
