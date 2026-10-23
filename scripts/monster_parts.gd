extends RefCounted
## Model-space spherical hit volumes, transformed with the articulated model.
static func volumes(monster: Node3D) -> Array[Dictionary]:
	var s: float = monster.data.size
	var y := s*0.50 if "quadruped" in monster.data.body else s*0.64
	var mesh: Node3D = monster.mesh
	var result: Array[Dictionary] = [
		{"id":"head","center":mesh.get_node("Neck").to_global(Vector3(0,s*0.14,-s*0.40)),"radius":s*0.26},
		{"id":"tail","center":mesh.get_node("Tail").to_global(Vector3(0,0,s*0.18)),"radius":s*0.24},
		{"id":"flank","center":mesh.to_global(Vector3(s*0.33,y,0)),"radius":s*0.24},
		{"id":"flank","center":mesh.to_global(Vector3(-s*0.33,y,0)),"radius":s*0.24},
		{"id":"body","center":mesh.to_global(Vector3(0,y,0)),"radius":s*0.43}
	]
	if monster.data.id=="stormcrest": result.push_front({"id":"spine","center":mesh.to_global(Vector3(0,s*0.86,s*0.15)),"radius":s*0.35})
	return result

static func cast(monster: Node3D, origin: Vector3, direction: Vector3, reach: float) -> Dictionary:
	var result := {}
	var closest := reach+1
	var unit := direction.normalized()
	for part in volumes(monster):
		var offset: Vector3 = origin-part.center
		var b := offset.dot(unit)
		var discriminant := b*b-offset.length_squared()+float(part.radius)*float(part.radius)
		if discriminant<0: continue
		var distance := maxf(0,-b-sqrt(discriminant))
		if -b+sqrt(discriminant)<0 or distance>reach or distance>=closest: continue
		closest = distance
		result = {"part":part.id,"point":origin+unit*distance,"distance":distance}
	return result

static func at_point(monster: Node3D, point: Vector3) -> String:
	# Projectile impact can be on the broad body collider; choose only a volume actually touched.
	for part in volumes(monster):
		if point.distance_to(part.center)<=float(part.radius)+0.12: return part.id
	return "body"
