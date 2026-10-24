extends "res://tests/replay_multi_enemy.gd"
func setup() -> void:
	await super.setup()
	world.hud.get_parent().hide()
	var overview := Camera3D.new()
	world.add_child(overview)
	overview.position = Vector3(10,7,-3)
	overview.look_at(Vector3(0,1,-10))
	overview.make_current()
	await create_timer(3.0).timeout
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Shubian-multi-enemy.png"))
	print("MULTI_ENEMY_CAPTURE: ",result)
