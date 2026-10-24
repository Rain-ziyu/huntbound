extends SceneTree
const Terrain = preload("res://scripts/forest_terrain.gd")
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
	var stage := Node3D.new()
	root.add_child(stage)
	var terrain := Terrain.new()
	stage.add_child(terrain)
	var water: MeshInstance3D = terrain.get_node("ShallowStream")
	var water_bounds: AABB = water.global_transform*water.get_aabb()
	await physics_frame
	await physics_frame
	var space := stage.get_world_3d().direct_space_state
	for point in [Vector2(38.3,12.7),Vector2(48.7,38.4),Vector2(-44.2,-42.8),Vector2(7.4,2.3),Vector2(59.9,5.1)]:
		var query := PhysicsRayQueryParameters3D.create(Vector3(point.x,10,point.y),Vector3(point.x,-10,point.y),2)
		var hit := space.intersect_ray(query)
		check(not hit.is_empty() and absf(hit.position.y-Terrain.mesh_height_at(point.x,point.y))<0.001,"terrain helper matches actual collision triangles")
	check(is_equal_approx(Terrain.effect_height_at(41,12),water_bounds.end.y),"effect height stays above actual opaque water surface")
	var cloud := Hazard.new()
	stage.add_child(cloud)
	cloud.set_physics_process(false)
	cloud.set_process(false)
	cloud.global_position = Vector3(38,Terrain.mesh_height_at(38,12)+0.05,12)
	await process_frame
	await process_frame
	check(cloud.boundary.mesh is ArrayMesh,"deferred projection uses final spawn position")
	var vertices: PackedVector3Array = cloud.boundary.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var low := 100.0
	var high := -100.0
	var radial_error := 0.0
	var height_error := 0.0
	for index in range(0,vertices.size(),16):
		var point := cloud.boundary.to_global(vertices[index])
		low = minf(low,point.y)
		high = maxf(high,point.y)
		var query := PhysicsRayQueryParameters3D.create(point+Vector3.UP*5,point-Vector3.UP*5,2)
		var hit := space.intersect_ray(query)
		if hit.is_empty(): height_error = 100
		else:
			var visible_floor: float = hit.position.y
			if point.x>=water_bounds.position.x and point.x<=water_bounds.end.x and point.z>=water_bounds.position.z and point.z<=water_bounds.end.z:
				visible_floor = maxf(visible_floor,water_bounds.end.y)
			height_error = maxf(height_error,absf(point.y-visible_floor-0.08))
		var distance := Vector2(vertices[index].x,vertices[index].z).length()
		radial_error = maxf(radial_error,minf(absf(distance-(cloud.radius-0.04)),absf(distance-(cloud.radius+0.04))))
	check(high-low>0.4,"boundary follows real height variation rather than remaining flat")
	check(height_error<0.002,"boundary fits actual terrain collision with consistent lift")
	check(radial_error<0.001,"terrain conformity preserves horizontal damage radius")
	var fill: PackedVector3Array = cloud.surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var fill_error := 0.0
	for point in fill:
		var world_point := cloud.surface.to_global(point)
		fill_error = maxf(fill_error,absf(world_point.y-Terrain.effect_height_at(world_point.x,world_point.z)-0.06))
	check(fill_error<0.001 and fill.size()>1000,"subdivided interior fits terrain instead of bridging the slope")
	var normals: PackedVector3Array = cloud.boundary.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	var faces_up := true
	for normal in normals: faces_up = faces_up and normal.y>0
	check(faces_up,"projected boundary faces upward")
	var puff_error := 0.0
	for index in cloud.puffs.size():
		var puff: MeshInstance3D = cloud.puffs[index]
		var point := cloud.to_global(Vector3(puff.position.x,cloud.puff_base_y[index],puff.position.z))
		puff_error = maxf(puff_error,absf(point.y-Terrain.effect_height_at(point.x,point.z)-0.7))
	check(puff_error<0.001,"fog puffs follow their local terrain heights")
	var lifetime := cloud.lifetime
	var timer := cloud.clock
	var projected_start := Time.get_ticks_usec()
	cloud.conform_ground()
	var projected_ms := float(Time.get_ticks_usec()-projected_start)/1000
	check(cloud.lifetime==lifetime and cloud.clock==timer,"projection does not advance combat clocks")
	print("HAZARD_GROUND_CHECKS: ",checks," FAILURES: ",failures," HEIGHT_SPAN=",high-low," ERROR=",height_error," PROJECT_MS=",projected_ms)
	stage.queue_free()
	await process_frame
	quit(1 if failures else 0)
