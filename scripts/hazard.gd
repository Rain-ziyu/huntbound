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
var source_actor: CollisionObject3D
var mist_material: ShaderMaterial
var boundary: MeshInstance3D
var puffs: Array[MeshInstance3D] = []
var visual_age := 0.0

func _ready() -> void:
	add_to_group("hazards")
	surface = Visuals.piece(self,Vector3(0,0.10,0),Vector3(radius*2,0.12,radius*2),Color("79a64b") if kind=="mist" else Color("78cfe2"),true)
	var material := surface.material_override as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.45
	if kind=="mist":
		material.albedo_color.a = 0.12
		var disc := CylinderMesh.new()
		disc.top_radius = radius
		disc.bottom_radius = radius
		disc.height = 0.02
		disc.radial_segments = 64
		surface.mesh = disc
		surface.scale = Vector3.ONE
		mist_material = ShaderMaterial.new()
		mist_material.shader = preload("res://shaders/hazard_mist.gdshader")
		mist_material.set_shader_parameter("density",1.0)
		boundary = MeshInstance3D.new()
		boundary.name = "DangerBoundary"
		var ring := TorusMesh.new()
		ring.inner_radius = maxf(0.01,radius-0.04)
		ring.outer_radius = radius+0.04
		ring.rings = 64
		ring.ring_segments = 8
		boundary.mesh = ring
		boundary.material_override = Visuals.mat(Color("aec878"),true)
		boundary.position.y = 0.1
		add_child(boundary)
		for i in 7:
			var angle := i*TAU/7
			var puff := Visuals.piece(self,Vector3(cos(angle)*radius*0.5,0.7,sin(angle)*radius*0.5),Vector3(radius*0.7,1.1,radius*0.7),Color("7ea866"),true)
			puff.material_override = mist_material
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			puffs.append(puff)

func _process(delta: float) -> void:
	if kind!="mist": return
	visual_age += delta
	mist_material.set_shader_parameter("density",clampf(lifetime/0.6,0,1))
	for index in puffs.size(): puffs[index].position.y = 0.7+sin(visual_age*0.9+index*0.8)*0.09

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime<=0:
		queue_free()
		return
	clock -= delta
	if clock<=0:
		clock += interval
		if contains_target(): target.take_damage(damage,global_position,false,kind!="mist")

func contains_target() -> bool:
	if not is_instance_valid(target) or target.combat.health<=0: return false
	var offset := target.global_position-global_position
	if Vector2(offset.x,offset.z).length()>=radius or absf(offset.y)>=2.0: return false
	var query := PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,target.global_position+Vector3.UP)
	query.exclude = [target.get_rid()]
	if is_instance_valid(source_actor): query.exclude = [target.get_rid(),source_actor.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
