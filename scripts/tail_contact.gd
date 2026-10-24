extends RefCounted
## Swept spherical samples fitted to the authored tail rings; still a volume approximation.
static func profile(mesh: Mesh) -> Array[Vector4]:
	var rings := {}
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for point in vertices:
		var key := snappedf(point.z,0.00001)
		if not rings.has(key): rings[key] = Vector4(point.x,point.x,point.y,point.y)
		var bounds: Vector4 = rings[key]
		rings[key] = Vector4(minf(bounds.x,point.x),maxf(bounds.y,point.x),minf(bounds.z,point.y),maxf(bounds.w,point.y))
	var depths := rings.keys()
	depths.sort()
	var result: Array[Vector4] = []
	for depth in depths:
		var bounds: Vector4 = rings[depth]
		result.append(Vector4(depth,(bounds.z+bounds.w)*0.5,maxf(bounds.y-bounds.x,bounds.w-bounds.z)*0.5,0))
	return result

static func touches(rings: Array[Vector4], before: Transform3D, after: Transform3D, feet: Vector3) -> bool:
	var low := feet+Vector3.UP*0.32
	var high := feet+Vector3.UP*1.48
	for index in range(rings.size()-1):
		var first := rings[index]
		var last := rings[index+1]
		var steps := maxi(1,ceili(absf(last.x-first.x)/0.08))
		for step in range(steps+1):
			var ring := first.lerp(last,float(step)/steps)
			var center := Vector3(0,ring.y,ring.x)
			var closest := Geometry3D.get_closest_points_between_segments(before*center,after*center,low,high)
			# Half sample spacing closes gaps between adjacent spheres.
			if closest[0].distance_to(closest[1])<=0.32+ring.z+0.04: return true
	return false
