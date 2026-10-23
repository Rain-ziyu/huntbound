extends SceneTree
const Model = preload("res://scripts/hunter_model.gd")
func _initialize() -> void:
	var holder := Node3D.new()
	var rig := Model.create(holder)
	rig.weapon.position = Vector3(0,1.05,0.26)
	rig.weapon.rotation.z = 0.35
	Model.pose_arms(rig,false,0)
	assign_owners(rig.root,rig.root)
	var scene := PackedScene.new()
	var error := scene.pack(rig.root)
	if error==OK: error = ResourceSaver.save(scene,"res://assets/models/hunter-forest-v1.tscn")
	print("MODEL_EXPORT: ",error)
	holder.free()
	quit(0 if error==OK else 1)
func assign_owners(node: Node, root_node: Node) -> void:
	for child in node.get_children():
		child.owner = root_node
		assign_owners(child,root_node)
