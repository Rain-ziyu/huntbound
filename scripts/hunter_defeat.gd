extends RefCounted
## Authored defeat fall, with cached mesh bounds. Not a ragdoll simulation.
var elapsed := 0.0
var started := false
var initial_y := 0.0
var ground_offset := 0.0
var corners: Array[Vector3] = []
func begin(actor: CharacterBody3D) -> void:
	started = true
	actor.heavy_held = -1
	actor.lock_target = null
	actor.strike_windows.clear()
	var rig: Dictionary = actor.rig
	rig.root.rotation.z = 0
	actor.HunterModel.pose_legs(rig,"hurt",0.12,true,0,0,0)
	actor.HunterModel.pose_torso(rig,"hurt",0.12,0,0,0)
	rig.weapon.position = Vector3(0.26,0.95,-0.12)
	rig.weapon.rotation = Vector3(-0.15,0,0.22)
	actor.HunterModel.pose_arms(rig,true,0)
	initial_y = rig.root.position.y
	var sources: Array[MeshInstance3D] = []
	for binding in rig.skinning.bindings: sources.append(binding.source)
	for mesh in rig.weapon.find_children("*","MeshInstance3D",true,false): sources.append(mesh)
	for mesh in sources:
		var transform: Transform3D = rig.root.global_transform.affine_inverse()*mesh.global_transform
		var bounds := mesh.get_aabb()
		for i in 8:
			corners.append(transform*(bounds.position+bounds.size*Vector3(i&1,(i>>1)&1,(i>>2)&1)))
	var excluded: Array[RID] = [actor.get_rid()]
	for creature in actor.get_tree().get_nodes_in_group("monsters"): excluded.append(creature.get_rid())
	ground_offset = -0.05
	for distance in [0.0,0.9,1.8]:
		var point: Vector3 = actor.global_position+rig.root.global_basis.x*distance
		var probe := PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.9,point-Vector3.UP*2,3,excluded)
		var hit := actor.get_world_3d().direct_space_state.intersect_ray(probe)
		if not hit.is_empty(): ground_offset = maxf(ground_offset,hit.position.y-actor.global_position.y)
func update(actor: CharacterBody3D, delta: float) -> void:
	if not started: begin(actor)
	elapsed += delta
	var weight := smoothstep(0.08,0.85,elapsed)
	var fall := Basis(Vector3.FORWARD,weight*PI/2)
	var minimum := INF
	for point in corners: minimum = minf(minimum,(fall*point).y)
	actor.rig.root.rotation.z = -weight*PI/2
	actor.rig.root.position.y = maxf(lerpf(initial_y,0.30,weight),ground_offset-minimum+0.025)
	actor.rig.weapon.visible = not is_instance_valid(actor.projectile)
	for ghost in actor.ghosts: ghost.hide()
