extends "res://tests/replay_encounter.gd"
func _init() -> void: controller_name = "tactical_movement"
## Uses ordinary mapped movement and combat requests; has privileged AI state knowledge.
func control() -> void:
	if result_saved: return
	var c = fighter.combat
	for action in ["move_left","move_right","move_forward","move_back","sprint"]: Input.action_release(action)
	if c.health<=0 or monster.health<=0 or elapsed>=120:
		super.control()
		return
	var away := fighter.global_position-monster.global_position
	away.y = 0
	var danger := false
	var escape := Vector3.ZERO
	# React to the visible, locked mist landing warning before the zone appears.
	if monster.data.pattern=="mist" and monster.phase=="windup" and monster.clock>=float(monster.data.windup)*0.7:
		var warned_offset: Vector3 = fighter.global_position-monster.target_point
		warned_offset.y = 0
		if warned_offset.length()<4.8:
			danger = true
			escape += warned_offset.normalized()
	for hazard in get_nodes_in_group("hazards"):
		var offset: Vector3 = fighter.global_position-hazard.global_position
		offset.y = 0
		if offset.length()<hazard.radius+0.8:
			danger = true
			escape += offset.normalized()
	if monster.data.pattern=="pulse" and monster.phase in ["windup","active"]:
		if away.length()<float(monster.data.reach)+1.2:
			danger = true
			escape += away.normalized()
	if danger and monster.data.pattern=="mist": escape = away.normalized()+away.normalized().cross(Vector3.UP)*0.65
	var movement := escape.normalized() if danger else (-away.normalized() if away.length()>2.7 else Vector3.ZERO)
	var local := movement.rotated(Vector3.UP,-fighter.yaw)
	if local.x>0.1: Input.action_press("move_right",local.x)
	if local.x< -0.1: Input.action_press("move_left",-local.x)
	if local.z>0.1: Input.action_press("move_back",local.z)
	if local.z< -0.1: Input.action_press("move_forward",-local.z)
	if danger:
		Input.action_press("sprint")
		if c.request("dodge"): decisions += 1
		elapsed += 1.0/60.0
		return
	if monster.data.pattern not in ["mist","pulse"]:
		super.control()
		return
	elapsed += 1.0/60.0
	if away.length()>4: return
	if c.action!="idle" and (c.action in ["hurt","dodge"] or c.elapsed<float(c.MOVES[c.action].chain)): return
	if monster.phase in ["idle","recover","windup"]:
		var next := "light" if last_attack=="heavy" else "heavy"
		if c.request(next):
			last_attack = next
			decisions += 1
