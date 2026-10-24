extends "res://tools/replay_animation_study.gd"
## Frozen-monster body-turn presentation study, not a combat difficulty test.
var study_clock := 0.0
var launched := false
func setup() -> void:
	await super.setup()
	fighter.combat.set_action("idle")
	fighter.combat.drawn = true
	fighter.animate(0,0)
func step() -> void:
	if finished: return
	study_clock += 1.0/60
	if study_clock>=0.4 and not launched:
		launched = true
		fighter.combat.request("turn")
	fighter.combat.advance(1.0/60)
	fighter.animate(1.0/60,0)
	title.text = "戍边 / 转身甩枪动作研究（非实战）\n全身转向与换步 / 镜头与战斗朝向独立"
	if study_clock>=1.9:
		finished = true
		finish.call_deferred()
func finish() -> void:
	print("TURN_STUDY_FINISHED: camera yaw=",fighter.yaw," body residual=",fighter.body_turn_applied)
	world.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit()
