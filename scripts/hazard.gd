extends Node3D
const Visuals = preload("res://scripts/visuals.gd")
var target: CharacterBody3D
var radius := 4.0
var lifetime := 6.0
var interval := 0.8
var damage := 9.0
var clock := 0.0
var kind := "mist"
var surface: MeshInstance3D

func _ready() -> void:
	add_to_group("hazards")
	surface = Visuals.piece(self,Vector3(0,0.10,0),Vector3(radius*2,0.12,radius*2),Color("79a64b") if kind=="mist" else Color("78cfe2"),true)
	var material := surface.material_override as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.45
	if kind=="mist":
		for i in 7:
			var angle := i*TAU/7
			var puff := Visuals.piece(self,Vector3(cos(angle)*radius*0.5,0.7,sin(angle)*radius*0.5),Vector3(radius*0.7,1.1,radius*0.7),Color("7ea866"),true)
			puff.material_override = material

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime<=0:
		queue_free()
		return
	clock -= delta
	if clock<=0:
		clock += interval
		if contains_target(): target.take_damage(damage,global_position,false)

func contains_target() -> bool:
	if not is_instance_valid(target) or target.combat.health<=0: return false
	var offset := target.global_position-global_position
	return Vector2(offset.x,offset.z).length()<radius and absf(offset.y)<2.0
