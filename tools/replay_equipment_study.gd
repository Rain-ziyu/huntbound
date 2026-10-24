extends "res://tools/replay_animation_study.gd"
## Normal action requests and clock, frozen targets; visual inspection, not combat proof.
var stage := 0
var stage_clock := 0.0
func setup() -> void:
	await super.setup()
	fighter.combat.set_action("idle")
	fighter.combat.drawn = false
	fighter.animate(0,0)
func step() -> void:
	if finished: return
	stage_clock += 1.0/60
	fighter.combat.advance(1.0/60)
	fighter.animate(1.0/60,0)
	title.text = "戍边 / 拔枪与收枪过渡研究（非实战回放）\n"+["背负待机","拔枪斜刺","侧上方收枪","拔枪横扫 · 背侧视角","收枪归位"][stage]
	var durations := [0.4,0.95,0.55,1.2,0.55]
	if stage_clock<float(durations[stage]): return
	stage_clock = 0
	stage += 1
	if stage==1: fighter.combat.request("light")
	elif stage in [2,4]: fighter.combat.request("sheathe")
	elif stage==3:
		fighter.combat.request("heavy")
		var camera := root.get_camera_3d()
		camera.position = fighter.global_position+Vector3(4,2.1,4)
		camera.look_at(fighter.global_position+Vector3(0,0.95,0))
	else:
		finished = true
		finish.call_deferred()
func finish() -> void:
	print("EQUIPMENT_STUDY: two draw/sheath cycles; visual inspection only")
	await create_timer(0.25).timeout
	world.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit()
