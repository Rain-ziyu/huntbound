extends RefCounted
## Rigid-weighted segmented skin: an editable skeletal asset, not final smooth organic topology.
static func bind(rig: Dictionary) -> Dictionary:
	var root: Node3D = rig.root
	var sources: Array[MeshInstance3D] = []
	collect(root,rig.weapon,sources)
	var skeleton := Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	root.add_child(skeleton)
	skeleton.add_bone("Root")
	skeleton.set_bone_rest(0,Transform3D.IDENTITY)
	var skin := Skin.new()
	skin.add_bind(0,Transform3D.IDENTITY)
	var bindings := []
	var indices := {}
	var rests := {}
	var labels := {}
	for side in [-1,1]:
		var prefix := "Left" if side==-1 else "Right"
		var arm: Dictionary = rig.arms[side]
		var leg: Dictionary = rig.legs[side]
		for item in [[arm.upper,"UpperArm"],[arm.lower,"Forearm"],[arm.hand,"Hand"],[leg.thigh,"Thigh"],[leg.shin,"Shin"],[leg.boot,"Foot"]]:
			labels[item[0].get_instance_id()] = prefix+item[1]
	for i in sources.size():
		var source := sources[i]
		var global_rest := relative_transform(source,root)
		var rest := Transform3D(global_rest.basis.orthonormalized(),global_rest.origin)
		var bone := skeleton.add_bone(labels.get(source.get_instance_id(),"Part_%02d" % i))
		skeleton.set_bone_parent(bone,0)
		skeleton.set_bone_rest(bone,rest)
		skeleton.set_bone_pose_position(bone,rest.origin)
		skeleton.set_bone_pose_rotation(bone,rest.basis.get_rotation_quaternion())
		skin.add_bind(bone,rest.affine_inverse())
		var arrays := source.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var bones := PackedInt32Array()
		var weights := PackedFloat32Array()
		var normal_basis := global_rest.basis.inverse().transposed()
		for vertex in vertices.size():
			vertices[vertex] = global_rest*vertices[vertex]
			if vertex<normals.size(): normals[vertex] = (normal_basis*normals[vertex]).normalized()
			bones.append_array(PackedInt32Array([bone,0,0,0]))
			weights.append_array(PackedFloat32Array([1,0,0,0]))
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var rendered := MeshInstance3D.new()
		rendered.name = "SkinPart_%02d" % i
		rendered.mesh = mesh
		rendered.material_override = source.material_override
		rendered.skeleton = NodePath("..")
		skeleton.add_child(rendered)
		rendered.skin = skin
		source.visible = false
		bindings.append({"source":source,"bone":bone,"rendered":rendered})
		indices[source.get_instance_id()] = bone
		rests[bone] = rest
	# Forearm and hand are true descendants, rather than independent root transforms.
	for side in [-1,1]:
		var arm: Dictionary = rig.arms[side]
		var upper: int = indices[arm.upper.get_instance_id()]
		var lower: int = indices[arm.lower.get_instance_id()]
		var hand: int = indices[arm.hand.get_instance_id()]
		for pair in [[lower,upper],[hand,lower]]:
			var child: int = pair[0]
			var parent: int = pair[1]
			var local: Transform3D = rests[parent].affine_inverse()*rests[child]
			skeleton.set_bone_parent(child,parent)
			skeleton.set_bone_rest(child,local)
			skeleton.set_bone_pose_position(child,local.origin)
			skeleton.set_bone_pose_rotation(child,local.basis.get_rotation_quaternion())
		var leg: Dictionary = rig.legs[side]
		var thigh: int = indices[leg.thigh.get_instance_id()]
		var shin: int = indices[leg.shin.get_instance_id()]
		var boot: int = indices[leg.boot.get_instance_id()]
		for pair in [[shin,thigh],[boot,shin]]:
			var child: int = pair[0]
			var parent: int = pair[1]
			var local: Transform3D = rests[parent].affine_inverse()*rests[child]
			skeleton.set_bone_parent(child,parent)
			skeleton.set_bone_rest(child,local)
			skeleton.set_bone_pose_position(child,local.origin)
			skeleton.set_bone_pose_rotation(child,local.basis.get_rotation_quaternion())
	return {"skeleton":skeleton,"skin":skin,"bindings":bindings}

static func relative_transform(node: Node3D, root: Node3D) -> Transform3D:
	var transform := node.transform
	var parent := node.get_parent()
	while parent!=root:
		transform = parent.transform*transform
		parent = parent.get_parent()
	return transform

static func collect(node: Node, excluded: Node, result: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child==excluded: continue
		if child is MeshInstance3D: result.append(child)
		collect(child,excluded,result)

static func update(rig: Dictionary) -> void:
	if not rig.has("skinning"): return
	var data: Dictionary = rig.skinning
	var skeleton: Skeleton3D = data.skeleton
	for binding in data.bindings:
		var pose := relative_transform(binding.source,rig.root)
		pose.basis = pose.basis.orthonormalized()
		skeleton.set_bone_global_pose(binding.bone,pose)
