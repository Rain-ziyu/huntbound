extends "res://tools/replay_animation_study.gd"
## Frozen scene pose study with one fixture shadow; not a live encounter.
var study_clock := 0.0
var launched := false
var beats := 0
func setup() -> void:
	await super.setup()
	fighter.combat.set_action("idle")
	fighter.combat.drawn = true
	fighter.combat.shadow_lifetimes.assign([180.0])
	fighter.animate(0,0)
	fighter.combat.strike.connect(func(_beat: int): beats += 1)
func step() -> void:
	if finished: return
	study_clock += 1.0/60
	if study_clock>=0.4 and not launched:
		launched = true
		fighter.combat.request("fourfold")
	fighter.combat.advance(1.0/60)
	fighter.animate(1.0/60,0)
	title.text = "戍边 / 四连刺动作研究（非实战）\n刺出 · 回收 · 再刺 / 命中节拍：%d / 4" % beats
	if study_clock>=2.25:
		finished = true
		finish.call_deferred()
func finish() -> void:
	print("FOURFOLD_STUDY_FINISHED: beats=",beats," fixture shadows remaining=",fighter.combat.shadow_lifetimes.size())
	world.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit(0 if beats==4 else 1)
