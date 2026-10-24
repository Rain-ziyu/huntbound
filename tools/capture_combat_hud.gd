extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await create_timer(0.5).timeout
	world.hunter.set_physics_process(false)
	for monster in get_nodes_in_group("monsters"): monster.set_physics_process(false)
	world.hunter.lock_target = get_nodes_in_group("monsters")[0]
	world.combat_hud.update_state(world.hunter,0)
	await RenderingServer.frame_post_draw
	var first := root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Shubian-combat-hud.png"))
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F1
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	await RenderingServer.frame_post_draw
	var second := root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Shubian-combat-help.png"))
	var opened: bool = world.combat_hud.help.visible
	print("COMBAT_HUD_CAPTURE: ",first," / ",second," F1_OPEN=",opened)
	world.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit(0 if first==OK and second==OK and opened else 1)
