extends Control

const Ambient = preload("res://scripts/island_ambient.gd")
var ambient: Control

const Model = preload("res://scripts/tavern_model.gd")
const Config = preload("res://scripts/day_config.gd")
const Progress = preload("res://scripts/progress_store.gd")
const Art = preload("res://scripts/art_catalog.gd")
const SEATS := [Vector2(800,710), Vector2(800,220), Vector2(1080,275), Vector2(1270,455), Vector2(1140,620), Vector2(440,620), Vector2(270,455), Vector2(520,275)]
const ITEMS := ["向日葵花瓶", "藤编小灯", "顺手托盘"]
const EFFECTS := ["客人耐心 +5%", "小费 +5%（累计取整）", "制作速度 +5%"]
var model: RefCounted
var progress: RefCounted
var art := Art.new()
var current_day := 1
var assisted := false
var modal: Control
var hud: Label
var income_label: Label
var wallet_label: Label
var timer_label: Label
var action_caption: Label
var bubbles: Array[TextureRect] = []
var status: Label
var queue_label: Label
var tutorial_label: Label
var tutorial_panel: Panel
var review_order: Button
var toast: Label
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
var arrival_time := 0.0
var tutorial := true
var tutorial_baseline := 0
var tutorial_time := 0.0
var focus_paused := false
var input_block_frame := -1
var serve_time := 0.0
var service_direction := 0
var service_pulse := 0.0
var feedback_time := 0.0
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
		var bubble := texture(self, SEATS[i]+Vector2(0,65), Vector2(190,98), art.ui_texture("UI_OrderBubble_Southwind_v1"))
		bubbles.append(bubble)
		# Bubble is below the transparent button; the whole table remains clickable.
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
	card(self, Vector2(800,845), Vector2(780,82))
	queue_label = label(self, Vector2(837,827), Vector2(650,32), "", 19)
	held_icon = texture(self, Vector2(455,827), Vector2(38,38), null)
	status = label(self, Vector2(800,863), Vector2(740,30), "", 17)
	tutorial_panel = card(self, Vector2(800,781), Vector2(780,40))
	tutorial_label = label(self, Vector2(800,781), Vector2(755,36), "", 18)
	toast = label(self, Vector2(280,140), Vector2(480,70), "", 21)
	review_order = button(self, Vector2(930,730), Vector2(160,42), "回看订单", review_selected_order)
	discard = button(self, Vector2(1120,730), Vector2(160,42), "清理成品", confirm_discard)
	progress = Progress.new()
	if not progress.error.is_empty():
		show_error(progress.error)
		return
	reset_day()
	welcome()

func reset_day() -> void:
	model = Model.new(Config.for_day(current_day), assisted)
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
	tutorial = not progress.data.tutorial_done
	tutorial_baseline = 0
	tutorial_time = 0
	close_modal()

func bonuses() -> void:
	model.patience_multiplier = 1.05 if progress.owns(0) else 1.0
	model.tip_multiplier = 1.05 if progress.owns(1) else 1.0
	model.brew_speed = 1.05 if progress.owns(2) else 1.0

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
		dialogue(v, true)
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
	for id in model.codex:
		progress.unlock(id)
	var income: int = model.claim_settlement()
	if income >= 0:
		progress.complete_day(current_day, income, model.day.target, model.tip_remainder, model.assisted)
		settlement()
	if not progress.error.is_empty():
		show_error(progress.error)
		return
	hud.text = "南风岛 · 第%d天" % current_day
	income_label.text = "收入 %d / %d" % [model.coins, model.day.target]
	wallet_label.text = "钱包 %d" % progress.data.wallet
	timer_label.text = "%s · %d 秒" % ["辅助" if assisted else "标准", maxi(0, ceili(model.day.duration-model.elapsed))]
	var dt := 0.0 if model.paused or model.ended or focus_paused else delta
	ambient.advance(dt)
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
	elif not model.ready.is_empty():
		queue_label.text = "已做好：%s · 面向出酒口取杯" % model.ready.drink
	elif not model.queue.is_empty():
		queue_label.text = "制作：%s  %.1fs  | 排队 %d" % [model.queue[0].drink, model.queue[0].remaining, model.queue.size()]
	else:
		queue_label.text = "点击客位转向，再次点击互动"
	discard.disabled = not can_input() or (model.hand.is_empty() and model.ready.is_empty())
	held_icon.texture = art.drink(model.hand.get("drink", ""))
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
		bubbles[i].visible = i > 0 and (not model.at(i).is_empty() or model.bills.has(i) or model.blocked(i))
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
			seats[i].text = "P%d · 待收款\n金币 · 用过的杯子 ×%d" % [i, model.bills[i].cups]
			continue
		if v.is_empty():
			seats[i].text = "行李占座" if model.blocked(i) else ""
			seats[i].tooltip_text = "P%d · 空位" % i
			if visibility[i] == 0:
				visit_ids.erase(i)
			continue
		var text := ""
		match v.state:
			Model.State.ORDER: text = "提醒摘呼吸器" if model.tank_attention(v) else "点单"
			Model.State.WAITING:
				text = model.order_text(v)
				if v.guest.id == "horn" and v.bubble <= 0:
					text = "再问一次"
				else:
					icons[i].texture = art.drink(v.guest.drink)
				if model.mimi_warning(v):
					text = "伸手中！互动打断 %ds" % ceili((4 if assisted else 2)-v.mimi_warning_time)
				elif v.guest.id == "gecko" and not v.gecko_attempted and v.gecko_wait >= 3:
					text = "准备换座 %ds" % ceili(5-v.gecko_wait)
			Model.State.DRINKING: text = "饮用中"
		if model.needs_cooling(v):
			text += " · 降温 %ds" % ceili(v.heat_remaining)
		seats[i].text = "P%d · %s\n%s" % [i, v.guest.name.split(" ")[0], text]
		bars[i].visible = v.state != Model.State.DRINKING
		var ratio: float = v.patience/(25.0*model.patience_multiplier)
		if model.needs_cooling(v):
			ratio = minf(ratio, v.heat_remaining/v.heat_limit)
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
	sunny.position = Vector2(712.5,347.5) + (SEATS[service_direction]-Vector2(800,435)).normalized()*8*pulse

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
	review_order.visible = not v.is_empty() and v.state == Model.State.WAITING
	review_order.disabled = not can_input() or (not v.is_empty() and model.mimi_warning(v))
	action.disabled = not can_input() or not actionable
	action_caption.text = action.text
	action.tooltip_text = action.text + " · Space"
	action.modulate = Color(1,1,1,0.5) if action.disabled else Color.WHITE

func choose_day(day: int) -> void:
	if not progress.can_enter(day) or (not model.ended and model.elapsed > 0):
		return
	current_day = day
	reset_day()
	welcome()

func restart(use_assistance: bool) -> void:
	assisted = use_assistance
	reset_day()
	welcome()

func record_text() -> String:
	return "第%d天：%s · 最佳收入 标准 %d / 辅助 %d" % [current_day, "已通关" if progress.cleared(current_day) else "未通关", progress.data.best[current_day-1][0], progress.data.best[current_day-1][1]]

func welcome() -> void:
	open_modal("南风岛 · 第%d天 · 准备营业 · %s模式" % [current_day, "辅助" if assisted else "标准"])
	label(modal, Vector2(800,405), Vector2(930,230), record_text()+"\n%d 秒内赚到 %d 金币\n接单 → 出酒口取杯 → 送达 → 收钱\n%s" % [model.day.duration, model.day.target, "辅助：耐心消耗降低25%；待收桌位无倒计时" if assisted else "标准：正常耐心；收钱后自动清台"],25)
	if current_day == 2:
		label(modal,Vector2(800,525),Vector2(950,50),"Tank先摘呼吸器再点单；Gecko等久了会换座，同款饮品可互送。",20)
	if current_day == 3:
		label(modal,Vector2(800,525),Vector2(950,60),"Mimi伸手时互动打断（%d秒），之后再送杯。\nSPF-8要两杯椰子水，分次取送，送齐再收钱。" % (4 if assisted else 2),20)
	for day in range(1,4):
		var chosen := day
		var b := button(modal,Vector2(470+(day-1)*330,675),Vector2(290,55),"当前：第%d天" % day if day == current_day else ("选择第%d天" % day if progress.can_enter(day) else "第%d天 · 通关前一天解锁" % day),func(): choose_day(chosen))
		b.disabled = not progress.can_enter(day) or day == current_day
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

func review_selected_order() -> void:
	if not can_input():
		return
	var v: Dictionary = model.at(model.direction)
	if v.is_empty() or v.state != Model.State.WAITING or model.mimi_warning(v):
		return
	v.bubble = 2.5
	dialogue(v, true)

func dialogue(v: Dictionary, review := false) -> void:
	open_modal(v.guest.name)
	texture(modal,Vector2(515,420),Vector2(250,300),art.portrait(v.guest.id))
	texture(modal,Vector2(675,415),Vector2(55,55),art.drink(v.guest.drink) if not model.tank_attention(v) else null)
	var order := "咕噜咕噜……（呼吸器还没摘）" if model.tank_attention(v) else "来%d杯%s！" % [v.guest.cups,v.guest.drink]
	if model.needs_cooling(v):
		order += "\n请在剩余 %d 秒内送到！" % ceili(v.heat_remaining)
	label(modal,Vector2(945,420),Vector2(470,230),v.guest.bio+"\n\n"+order,24)
	if review:
		button(modal,Vector2(940,590),Vector2(300,65),"记住了",close_modal)
		return
	button(modal,Vector2(940,590),Vector2(300,65),"先摘呼吸器吧" if model.tank_attention(v) else "马上来！",func():
		close_modal()
		model.direction = v.seat
		model.interact())

func codex(selected: int) -> void:
	open_modal("客人图鉴",true)
	var available: Array = Config.available_guests()
	for i in 9:
		var choice := i
		var known: bool = i < available.size() and model.codex.has(available[i])
		var b := button(modal,Vector2(420+(i%3)*150,320+(i/3)*125),Vector2(135,100),Config.guest(available[i]).name.split(" ")[0] if known else "未遇见",func(): codex(choice))
		b.disabled = not known
	var id: String = available[clampi(selected,0,available.size()-1)]
	var g: Dictionary = Config.guest(id)
	var unlocked: bool = model.codex.has(id)
	if unlocked:
		texture(modal,Vector2(1060,385),Vector2(230,250),art.portrait(id))
		texture(modal,Vector2(810,605),Vector2(65,65),art.drink(g.drink))
	label(modal,Vector2(1060,230),Vector2(440,60),g.name if unlocked else "未知客人",25)
	label(modal,Vector2(1060,610),Vector2(420,170),g.bio+"\n喜欢："+g.drink+(" × %d" % g.cups if g.cups > 1 else "") if unlocked else "完成服务并收钱，解锁人物小传。\n更多客人将在后续营业日登场。",23)

func settlement() -> void:
	open_modal("今日打烊 · 目标达成" if model.passed() else "今日打烊 · 再试一次")
	label(modal,Vector2(800,410),Vector2(950,230),"%s模式 · 营业收入 %d / %d\n服务 %d 位 · 漏单 %d 次 · 最佳连击 %d\n%s\n金币已入账 · 钱包 %d\n%s" % ["辅助" if assisted else "标准",model.coins,model.day.target,model.served,model.missed,model.best_combo,"目标达成，可选择已解锁营业日" if model.passed() else "还差 %d 金币；重试保留钱包、装饰和图鉴" % maxi(0,model.day.target-model.coins),progress.data.wallet,record_text()],22)
	button(modal,Vector2(470,590),Vector2(260,65),"装饰酒馆",shop)
	button(modal,Vector2(800,590),Vector2(290,65),"同模式重玩当天",func(): restart(assisted))
	button(modal,Vector2(1130,590),Vector2(290,65),"标准模式重试" if assisted else "辅助模式重试",func(): restart(not assisted))
	if progress.can_enter(current_day+1):
		button(modal,Vector2(970,675),Vector2(290,55),"进入第%d天" % (current_day+1),func(): choose_day(current_day+1))
	if current_day > 1:
		button(modal,Vector2(620,675),Vector2(290,55),"返回第%d天" % (current_day-1),func(): choose_day(current_day-1))
	if current_day == 3:
		label(modal,Vector2(975,675),Vector2(350,50),"第4天尚未开放",20)

func shop() -> void:
	open_modal("装饰酒馆 · 钱包 %d" % progress.data.wallet)
	for i in 3:
		var index := i
		label(modal,Vector2(650,345+i*110),Vector2(520,85),ITEMS[i]+"\n"+EFFECTS[i],25)
		var b := button(modal,Vector2(1060,345+i*110),Vector2(250,65),"已拥有" if progress.owns(i) else "%d 金币" % Progress.PRICES[i],func():
			if progress.purchase(index):
				bonuses()
			shop())
		b.disabled = progress.owns(i) or progress.data.wallet < Progress.PRICES[i]
	label(modal,Vector2(800,660),Vector2(960,60),"装饰加成立即生效；实体摆件美术待接入。",20)

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
	button(modal,Vector2(1310,160 if book else 240),Vector2(65,55),"×",close_modal)

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

func label(parent: Node, center: Vector2, dimensions: Vector2, text: String, font_size: int) -> Label:
	var control := Label.new()
	place(control,parent,center,dimensions)
	control.text = text
	control.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	control.add_theme_font_size_override("font_size",font_size)
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

func round_button(center: Vector2, caption: String, callback: Callable) -> Button:
	var control := button(self, center, Vector2(72,72), caption, callback)
	var box := StyleBoxTexture.new()
	box.texture = art.ui_texture("UI_RoundButtonBase_Southwind_v1")
	for state in ["normal", "hover", "pressed", "disabled"]:
		control.add_theme_stylebox_override(state, box)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		control.add_theme_color_override(state, Color("fff0bd"))
	control.mouse_entered.connect(func(): control.modulate = Color(1.15,1.15,1.15))
	control.mouse_exited.connect(func(): control.modulate = Color.WHITE)
	return control
