extends Control

const Ambient = preload("res://scripts/island_ambient.gd")
var ambient: Control
var decor_layer: Control
var decor_nodes := {}

const Model = preload("res://scripts/tavern_model.gd")
const Config = preload("res://scripts/day_config.gd")
const Maps = preload("res://scripts/map_config.gd")
const Progress = preload("res://scripts/progress_store.gd")
const NordicProgress = preload("res://scripts/nordic_progress_store.gd")
const NordicEvent = preload("res://scripts/nordic_event.gd")
const Art = preload("res://scripts/art_catalog.gd")
const SEATS: Array[Vector2] = [Vector2(800,710), Vector2(800,220), Vector2(1080,275), Vector2(1270,455), Vector2(1140,620), Vector2(440,620), Vector2(270,455), Vector2(520,275)]
const ITEMS := ["向日葵花瓶", "藤编小灯", "顺手托盘"]
const EFFECTS := ["客人耐心 +5%", "小费 +5%（累计取整）", "制作速度 +5%"]
var model: RefCounted
var progress: RefCounted
var map_progress: RefCounted
var map_id := Maps.MAP01
var art := Art.new()
var current_day := 1
var assisted := false
var decor_shop_page := 0
var modal: Control
var hud: Label
var income_label: Label
var wallet_label: Label
var timer_label: Label
var action_caption: Label
var bubbles: Array[TextureRect] = []
var status: Label
var queue_label: Label
var brew_progress: ProgressBar
var ready_icon: TextureRect
var tutorial_label: Label
var tutorial_panel: Panel
var toast: Label
var toast_panel: Panel
var selection: Label
var action: Button
var discard: Button
var sunny: TextureRect
var held_icon: TextureRect
var seats: Array[Button] = []
var sprites: Array[TextureRect] = []
var bars: Array[ProgressBar] = []
var icons: Array[TextureRect] = []
var arrival_ids := {}
var visit_ids := {}
var visibility := {}
var bubble_labels: Array[Label] = []
var arrival_time := 0.0
var tutorial := false
var tutorial_baseline := 0
var tutorial_time := 0.0
var focus_paused := false
var input_block_frame := -1
var serve_time := 0.0
var service_direction := 0
var service_pulse := 0.0
var feedback_time := 0.0
var sunny_breath_time := 0.0
var previous_coins := 0
var previous_stolen := 0
var previous_missed := 0
var feedback := ""
var fatal := false

func _ready() -> void:
	var system_font := SystemFont.new()
	system_font.font_names = PackedStringArray(["Noto Sans CJK SC", "Microsoft YaHei", "PingFang SC", "WenQuanYi Zen Hei"])
	add_theme_font_override("font", system_font)
	add_theme_color_override("font_color", Color("48270e"))
	var background := texture(self, Vector2(800,450), Vector2(1600,900), art.texture("Island_Background"))
	ambient = Ambient.new()
	add_child(ambient)
	ambient.setup(background)
	setup_decor_layer()
	var guest_layer := Control.new()
	guest_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(guest_layer)
	for i in 8:
		sprites.append(texture(guest_layer, SEATS[i]+Vector2(-30,-35), Vector2(130,130), null))
	texture(self, Vector2(800,450), Vector2(1600,900), art.texture("TableFront_Combined"))
	sunny = texture(self, Vector2(800,435), Vector2(175,175), art.texture("Sunny_Southwind_Idle_v1"))
	for i in 8:
		var selected := i
		seats.append(button(self, SEATS[i]+Vector2(0,50 if i == 0 else 65), Vector2(200,70), "", func(): select_seat(selected)))
		seats[i].add_theme_font_size_override("font_size", 15)
		var bubble := texture(self, SEATS[i]+Vector2(0,-78), Vector2(210,98), art.ui_texture("UI_OrderBubble_Southwind_v1"))
		bubble.z_index = 12
		bubbles.append(bubble)
		var bubble_label := label(bubble, Vector2(105,48), Vector2(176,62), "", 16)
		bubble_label.name = "PendingOrder"
		bubble_labels.append(bubble_label)
		# Bubble is visual-only above the guest; the transparent table button remains clickable.
		move_child(bubble, seats[i].get_index())
		if i > 0:
			for state in ["normal", "hover", "pressed", "disabled", "focus"]:
				seats[i].add_theme_stylebox_override(state, StyleBoxEmpty.new())
			seats[i].size = Vector2(156,70)
			seats[i].position.x += 6
			seats[i].add_theme_color_override("font_hover_color", Color("48270e"))
			seats[i].add_theme_color_override("font_pressed_color", Color("48270e"))
		var bar := ProgressBar.new()
		place(bar, self, SEATS[i]+Vector2(0,106), Vector2(150,7))
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bars.append(bar)
		icons.append(texture(self, SEATS[i]+Vector2(69,53) if i > 0 else SEATS[i]+Vector2(0,-58), Vector2(32,32), null))
	texture(self, Vector2(220,48), Vector2(405,79), art.ui_texture("UI_MapNamePlate_Southwind_v1"))
	hud = label(self, Vector2(247,48), Vector2(300,45), "", 22)
	hud.add_theme_color_override("font_color", Color("fff0bd"))
	texture(self, Vector2(790,48), Vector2(600,100), art.ui_texture("UI_IncomeGoalPlate_Southwind_v1"))
	income_label = label(self, Vector2(704,48), Vector2(275,45), "", 20)
	wallet_label = label(self, Vector2(961,48), Vector2(185,45), "", 20)
	texture(self, Vector2(1340,48), Vector2(250,65), art.ui_texture("UI_TimerPlate_Southwind_v1"))
	timer_label = label(self, Vector2(1364,48), Vector2(190,50), "", 19)
	timer_label.add_theme_color_override("font_color", Color("fff0bd"))
	round_button(Vector2(1520,48), "Ⅱ", pause_game)
	round_button(Vector2(100,835), "图鉴", func(): codex(0))
	round_button(Vector2(205,835), "装饰", shop)
	round_button(Vector2(1290,835), "←", func(): turn(-1))
	action = button(self, Vector2(1400,816), Vector2(92,92), "互动", interact)
	round_button(Vector2(1510,835), "→", func(): turn(1))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		action.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		action.add_theme_color_override(state, Color.TRANSPARENT)
	texture(action, Vector2(46,46), Vector2(92,92), art.ui_texture("UI_InteractButton_Southwind_v1"))
	action_caption = label(self, Vector2(1400,878), Vector2(180,30), "", 18)
	card(self, Vector2(1400,748), Vector2(300,46))
	selection = label(self, Vector2(1400,748), Vector2(280,34), "", 18)
	# Centered production dock: title, live brew progress, held/ready slots, and status.
	art_panel(self, Vector2(800,805), Vector2(620,155), "UI_QueuePanel_Southwind_v1", 34, 24)
	art_panel(self, Vector2(800,744), Vector2(250,36), "UI_BrewingBadge_Southwind_v1", 24, 14)
	label(self, Vector2(800,744), Vector2(560,30), "制作中", 20)
	queue_label = label(self, Vector2(800,770), Vector2(560,30), "", 18)
	brew_progress = ProgressBar.new()
	place(brew_progress, self, Vector2(800,800), Vector2(450,12))
	brew_progress.min_value = 0
	brew_progress.max_value = 100
	brew_progress.show_percentage = false
	brew_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture(self, Vector2(650,840), Vector2(64,64), art.ui_texture("UI_DrinkSlot_Southwind_v1"))
	held_icon = texture(self, Vector2(650,840), Vector2(46,46), null)
	texture(self, Vector2(800,840), Vector2(64,64), art.ui_texture("UI_DrinkSlot_Southwind_v1"))
	ready_icon = texture(self, Vector2(800,840), Vector2(46,46), null)
	label(self, Vector2(950,840), Vector2(180,42), "空槽 · 可继续制作", 15)
	status = label(self, Vector2(800,881), Vector2(560,28), "", 16)
	tutorial_panel = art_panel(self, Vector2(800,700), Vector2(620,42), "UI_ToastPanel_Southwind_v1", 28, 18)
	tutorial_label = label(self, Vector2(800,700), Vector2(600,36), "", 17)
	toast_panel = art_panel(self, Vector2(280,140), Vector2(500,74), "UI_ToastPanel_Southwind_v1", 28, 18)
	toast = label(self, Vector2(280,140), Vector2(480,70), "", 21)
	discard = button(self, Vector2(1120,730), Vector2(160,42), "清理成品", confirm_discard)
	progress = Progress.new()
	map_progress = NordicProgress.new() if map_id == Maps.MAP02 else progress
	if not progress.error.is_empty() or not map_progress.error.is_empty():
		show_error(map_progress.error if not map_progress.error.is_empty() else progress.error)
		return
	reset_day()
	welcome()

func reset_day() -> void:
	model = Model.new(Maps.for_day(map_id, current_day), assisted)
	model.started = true
	model.tip_remainder = progress.data.tip_remainder
	for id in progress.data.codex:
		model.codex[id] = true
	bonuses()
	arrival_ids.clear()
	visit_ids.clear()
	visibility.clear()
	arrival_time = 0
	service_pulse = 0
	serve_time = 0
	previous_coins = 0
	previous_stolen = 0
	previous_missed = 0
	feedback_time = 0
	feedback = ""
	# Tutorial is opt-in from the pause/help menu; gameplay starts clean.
	tutorial = false
	tutorial_panel.visible = false
	tutorial_label.visible = false
	tutorial_baseline = 0
	tutorial_time = 0
	close_modal()

func bonuses() -> void:
	model.patience_multiplier = 1.05 if progress.owns(0) else 1.0
	model.tip_multiplier = 1.05 if progress.owns(1) else 1.0
	model.brew_speed = 1.05 if progress.owns(2) else 1.0
	model.patience_bonus = 2.0 if progress.owns(3) else 0.0
	model.wrong_cup_penalty = 1.0 if progress.owns(4) else 2.0
	model.combo_reward_cap = 6 if progress.owns(5) else 5
	refresh_decor_visibility()

func setup_decor_layer() -> void:
	decor_layer = Control.new()
	decor_layer.name = "ApprovedDecorLayer"
	decor_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(decor_layer)
	# Positions are conservative first-pass anchors in the 1600x900 scene. Each
	# asset remains a native transparent PNG; no raster edits or baked text.
	decor_nodes["deck"] = texture(decor_layer, Vector2(800,450), Vector2(1600,900), art.decor("deck"))
	decor_nodes["counter"] = texture(decor_layer, Vector2(800,790), Vector2(500,282), art.decor("counter"))
	decor_nodes["railing"] = texture(decor_layer, Vector2(800,170), Vector2(1120,532), art.decor("railing"))
	decor_nodes["table"] = texture(decor_layer, Vector2(800,470), Vector2(210,192), art.decor("table"))
	decor_nodes["hanging_lamp"] = texture(decor_layer, Vector2(800,104), Vector2(120,118), art.decor("hanging_lamp"))
	for i in 7:
		var lamp := texture(decor_layer, SEATS[i+1]+Vector2(0,-8), Vector2(35,35), art.decor("lighting"))
		decor_nodes["lighting_%d" % i] = lamp
		var chair := texture(decor_layer, SEATS[i+1]+Vector2(0,30), Vector2(72,64), art.decor("chair"))
		decor_nodes["chair_%d" % i] = chair
	refresh_decor_visibility()

func refresh_decor_visibility() -> void:
	if decor_nodes.is_empty() or progress == null:
		return
	# Existing three save slots map to the confirmed replacement family.
	decor_nodes["counter"].visible = progress.owns(2)
	for i in 7:
		decor_nodes["chair_%d" % i].visible = progress.owns(0)
	for i in 7:
		decor_nodes["lighting_%d" % i].visible = progress.owns(1)
	decor_nodes["hanging_lamp"].visible = progress.owns(1)
	# New stable-ID replacement slots are active after purchase; old saves migrate to six slots.
	decor_nodes["deck"].visible = progress.owns(5)
	decor_nodes["railing"].visible = progress.owns(3)
	decor_nodes["table"].visible = progress.owns(4)

func can_input() -> bool:
	return model != null and not fatal and not model.paused and not model.ended and not focus_paused and modal == null and Engine.get_process_frames() > input_block_frame

func turn(delta: int) -> void:
	if can_input():
		model.turn(delta)

func select_seat(seat: int) -> void:
	if not can_input():
		return
	if model.direction == seat:
		interact()
	else:
		model.direction = seat

func interact() -> void:
	if not can_input():
		return
	var v: Dictionary = model.at(model.direction)
	if not v.is_empty() and v.state == Model.State.ORDER:
		dialogue(v)
		return
	if not v.is_empty() and v.state == Model.State.WAITING and model.hand.is_empty() and not model.mimi_warning(v):
		model.interact()
		dialogue(v)
		return
	var delivery: bool = not v.is_empty() and v.state == Model.State.WAITING and not model.mimi_warning(v) and not model.hand.is_empty() and model.accepts(v, model.hand)
	var lime: bool = not model.hand.is_empty() and model.hand.drink == "青柠苏打"
	model.interact()
	if delivery:
		service_direction = model.direction
		service_pulse = 0.32
		serve_time = 0.36 if lime else 0.0

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or fatal:
		return
	match event.keycode:
		KEY_ESCAPE:
			if modal != null:
				close_modal()
			else:
				pause_game()
		KEY_LEFT: turn(-1)
		KEY_RIGHT: turn(1)
		KEY_SPACE: interact()
		_: return
	get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if model == null or fatal:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not model.ended:
		focus_paused = true
		if modal == null:
			pause_game()
		model.paused = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focus_paused = false
		model.paused = modal != null

func _process(delta: float) -> void:
	if model == null or fatal:
		return
	model.update(delta)
	if not model.paused and not model.ended:
		arrival_time -= delta
		for v in model.visitors:
			if not arrival_ids.has(v.id):
				arrival_ids[v.id] = true
				toast.text = ("惊喜客人 · " if v.guest.id == "jiwoo" else "客人入场 · ") + v.guest.name
				arrival_time = 3
	toast.visible = arrival_time > 0
	toast_panel.visible = toast.visible
	for id in model.codex:
		progress.unlock(id)
	var income: int = model.claim_settlement()
	if income >= 0:
		record_active_day(income)
		settlement()
	if not progress.error.is_empty() or not map_progress.error.is_empty():
		show_error(map_progress.error if not map_progress.error.is_empty() else progress.error)
		return
	hud.text = "%s · 第%d天" % [Maps.map_name(map_id), current_day]
	income_label.text = "收入 %d / %d" % [model.coins, model.day.target]
	wallet_label.text = "钱包 %d" % progress.data.wallet
	timer_label.text = "%s · %d 秒" % ["辅助" if assisted else "标准", maxi(0, ceili(model.day.duration-model.elapsed))]
	var dt := 0.0 if model.paused or model.ended or focus_paused else delta
	ambient.advance(dt)
	sunny_breath_time += dt
	feedback_time = maxf(0, feedback_time-dt)
	var stolen: int = model.stolen_coins - previous_stolen
	var earned: int = model.coins - previous_coins + stolen
	var lost: int = model.missed - previous_missed
	if earned > 0 or stolen > 0 or lost > 0:
		feedback = "收款 +%d 金币 · 连续服务 %d 单" % [earned,model.combo] if earned > 0 else ""
		if stolen > 0:
			feedback += "  被偷 -%d 金币" % stolen
		if lost > 0:
			feedback += "  漏单 %d 位，下一单继续！" % lost
		feedback_time = 2.4
	previous_coins = model.coins
	previous_stolen = model.stolen_coins
	previous_missed = model.missed
	status.text = feedback if feedback_time > 0 else model.message
	if not model.hand.is_empty():
		queue_label.text = "手持：%s · 同款可互送" % model.hand.drink
		brew_progress.visible = false
	elif not model.ready.is_empty():
		queue_label.text = "已做好：%s · 面向出酒口取杯" % model.ready.drink
		brew_progress.visible = false
	elif not model.queue.is_empty():
		queue_label.text = "制作：%s  %.1fs  | 排队 %d" % [model.queue[0].drink, model.queue[0].remaining, model.queue.size()]
		brew_progress.visible = true
		brew_progress.value = clampf((1.0 - model.queue[0].remaining / maxf(0.01, model.queue[0].duration)) * 100.0, 0.0, 100.0)
	else:
		queue_label.text = "点击客位转向，再次点击互动"
		brew_progress.visible = false
	discard.disabled = not can_input() or (model.hand.is_empty() and model.ready.is_empty())
	held_icon.texture = art.drink(model.hand.get("drink", ""))
	ready_icon.texture = art.drink(model.ready.get("drink", ""))
	icons[0].texture = art.drink(model.ready.get("drink", ""))
	var hint: Dictionary = model.service_hint()
	tutorial_label.visible = tutorial and not model.ended and modal == null
	tutorial_panel.visible = tutorial_label.visible
	tutorial_label.text = hint.text
	if tutorial and model.served > tutorial_baseline:
		progress.complete_tutorial()
		tutorial_label.text = "完成！收钱后自动清台，新客就能入座。"
		tutorial_time += dt
		if tutorial_time >= 3:
			tutorial = false
	refresh_motion(dt)
	refresh_seats(dt, int(hint.target) if tutorial else -1)
	refresh_action()

func refresh_seats(dt: float, hint: int) -> void:
	for i in 8:
		seats[i].modulate = Color("b6ffb6") if hint == i else (Color("ffc24a") if model.direction == i else Color.WHITE)
		bars[i].visible = false
		bubbles[i].visible = false
		bubble_labels[i].text = ""
		bubbles[i].modulate = seats[i].modulate
		if i == 0:
			seats[i].text = "出酒口 · 取杯" if not model.ready.is_empty() else "出酒口"
			continue
		var v: Dictionary = model.at(i)
		icons[i].texture = null
		if not v.is_empty() and visit_ids.get(i, -1) != v.id:
			visit_ids[i] = v.id
			visibility[i] = 0.0
			sprites[i].texture = art.chibi(v.guest.id)
		visibility[i] = move_toward(float(visibility.get(i,0)), 0.0 if v.is_empty() else 1.0, dt/0.22)
		sprites[i].modulate.a = visibility[i]
		if model.bills.has(i):
			visibility[i] = 0.0
			sprites[i].modulate.a = 0.0
			visit_ids.erase(i)
			icons[i].texture = art.ui_texture("UI_Icon_Coin_Southwind_v1")
			seats[i].text = "P%d · 待收款\n金币 · 用过的杯子 ×%d" % [i, model.bills[i].cups]
			continue
		if v.is_empty():
			seats[i].text = "行李占座" if model.blocked(i) else ""
			seats[i].tooltip_text = "P%d · 空位" % i
			if visibility[i] == 0:
				visit_ids.erase(i)
			continue
		if v.state == Model.State.WAITING:
			bubbles[i].visible = true
			bubble_labels[i].text = model.order_text(v)
		elif v.state == Model.State.ORDER and model.tank_attention(v):
			bubbles[i].visible = true
			bubble_labels[i].text = "先摘呼吸器"
		var text := ""
		match v.state:
			Model.State.ORDER: text = "提醒摘呼吸器" if model.tank_attention(v) else "点单"
			Model.State.WAITING:
				text = model.order_text(v)
				icons[i].texture = art.drink(v.guest.drink)
				if model.mimi_warning(v):
					text = "伸手中！互动打断 %ds" % ceili((4 if assisted else 2)-v.mimi_warning_time)
				elif v.guest.id == "gecko" and not v.gecko_attempted and v.gecko_wait >= 3:
					text = "准备换座 %ds" % ceili(5-v.gecko_wait)
			Model.State.DRINKING: text = "饮用中"
		if model.needs_cooling(v):
			text += " · 降温 %ds" % ceili(v.heat_remaining)
		if model.needs_warmth(v):
			text += " · 保暖 %ds" % ceili(v.warmth_remaining)
		seats[i].text = "P%d · %s\n%s" % [i, v.guest.name.split(" ")[0], text]
		bars[i].visible = v.state != Model.State.DRINKING
		var ratio: float = v.patience/(25.0*model.patience_multiplier)
		if model.needs_cooling(v):
			ratio = minf(ratio, v.heat_remaining/v.heat_limit)
		if model.needs_warmth(v):
			ratio = minf(ratio, v.warmth_remaining/v.warmth_limit)
		bars[i].value = clampf(ratio,0,1)*100
		bars[i].modulate = Color("ff563a") if ratio < 0.3 else Color("86d062")

func refresh_motion(dt: float) -> void:
	if model.ended or model.direction != service_direction:
		service_pulse = 0
		serve_time = 0
	if not model.hand.is_empty():
		serve_time = 0
	service_pulse = maxf(0, service_pulse-dt)
	serve_time = maxf(0, serve_time-dt)
	var direction: int = model.direction
	var asset := "Sunny_Southwind_Idle_v1"
	if direction in [2,6]:
		asset = "Sunny_Southwind_D%d_Idle" % direction
	if not model.hand.is_empty() and model.hand.drink == "青柠苏打" and direction in [0,6]:
		asset = "Sunny_Southwind_D%d_Carry" % direction
	if serve_time > 0:
		asset = "Sunny_Southwind_D%d_Serve_%02d" % [6 if direction == 6 else 0, clampi(int((1-serve_time/0.36)*3),0,2)]
	sunny.texture = art.texture(asset)
	var pulse := sin((1-service_pulse/0.32)*PI) if service_pulse > 0 else 0.0
	var base_position: Vector2 = Vector2(712.5,347.5) + (SEATS[service_direction]-Vector2(800,435)).normalized()*8*pulse
	# A restrained procedural breath keeps the central host alive without adding
	# another animation sheet. It freezes with pause/low-motion and yields to
	# the existing service pulse.
	var breathing := 0.0 if pulse > 0 or serve_time > 0 or model.paused else sin(sunny_breath_time*2.15)*0.012
	sunny.pivot_offset = Vector2(87.5,87.5)
	sunny.scale = Vector2(1.0-breathing*0.35, 1.0+breathing)
	sunny.position = base_position + Vector2(0,-breathing*26.0)

func refresh_action() -> void:
	var v: Dictionary = model.at(model.direction)
	selection.text = "面向：出酒口" if model.direction == 0 else "面向：P%d · %s" % [model.direction, v.guest.name.split(" ")[0] if not v.is_empty() else ("待收款" if model.bills.has(model.direction) else ("行李占座" if model.blocked(model.direction) else "空位"))]
	var actionable := true
	if model.direction == 0:
		action.text = "先送饮品" if not model.hand.is_empty() else ("取杯" if not model.ready.is_empty() else ("制作中" if not model.queue.is_empty() else "先接单"))
		actionable = model.hand.is_empty() and not model.ready.is_empty()
	elif model.bills.has(model.direction):
		action.text = "收钱清台"
	elif v.is_empty():
		action.text = "暂无客人"
		actionable = false
	elif v.state == Model.State.ORDER:
		action.text = "提醒Tank" if model.tank_attention(v) else "接单"
	elif v.state == Model.State.WAITING:
		action.text = "打断偷钱" if model.mimi_warning(v) else ("送达" if not model.hand.is_empty() else "问订单")
	else:
		action.text = "饮用中"
		actionable = false
	action.disabled = not can_input() or not actionable
	action_caption.text = action.text
	action.tooltip_text = action.text + " · Space"
	action.modulate = Color(1,1,1,0.5) if action.disabled else Color.WHITE

func choose_day(day: int) -> void:
	if not active_can_enter(day) or (not model.ended and model.elapsed > 0):
		return
	current_day = day
	reset_day()
	welcome()

func restart(use_assistance: bool) -> void:
	assisted = use_assistance
	reset_day()
	welcome()

func record_text() -> String:
	return "第%d天：%s · 最佳收入 标准 %d / 辅助 %d" % [current_day, "已通关" if active_cleared(current_day) else "未通关", active_best(current_day, 0), active_best(current_day, 1)]

func welcome() -> void:
	open_modal("%s · 第%d天 · 准备营业 · %s模式" % [Maps.map_name(map_id), current_day, "辅助" if assisted else "标准"])
	label(modal, Vector2(800,405), Vector2(930,230), record_text()+"\n%d 秒内赚到 %d 金币\n接单 → 出酒口取杯 → 送达 → 收钱\n%s" % [model.day.duration, model.day.target, "辅助：耐心消耗降低25%；待收桌位无倒计时" if assisted else "标准：正常耐心；收钱后自动清台"],25)
	if current_day == 2:
		label(modal,Vector2(800,525),Vector2(950,50),"Tank先摘呼吸器再点单；Gecko等久了会换座，同款饮品可互送。",20)
	if current_day == 3:
		label(modal,Vector2(800,525),Vector2(950,60),"Mimi伸手时互动打断（%d秒），之后再送杯。\nSPF-8要两杯椰子水，分次取送，送齐再收钱。" % (4 if assisted else 2),20)
	if current_day == 4:
		label(modal,Vector2(800,525),Vector2(950,60),"终局营业：Jiwoo白天喝冰美式，夜里切换无酒精特调；Snowy需要快速降温。",20)
	for day in range(1,5):
		var chosen := day
		var b := button(modal,Vector2(310+(day-1)*330,675),Vector2(270,55),"当前：第%d天" % day if day == current_day else ("选择第%d天" % day if active_can_enter(day) else "第%d天 · 通关前一天解锁" % day),func(): choose_day(chosen))
		b.disabled = not active_can_enter(day) or day == current_day
	button(modal,Vector2(620,590),Vector2(290,65),"开始营业",close_modal)
	button(modal,Vector2(970,590),Vector2(290,65),"切换标准模式" if assisted else "切换辅助模式",func(): restart(not assisted))

func confirm_discard() -> void:
	if not can_input() or (model.hand.is_empty() and model.ready.is_empty()):
		return
	open_modal("清理成品 · 不会自动倒掉")
	label(modal,Vector2(800,380),Vector2(850,100),"仅清理你选择的一杯；尚未满足的订单会重新安排制作。",23)
	for from_hand in [true, false]:
		var cup: Dictionary = model.hand if from_hand else model.ready
		if cup.is_empty():
			continue
		var source: bool = from_hand
		button(modal,Vector2(800,470 if from_hand else 550),Vector2(600,60),"确认倒掉%s：%s" % ["手持" if from_hand else "出酒口",cup.drink],func():
			close_modal()
			model.discard_cup(source))
	button(modal,Vector2(800,640),Vector2(300,55),"保留，返回营业",close_modal)

func pause_game() -> void:
	if model == null or fatal:
		return
	if model.ended:
		settlement()
		return
	open_modal("休息一下")
	button(modal,Vector2(800,430),Vector2(300,70),"继续营业",close_modal)
	button(modal,Vector2(800,630),Vector2(420,55),"环境动态：关闭（低动态）" if ambient.reduced_motion else "环境动态：开启",func():
		var result: Error = ambient.set_reduced_motion(not ambient.reduced_motion)
		if result != OK:
			model.message = "环境动态已切换，但设置未能保存。"
		pause_game())
	button(modal,Vector2(800,540),Vector2(300,65),"关闭教学提示" if tutorial else "重新开启教学",func():
		tutorial = not tutorial
		tutorial_baseline = model.served
		tutorial_time = 0
		close_modal())

func dialogue(v: Dictionary) -> void:
	# Native bottom dialogue overlay; a modal pauses service without hiding the scene.
	close_modal()
	model.paused = true
	modal = Control.new()
	modal.name = "OrderDialogue"
	modal.size = Vector2(1600,900)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var shade := ColorRect.new()
	place(shade, modal, Vector2(800,450), Vector2(1600,900))
	shade.color = Color(0,0,0,0.38)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var guest_portrait := texture(modal, Vector2(325,449), Vector2(500,480), art.portrait(v.guest.id))
	guest_portrait.name = "GuestPortrait"
	# Explicit temporary presentation; replace with an approved dialogue portrait when supplied.
	var host := texture(modal, Vector2(1290,464), Vector2(410,450), art.texture("Sunny_Chibi"))
	host.name = "SunnyDialogueFallback"
	var panel := card(modal, Vector2(800,765), Vector2(1530,230))
	panel.name = "DialoguePanel"
	texture(modal, Vector2(245,647), Vector2(355,69), art.ui_texture("UI_DialogueNamePlate_Southwind_v1"))
	var name_label := label(modal, Vector2(275,646), Vector2(255,48), v.guest.name.split(" ")[0], 26)
	name_label.add_theme_color_override("font_color", Color("fff0bd"))
	var order := "咕噜咕噜……（呼吸器还没摘）" if model.tank_attention(v) else "来%d杯%s！" % [v.guest.cups,v.guest.drink]
	if model.needs_cooling(v):
		order += "\n请在剩余 %d 秒内送到！" % ceili(v.heat_remaining)
	var content := label(modal, Vector2(620,754), Vector2(890,135), order, 28)
	content.name = "OrderText"
	content.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	texture(modal,Vector2(111,751),Vector2(66,80),art.drink(v.guest.drink) if not model.tank_attention(v) else null)
	label(modal,Vector2(620,840),Vector2(900,30),"确认后接单；待上饮品会一直显示在客人头顶",18)
	var skip := button(modal,Vector2(1460,140),Vector2(92,52),"",close_modal)
	skin_button(skip, "UI_Button_Ivory_Southwind_v1")
	texture(skip, Vector2(46,26), Vector2(62,36), art.ui_texture("UI_Icon_DialogueSkip_Southwind_v1"))
	var accept := button(modal,Vector2(1300,727),Vector2(350,66),"先摘呼吸器吧" if model.tank_attention(v) else "马上来！",func():
		close_modal()
		model.direction = v.seat
		model.interact())
	skin_button(accept, "UI_Button_Teal_Southwind_v1")
	var later := button(modal,Vector2(1300,810),Vector2(350,60),"稍后再来",close_modal)
	skin_button(later, "UI_Button_Ivory_Southwind_v1")

func codex(selected: int) -> void:
	close_modal()
	model.paused = true
	modal = Control.new()
	modal.name = "GuestCodex"
	modal.size = Vector2(1600, 900)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var shade := ColorRect.new()
	place(shade, modal, Vector2(800,450), Vector2(1600,900))
	shade.color = Color(0,0,0,0.50)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture(modal, Vector2(800,450), Vector2(1440,780), art.codex_asset("book"))
	var codex_close := button(modal, Vector2(1405,125), Vector2(72,72), "", close_modal)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		codex_close.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	texture(codex_close, Vector2(36,36), Vector2(44,44), art.ui_texture("UI_Icon_Close_Southwind_v1"))
	label(modal, Vector2(800,135), Vector2(520,62), "客人图鉴", 34)
	var available: Array = Maps.available_guests(map_id)
	var safe_selected := clampi(selected, 0, maxi(0, available.size()-1))
	var current_id: String = available[safe_selected] if not available.is_empty() else ""
	var current_guest: Dictionary = Config.guest(current_id) if not current_id.is_empty() else {}
	label(modal, Vector2(500,220), Vector2(220,42), "%d / %d" % [safe_selected+1, available.size()], 22)
	var grid_x := [285.0, 465.0, 645.0]
	var grid_y := [330.0, 495.0, 660.0]
	for i in mini(9, available.size()):
		if i >= available.size():
			continue
		var choice := i
		var id: String = available[i]
		var known: bool = model.codex.has(id)
		var tile_center := Vector2(grid_x[i % 3], grid_y[i / 3])
		texture(modal, tile_center, Vector2(142,142), art.ui_texture("UI_CodexPortraitSlot_Southwind_v1"))
		if i == safe_selected:
			texture(modal, tile_center, Vector2(154,154), art.ui_texture("UI_CodexSelectionFrame_Southwind_v1"))
		if known:
			texture(modal, tile_center, Vector2(126,126), art.portrait(id))
		else:
			texture(modal, tile_center, Vector2(142,142), art.codex_asset("locked_slot"))
			texture(modal, tile_center, Vector2(52,62), art.ui_texture("UI_Icon_Lock_Southwind_v1"))
		var pick := button(modal, tile_center+Vector2(0,70), Vector2(150,24), "", func(): codex(choice))
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			pick.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		pick.add_theme_color_override("font_color", Color.TRANSPARENT)
		pick.tooltip_text = Config.guest(id).name if known else "完成服务后解锁"
		pick.disabled = not known and i != safe_selected
	var unlocked: bool = not current_id.is_empty() and model.codex.has(current_id)
	var name_text: String = current_guest.name if unlocked else "未知客人"
	label(modal, Vector2(1070,225), Vector2(600,58), name_text, 30)
	if unlocked:
		texture(modal, Vector2(1050,470), Vector2(330,340), art.portrait(current_id))
		texture(modal, Vector2(1290,265), Vector2(280,72), art.ui_texture("UI_CodexTag_Southwind_v1"))
		var badge_sheet := texture(modal, Vector2(1290,360), Vector2(250,166), art.codex_asset("trait_badges"))
		badge_sheet.modulate = Color(1,1,1,0.92)
		label(modal, Vector2(1290,280), Vector2(250,34), "客人标签", 18)
		label(modal, Vector2(1290,320), Vector2(210,28), "海岛旅客", 17)
		label(modal, Vector2(1290,360), Vector2(210,28), "喜欢拍照", 17)
		label(modal, Vector2(1290,400), Vector2(210,28), "常点饮品", 17)
		texture(modal, Vector2(910,655), Vector2(120,150), art.ui_texture("UI_FavoriteDrinkCard_Southwind_v1"))
		texture(modal, Vector2(910,635), Vector2(64,64), art.drink(current_guest.drink))
		var bio: String = current_guest.bio + "\n\n喜欢：" + current_guest.drink + (" × %d" % current_guest.cups if current_guest.cups > 1 else "")
		label(modal, Vector2(1160,665), Vector2(410,150), bio, 20)
	else:
		texture(modal, Vector2(1070,470), Vector2(250,250), art.ui_texture("UI_CodexPortraitSlot_Southwind_v1"))
		texture(modal, Vector2(1070,470), Vector2(72,84), art.ui_texture("UI_Icon_Lock_Southwind_v1"))
		label(modal, Vector2(1120,665), Vector2(420,100), "完成服务并收钱，解锁人物小传。\n更多客人将在后续营业日登场。", 21)
	button(modal, Vector2(1030,770), Vector2(82,64), "‹", func(): codex(posmod(safe_selected-1, available.size())))
	button(modal, Vector2(1380,770), Vector2(82,64), "›", func(): codex(posmod(safe_selected+1, available.size())))

func settlement() -> void:
	var passed: bool = model.passed()
	open_modal("")
	var frame := art_panel(modal, Vector2(800,470), Vector2(1250,680), "UI_SettlementPanel_Southwind_v1", 42, 38)
	frame.name = "VictorySettlementPanel"
	modal.move_child(frame,1)
	texture(modal, Vector2(800,212), Vector2(1050,110), art.texture("UI_VictoryFloralHeader_Southwind_v1"))
	texture(modal, Vector2(800,212), Vector2(620,128), art.ui_texture("UI_SettlementTitle_Southwind_v1"))
	label(modal, Vector2(800,247), Vector2(760,66), "目标达成" if passed else "今日打烊", 42)
	var character_asset := "Sunny_Southwind_Victory_v1" if passed else "Sunny_Chibi"
	texture(modal, Vector2(410,495), Vector2(350,500), art.texture(character_asset))
	texture(modal, Vector2(535,360), Vector2(138,138), art.ui_texture("UI_Badge_GoalSuccess_Southwind_v1" if passed else "UI_Badge_GoalRetry_Southwind_v1"))
	if passed:
		texture(modal, Vector2(1095,382), Vector2(185,140), art.texture("UI_VictoryCoinBurst_Southwind_v1"))
	label(modal, Vector2(800,330), Vector2(420,38), "%s模式 · 椰风岛 · 第%d天" % ["辅助" if assisted else "标准", current_day], 20)
	for row_y in [430,495,560]:
		texture(modal, Vector2(930,row_y), Vector2(520,58), art.ui_texture("UI_StatRow_Southwind_v1"))
	var summary := "营业收入    %d / %d\n服务客人    %d\n已收录图鉴  %d\n最佳连击    %d" % [model.coins, model.day.target, model.served, model.codex.size(), model.best_combo]
	label(modal, Vector2(930,490), Vector2(470,220), summary, 24)
	label(modal, Vector2(930,625), Vector2(470,44), "金币已入账 · 钱包 %d" % progress.data.wallet, 20)
	label(modal, Vector2(930,675), Vector2(470,38), "目标达成，可进入下一天" if passed else "还差 %d 金币；重试保留钱包、装饰和图鉴" % maxi(0, model.day.target-model.coins), 17)
	var decorate_button := button(modal, Vector2(470,760), Vector2(250,58), "装饰酒馆", shop)
	skin_button(decorate_button, "UI_Button_Ivory_Southwind_v1")
	var replay_button := button(modal, Vector2(800,760), Vector2(280,58), "同模式重玩当天", func(): restart(assisted))
	skin_button(replay_button, "UI_Button_Teal_Southwind_v1")
	var mode_button := button(modal, Vector2(1130,760), Vector2(250,58), "标准模式重试" if assisted else "辅助模式重试", func(): restart(not assisted))
	skin_button(mode_button, "UI_Button_Ivory_Southwind_v1")
	if active_can_enter(current_day+1):
		button(modal, Vector2(970, 825), Vector2(280, 50), "进入第%d天" % (current_day+1), func(): choose_day(current_day+1))
	if current_day > 1:
		button(modal, Vector2(620, 825), Vector2(280, 50), "返回第%d天" % (current_day-1), func(): choose_day(current_day-1))
	if current_day == 4 and model.passed():
		if map_id == Maps.MAP01:
			label(modal, Vector2(800, 775), Vector2(700, 36), "第一地图完成！下一站：北欧极光峡湾", 20)
			button(modal, Vector2(800, 825), Vector2(360, 58), "前往北欧极光峡湾", go_to_nordic)
		else:
			label(modal, Vector2(800, 825), Vector2(700, 50), "北欧地图完成！下一站：希腊古城", 20)

func go_to_nordic() -> void:
	if map_id != Maps.MAP01 or not progress.cleared(4):
		return
	get_tree().change_scene_to_file("res://scenes/nordic_island.tscn")

func active_can_enter(day: int) -> bool:
	return map_progress.unlocked(day) if map_id == Maps.MAP02 else progress.can_enter(day)

func active_cleared(day: int) -> bool:
	return map_progress.cleared(day) if map_id == Maps.MAP02 else progress.cleared(day)

func active_best(day: int, mode: int) -> int:
	return int(map_progress.data.best[day-1][mode]) if map_id == Maps.MAP02 else int(progress.data.best[day-1][mode])

func record_active_day(income: int) -> void:
	if map_id == Maps.MAP02:
		var recorded: bool = map_progress.record(current_day, income, model.day.target, model.assisted)
		if recorded:
			progress.deposit_income(income + NordicEvent.reward(model.codex, model.passed()))
	else:
		progress.complete_day(current_day, income, model.day.target, model.tip_remainder, model.assisted)

func shop() -> void:
	decor_shop_page = 0
	decor_shop_page_view()

func decor_shop_page_view() -> void:
	close_modal()
	model.paused = true
	modal = Control.new()
	modal.name = "DecorShop"
	modal.size = Vector2(1600,900)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var shade := ColorRect.new()
	place(shade, modal, Vector2(800,450), Vector2(1600,900))
	shade.color = Color(0,0,0,0.10)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture(modal, Vector2(1250,450), Vector2(650,900), art.ui_texture("UI_ShopSidebar_Southwind_v1"))
	texture(modal, Vector2(1250,450), Vector2(620,870), art.decor_ui("panel"))
	button(modal, Vector2(1490,83), Vector2(64,64), "×", close_modal)
	label(modal, Vector2(1250,83), Vector2(390,58), "装饰酒馆", 34)
	label(modal, Vector2(1250,166), Vector2(370,48), "金币  %d" % progress.data.wallet, 26)
	var preview_slots := ["chair", "lighting", "counter", "railing", "table", "deck"]
	var preview_names := ["贝壳藤编软椅", "海岛贝壳灯具", "浅海玻璃吧台", "漂流木贝壳栏杆", "浅海波纹客桌", "海岸贝母地板"]
	var preview_effects := ["客人耐心 +5%", "小费 +5%", "制作速度 +5%", "耐心 +2 秒", "错杯惩罚 -1 秒", "连击收益上限 +1"]
	var card_x := [1050.0, 1250.0, 1450.0]
	var card_y := 385.0
	for i in 3:
		var index := decor_shop_page * 3 + i
		if index >= preview_slots.size():
			continue
		var slot: String = preview_slots[index]
		var cx: float = card_x[i]
		texture(modal, Vector2(cx, card_y), Vector2(180,470), art.ui_texture("UI_ShopItemCard_Southwind_v1"))
		texture(modal, Vector2(cx, card_y), Vector2(170,450), art.decor_ui("card"))
		if progress.owns(index) or index == decor_shop_page*3:
			texture(modal, Vector2(cx, card_y), Vector2(190,480), art.ui_texture("UI_ShopSelectionFrame_Southwind_v1"))
		texture(modal, Vector2(cx, 315), Vector2(145,145), art.decor(slot))
		label(modal, Vector2(cx, 205), Vector2(175,38), preview_names[index], 18)
		texture(modal, Vector2(cx+55, 515), Vector2(34,34), art.ui_texture("UI_Icon_Bonus_Southwind_v1"))
		label(modal, Vector2(cx, 515), Vector2(175,58), preview_effects[index], 17)
		var owned: bool = progress.owns(index)
		var buy_text := "已拥有" if owned else "%d 金币" % Progress.PRICES[index]
		texture(modal, Vector2(cx, 645), Vector2(186,62), art.ui_texture("UI_PricePlate_Southwind_v1"))
		texture(modal, Vector2(cx, 645), Vector2(176,58), art.decor_ui("purchase_button"))
		var buy := button(modal, Vector2(cx,645), Vector2(176,58), "", func():
			if progress.purchase(index):
				bonuses()
			decor_shop_page_view())
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			buy.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		buy.add_theme_color_override("font_color", Color.TRANSPARENT)
		label(modal, Vector2(cx,645), Vector2(160,42), buy_text, 19)
		buy.disabled = owned or progress.data.wallet < Progress.PRICES[index]
	label(modal, Vector2(1250,760), Vector2(390,34), "购买后会立即替换场景中的对应物件", 17)
	label(modal, Vector2(1250,798), Vector2(180,30), "%d / 2" % (decor_shop_page+1), 16)
	button(modal, Vector2(1070,798), Vector2(58,44), "‹", func():
		decor_shop_page = posmod(decor_shop_page-1, 2)
		decor_shop_page_view())
	button(modal, Vector2(1430,798), Vector2(58,44), "›", func():
		decor_shop_page = posmod(decor_shop_page+1, 2)
		decor_shop_page_view())

func open_modal(title: String, book := false) -> void:
	close_modal()
	model.paused = true
	modal = Control.new()
	modal.size = Vector2(1600,900)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var shade := ColorRect.new()
	place(shade,modal,Vector2(800,450),Vector2(1600,900))
	shade.color = Color(0,0,0,0.55)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if book:
		texture(modal,Vector2(800,450),Vector2(1160,680),art.texture("Codex_Book"))
	else:
		card(modal,Vector2(800,450),Vector2(1100,600))
	label(modal,Vector2(800,160 if book else 240),Vector2(950,70),title,30)
	var close_button := button(modal,Vector2(1310,160 if book else 240),Vector2(65,55),"",close_modal)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		close_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	texture(close_button,Vector2(32.5,27.5),Vector2(40,40),art.ui_texture("UI_Icon_Close_Southwind_v1"))

func close_modal() -> void:
	if modal != null:
		input_block_frame = Engine.get_process_frames()
		remove_child(modal)
		modal.queue_free()
		modal = null
	if model != null:
		model.paused = focus_paused

func show_error(message: String) -> void:
	fatal = true
	if model == null:
		model = Model.new()
	open_modal("存档错误 · 已暂停")
	label(modal,Vector2(800,450),Vector2(900,200),message,26)
	model.paused = true
	set_process(false)

func place(control: Control, parent: Node, center: Vector2, dimensions: Vector2) -> void:
	parent.add_child(control)
	control.position = center - dimensions/2
	control.size = dimensions

func texture(parent: Node, center: Vector2, dimensions: Vector2, image: Texture2D) -> TextureRect:
	var control := TextureRect.new()
	place(control,parent,center,dimensions)
	control.texture = image
	control.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	control.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control

func card(parent: Node, center: Vector2, dimensions: Vector2) -> Panel:
	var panel := Panel.new()
	place(panel,parent,center,dimensions)
	panel.add_theme_stylebox_override("panel",art.panel("Dialogue_Panel"))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

func art_panel(parent: Node, center: Vector2, dimensions: Vector2, asset: String, horizontal_margin := 36.0, vertical_margin := 24.0) -> Panel:
	var panel := Panel.new()
	place(panel,parent,center,dimensions)
	panel.add_theme_stylebox_override("panel",art.ui_style(asset,horizontal_margin,vertical_margin))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

func label(parent: Node, center: Vector2, dimensions: Vector2, text: String, font_size: int) -> Label:
	var control := Label.new()
	place(control,parent,center,dimensions)
	control.text = text
	control.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	control.add_theme_font_size_override("font_size",font_size)
	# Explicit dark ink is required because the default theme can fall back to
	# white text on the cream start/settlement panels.
	control.add_theme_color_override("font_color",Color("48270e"))
	control.add_theme_color_override("font_shadow_color",Color(1,0.88,0.62,0.35))
	control.add_theme_constant_override("shadow_offset_x",1)
	control.add_theme_constant_override("shadow_offset_y",1)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control

func button(parent: Node, center: Vector2, dimensions: Vector2, text: String, callback: Callable) -> Button:
	var control := Button.new()
	place(control,parent,center,dimensions)
	control.text = text
	control.focus_mode = Control.FOCUS_NONE
	control.add_theme_font_size_override("font_size",20)
	for state in ["normal","hover","pressed","disabled"]:
		control.add_theme_stylebox_override(state,art.panel("Button_Gold"))
		control.add_theme_color_override("font_"+state+"_color",Color("48270e"))
	control.add_theme_color_override("font_color",Color("48270e"))
	control.pressed.connect(callback)
	return control

func skin_button(control: Button, asset: String) -> void:
	for state in ["normal","hover","pressed","disabled"]:
		control.add_theme_stylebox_override(state,art.ui_style(asset,40,20))
	control.add_theme_color_override("font_color",Color("48270e"))
	for state in ["hover","pressed","disabled"]:
		control.add_theme_color_override("font_"+state+"_color",Color("48270e"))

func round_button(center: Vector2, caption: String, callback: Callable) -> Button:
	var control := button(self, center, Vector2(72,72), "", callback)
	control.tooltip_text = caption
	var icon_names := {"图鉴":"Codex", "装饰":"Decorate", "←":"TurnLeft", "→":"TurnRight", "Ⅱ":"Pause"}
	var icon := texture(control, Vector2(36,36), Vector2(43,43), art.ui_texture("UI_Icon_%s_Southwind_v1" % icon_names[caption]))
	icon.name = "ButtonIcon"
	if caption in ["图鉴", "装饰"]:
		label(self, center+Vector2(0,49), Vector2(90,25), caption, 16)
	var box := StyleBoxTexture.new()
	box.texture = art.ui_texture("UI_RoundButtonBase_Southwind_v1")
	for state in ["normal", "hover", "pressed", "disabled"]:
		control.add_theme_stylebox_override(state, box)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		control.add_theme_color_override(state, Color("fff0bd"))
	control.mouse_entered.connect(func(): control.modulate = Color(1.15,1.15,1.15))
	control.mouse_exited.connect(func(): control.modulate = Color.WHITE)
	return control
