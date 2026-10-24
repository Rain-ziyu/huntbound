extends SceneTree
const Art = preload("res://scripts/forest_art.gd")
const Terrain = preload("res://scripts/forest_terrain.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	if DisplayServer.get_name()!="headless": await create_timer(0.25).timeout
	world.hunter.set_physics_process(false)
	for m in get_nodes_in_group("monsters"): m.set_physics_process(false)
	var trees := get_nodes_in_group("forest_trees")
	var solids := get_nodes_in_group("forest_tree_collisions")
	check(trees.size()>60 and trees.size()==solids.size(),"each planted tree has a corresponding physical trunk")
	var matching := true
	var clearings := true
	var decorative := true
	for index in trees.size():
		var tree := trees[index] as Node3D
		var height: float = tree.get_meta("trunk_height")
		if tree.position.distance_to(solids[index].position-Vector3.UP*height/2)>0.001: matching = false
		for center in Terrain.CLEARINGS:
			if Vector2(tree.position.x,tree.position.z).distance_to(center)<8.9: clearings = false
		if not tree.find_children("*","CollisionObject3D",true,false).is_empty(): decorative = false
	check(matching,"rendered trunk positions match collision proxies")
	check(clearings,"planted trunks leave all five combat clearings open")
	check(decorative,"branch leaves and wind have no extra collision objects")
	var nodes := get_nodes_in_group("forest_understory")
	check(nodes.size()==1,"understory uses one multimesh group")
	var ferns := nodes[0] as MultiMeshInstance3D
	var safely_placed := true
	var positions: PackedVector3Array = ferns.get_meta("root_positions")
	for position in positions:
		if not Art.clear_for_fern(position): safely_placed = false
		if absf(position.y-Terrain.height_at(position.x,position.z))>0.001: safely_placed = false
	check(safely_placed,"fern roots follow terrain and avoid paths water and combat clearings")
	if DisplayServer.get_name()!="headless":
		var renderer_matches := true
		for index in positions.size():
			if ferns.multimesh.get_instance_transform(index).origin.distance_to(positions[index])>0.001: renderer_matches = false
		check(renderer_matches,"renderer uses authored fern instance positions")
	else: print("FERN_RENDERER_READBACK: skipped on headless dummy renderer")
	check(ferns.multimesh.instance_count>100,"understory has distributed fern clumps")
	var terrain = get_nodes_in_group("terrain")[0]
	check(terrain.get_node("WetGround").material_override is ShaderMaterial,"wet ground shader is installed")
	check(terrain.get_node("ShallowStream").material_override is ShaderMaterial,"flowing surface shader is installed")
	check(get_nodes_in_group("forest_backdrop").size()==1,"rocky boundary backdrop exists")
	var cliff: MeshInstance3D = get_nodes_in_group("forest_backdrop")[0]
	var normals: PackedVector3Array = cliff.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	check(normals[0].dot(Vector3.LEFT)>0.9,"boundary rock face points toward playable interior")
	print("FOREST_ART_CHECKS: ",checks," FAILURES: ",failures," TREES: ",trees.size()," FERNS: ",ferns.multimesh.instance_count)
	world.queue_free()
	await process_frame
	if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw
	quit(1 if failures else 0)
