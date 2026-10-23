extends SceneTree
var world: Node3D
func _initialize() -> void: call_deferred("run")
func run() -> void:
	world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	var p = world.hunter
	p.set_physics_process(false)
	for m in get_nodes_in_group("monsters"): m.set_physics_process(false)
	var library := AnimationLibrary.new()
	var skeleton: Skeleton3D = p.rig.skinning.skeleton
	for action in ["idle","light","heavy","pull","turn","guard","reply","flash","throw","fourfold","spin","plant","wait","counter_window","finisher","dodge","hurt"]:
		var clip := Animation.new()
		clip.length = float(p.Combat.MOVES.get(action,{"duration":1}).duration)
		if action=="wait": clip.length = 1.0
		if action in ["idle","wait"]: clip.loop_mode = Animation.LOOP_LINEAR
		for bone in range(1,skeleton.get_bone_count()):
			for kind in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D]:
				var track := clip.add_track(kind)
				clip.track_set_path(track,NodePath("Skeleton3D:"+skeleton.get_bone_name(bone)))
		var pos_track := clip.add_track(Animation.TYPE_POSITION_3D)
		clip.track_set_path(pos_track,NodePath("Trident"))
		var rot_track := clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(rot_track,NodePath("Trident"))
		p.combat.set_action(action)
		p.combat.drawn = true
		var frames := ceili(clip.length*30)
		for frame in range(frames+1):
			var t := minf(clip.length,frame/30.0)
			p.combat.elapsed = t
			p.animate(0,0)
			for bone in range(1,skeleton.get_bone_count()):
				clip.position_track_insert_key((bone-1)*2,t,skeleton.get_bone_pose_position(bone))
				clip.rotation_track_insert_key((bone-1)*2+1,t,skeleton.get_bone_pose_rotation(bone))
			clip.position_track_insert_key(pos_track,t,p.rig.weapon.position)
			clip.rotation_track_insert_key(rot_track,t,p.rig.weapon.quaternion)
		library.add_animation(action,clip)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://resources/animations"))
	var error := ResourceSaver.save(library,"res://resources/animations/trident_library.tres")
	print("BAKED_ANIMATIONS: ",library.get_animation_list().size()," RESULT: ",error)
	world.queue_free()
	await process_frame
	quit(0 if error==OK else 1)
