extends RefCounted
## Preserve physical bindings while accepting logical-only injected key events.
var pressed_actions := {}
const MOVEMENT := ["move_forward","move_back","move_left","move_right","sprint"]
static func code(event: InputEventKey) -> Key:
	return event.physical_keycode if event.physical_keycode!=0 else event.keycode
func movement(event: InputEventKey) -> void:
	if event.physical_keycode!=0: return
	for action in MOVEMENT:
		if not InputMap.has_action(action): continue
		for binding in InputMap.action_get_events(action):
			if binding is InputEventKey and binding.physical_keycode!=0 and binding.physical_keycode==event.keycode:
				if event.pressed:
					Input.action_press(action)
					pressed_actions[action] = true
				else:
					Input.action_release(action)
					pressed_actions.erase(action)
				break
func release() -> void:
	for action in pressed_actions: Input.action_release(action)
	pressed_actions.clear()
