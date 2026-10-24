extends "res://tools/replay_animation_study.gd"
## Frozen-monster presentation study with a fixture lethal hit.
var study_clock := 0.0
var fallen := false
func setup() -> void:
	await super.setup()
	fighter.global_position = Vector3(0,0.05,0)
	fighter.combat.set_action("idle")
	fighter.combat.drawn = true
	fighter.animate(0,0)
	var camera := root.get_camera_3d()
	camera.position = fighter.global_position+Vector3(3,2,4.5)
	camera.look_at(fighter.global_position+Vector3(0.7,0.7,0))
	camera.fov = 40
func step() -> void:
	if finished: return
	study_clock += 1.0/60
	if study_clock>=0.5 and not fallen:
		fallen = true
		fighter.take_damage(1000,fighter.global_position+Vector3.FORWARD,false)
	fighter.combat.advance(1.0/60)
	fighter.animate(1.0/60,0)
	title.text = "戍边 / 倒地姿态研究（冻结怪物、测试伤害）\n生命归零后保持倒地 / F5 可重试"
	if study_clock>=2.0 and not captured:
		captured = true
		capture.call_deferred()
	if study_clock>=2.25:
		finished = true
		finish.call_deferred()
func capture() -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Shubian-player-defeat.png"))
func finish() -> void:
	print("DEFEAT_STUDY_FINISHED: health=",fighter.combat.health," root tilt=",fighter.rig.root.rotation.z)
	world.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit()
