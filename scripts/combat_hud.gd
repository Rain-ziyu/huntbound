extends CanvasLayer
const ACTION_NAMES := {"light":"斜刺","heavy":"横扫","pull":"钩齿回拉","turn":"转身甩枪","guard":"枪尾架势","reply":"枪尾反击","flash":"闪刺","throw":"投枪","fourfold":"枪意 · 四连刺","spin":"枪意 · 旋枪","plant":"插地蓄势","wait":"插地等待","counter_window":"迎击架势","finisher":"旋枪踢击","dodge":"闪避","hurt":"受击"}
const PART_NAMES := {"body":"躯干","head":"头部","tail":"尾部","flank":"侧腹","spine":"背棘"}
var surface: Control
var status: Label
var health_text: Label
var stamina_text: Label
var health: ProgressBar
var stamina: ProgressBar
var shadows: Label
var shadow_bars: Array[ProgressBar] = []
var shadow_times: Array[Label] = []
var context: Label
var help: Label
var target_text: Label
var target_health: ProgressBar
var notice: Label
func text_at(position: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = position
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color("ede9da"))
	label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x",1)
	label.add_theme_constant_override("shadow_offset_y",2)
	surface.add_child(label)
	return label
func bar_at(position: Vector2, dimensions: Vector2, maximum: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = position
	bar.max_value = maximum
	bar.show_percentage = false
	bar.add_theme_font_size_override("font_size",1)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.05,0.09,0.08,0.85)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background",background)
	bar.add_theme_stylebox_override("fill",fill)
	surface.add_child(bar)
	bar.size = dimensions
	return bar
func _ready() -> void:
	surface = Control.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surface)
	health_text = text_at(Vector2(22,16),19)
	health = bar_at(Vector2(22,44),Vector2(248,14),240,Color("bc6e60"))
	stamina_text = text_at(Vector2(22,65),16)
	stamina = bar_at(Vector2(22,89),Vector2(248,9),100,Color("bab67c"))
	shadows = text_at(Vector2(22,109),17)
	for i in 5:
		shadow_bars.append(bar_at(Vector2(22+i*50,138),Vector2(42,8),180,Color("83bdb1")))
		shadow_times.append(text_at(Vector2(22+i*50,152),13))
	status = text_at(Vector2(22,184),17)
	notice = text_at(Vector2(22,238),16)
	context = text_at(Vector2(22,0),20)
	context.anchor_top = 1
	context.anchor_bottom = 1
	context.offset_top = -78
	var hints := text_at(Vector2(22,0),15)
	hints.anchor_top = 1
	hints.anchor_bottom = 1
	hints.offset_top = -34
	hints.text = "WASD 移动  ·  空格闪避  ·  中键锁定 / Tab 切换  ·  F1 操作说明  ·  F5 重试"
	help = text_at(Vector2(22,280),17)
	help.text = "操作说明 · 不暂停战斗\n左键斜刺 / 右键短按横扫、长按松开投枪瞬移\nE 回拉 / Alt+左键转身 / Q 架势 / R 收枪\n格挡成功 → 左键反击 → Ctrl+左键闪刺\n有枪影：Ctrl+左键四连刺 / Ctrl+右键旋枪\n拔枪后 Ctrl+空格插地，再按 Ctrl 迎击\nTab 切换目标 / Shift+Tab 反向切换\nShift 奔跑 / Esc 切换鼠标 / F1 收起说明"
	help.hide()
	target_text = text_at(Vector2.ZERO,17)
	target_text.anchor_left = 0.5
	target_text.anchor_right = 0.5
	target_text.offset_left = -280
	target_text.offset_right = 280
	target_text.offset_top = 18
	target_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_text.offset_bottom = 160
	target_health = bar_at(Vector2.ZERO,Vector2(440,9),1,Color("b49368"))
	target_health.anchor_left = 0.5
	target_health.anchor_right = 0.5
	target_health.offset_left = -220
	target_health.offset_right = 220
	target_health.offset_top = 46
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F1:
		help.visible = not help.visible
		get_viewport().set_input_as_handled()
static func followup(c, held: float) -> String:
	if c.health<=0: return "任务失败 · F5 重试"
	if c.action=="wait": return "插地等待 %ds · 按 Ctrl 迎击" % ceili(maxf(0,30-c.elapsed))
	if c.action=="counter_window": return "迎击架势 · 接住来袭攻击"
	if c.guard_reward>0: return "格挡成功 · 左键枪尾反击"
	if c.flash_window>0: return "追击机会 · Ctrl+左键闪刺"
	if held>=0: return "投枪就绪 · 松开右键" if held>=0.45 else "松开右键横扫 · 继续按住准备投枪"
	if not c.drawn: return "背负待机 · 左键或右键拔枪出招"
	if not c.shadow_lifetimes.is_empty(): return "枪意就绪 · Ctrl+左键四连刺 / Ctrl+右键旋枪"
	return "Q 架势 → 左键反击 → Ctrl+左键闪刺获得枪影"
func update_state(fighter, defeated: int) -> void:
	var c = fighter.combat
	health.value = c.health
	stamina.value = c.stamina
	health_text.text = "生命 %d / 240" % ceili(c.health)
	stamina_text.text = "耐力 %d / 100" % floori(c.stamina)
	shadows.text = "枪影 %d / 5" % c.shadow_lifetimes.size()
	if not c.shadow_lifetimes.is_empty(): shadows.text += "  攻击 +%d%%" % (c.shadow_lifetimes.size()*10)
	for i in 5:
		var remaining: float = c.shadow_lifetimes[i] if i<c.shadow_lifetimes.size() else 0
		shadow_bars[i].value = remaining
		shadow_times[i].text = "%d:%02d" % [ceili(remaining)/60,ceili(remaining)%60] if remaining>0 else "—"
	var action: String = ACTION_NAMES.get(c.action,"持枪待机" if c.drawn else "背负待机")
	status.text = "击退 %d / 5\n%s" % [defeated,action]
	if c.health<=0: status.text = "任务失败 · F5 重试"
	elif defeated==5: status.text = "林地已清理 · F5 重新挑战"
	context.text = "林地已清理 · F5 重新挑战" if c.health>0 and defeated==5 else followup(c,fighter.heavy_held)
	notice.text = fighter.message if fighter.message!="观察金色预警后躲避或格挡。" and c.health>0 else ""
	for part in PART_NAMES: notice.text = notice.text.replace(part,PART_NAMES[part])
	var locked: bool = is_instance_valid(fighter.lock_target) and fighter.lock_target.health>0
	target_text.visible = locked
	target_health.visible = locked
	if locked:
		var target = fighter.lock_target
		target_text.text = "%s  %d / %d\n\n%s\n对策：%s" % [target.data.name,ceili(target.health),int(target.data.health),target.data.trait,target.data.weakness]
		target_health.max_value = target.data.health
		target_health.value = target.health
