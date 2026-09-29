extends Control

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
var status: Label
var queue_label: Label
var tutorial_label: Label
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
	texture(self, Vector2(800,450), Vector2(1600,900), art.texture("Island_Background"))
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
		seats[i].add_theme_font_size_override("font_size", 16)
		var bar := ProgressBar.new()
		place(bar, self, SEATS[i]+Vector2(0,106), Vector2(150,7))
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bars.append(bar)
		icons.append(texture(self, SEATS[i]+Vector2(83,4) if i > 0 else SEATS[i]+Vector2(0,-58), Vector2(48,48), null))
	card(self, Vector2(800,50), Vector2(1540,88))
	hud = label(self, Vector2(760,50), Vector2(1390,65), "", 24)
	button(self, Vector2(1520,50), Vector2(65,50), "Ⅱ", pause_game)
	button(self, Vector2(100,835), Vector2(150,64), "客人图鉴", func(): codex(0))
	button(self, Vector2(270,835), Vector2(150,64), "装饰酒馆", shop)
	button(self, Vector2(1300,835), Vector2(70,64), "←", func(): turn(-1))
	action = button(self, Vector2(1400,835), Vector2(120,64), "互动", interact)
	button(self, Vector2(1500,835), Vector2(70,64), "→", func(): turn(1))
	card(self, Vector2(1400,768), Vector2(300,46))
	selection = label(self, Vector2(1400,768), Vector2(280,34), "", 18)
	card(self, Vector2(800,845), Vector2(780,82))
	queue_label = label(self, Vector2(837,827), Vector2(650,32), "", 19)
	held_icon = texture(self, Vector2(455,827), Vector2(38,38), null)
	status = label(self, Vector2(800,863), Vector2(740,30), "", 17)
	card(self, Vector2(800,781), Vector2(780,40))
	tutorial_label = label(self, Vector2(800,781), Vector2(755,36), "", 18)
	toast = label(self, Vector2(280,140), Vector2(480,70), "", 21)
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
	hud.text = "南风岛 · 第%d天 · %s       今日 %d / %d       钱包 %d       %d 秒" % [current_day, "辅助" if assisted else "标准", model.coins, model.day.target, progress.data.wallet, ceili(model.day.duration-model.elapsed)]
	var dt := 0.0 if model.paused or model.ended or focus_paused else delta
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
	tutorial_label.text = hint.text
	if tutorial and model.served > tutorial_baseline:
		progress.complete_tutorial()
		tutorial_label.text = "完成！接单 → 取杯 → 送达 → 收钱。"
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
		if v.is_empty():
			seats[i].text = "P%d · %s" % [i, "行李占座" if model.blocked(i) else "空位"]
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
			Model.State.PAYMENT: text = "收钱 %ds" % ceili(v.timer)
		if model.needs_cooling(v):
			text += " · 降温 %ds" % ceili(v.heat_remaining)
		seats[i].text = "P%d · %s\n%s" % [i, v.guest.name.split(" ")[0], text]
		bars[i].visible = v.state != Model.State.DRINKING
		var ratio: float = v.timer/((6.0 if v.guest.id == "bobo" else 12.0)*(1.5 if assisted else 1.0)) if v.state == Model.State.PAYMENT else v.patience/(25.0*model.patience_multiplier)
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
	selection.text = "面向：出酒口" if model.direction == 0 else "面向：P%d · %s" % [model.direction, v.guest.name.split(" ")[0] if not v.is_empty() else ("行李占座" if model.blocked(model.direction) else "空位")]
	var actionable := true
	if model.direction == 0:
		action.text = "先送饮品" if not model.hand.is_empty() else ("取杯" if not model.ready.is_empty() else ("制作中" if not model.queue.is_empty() else "先接单"))
		actionable = model.hand.is_empty() and not model.ready.is_empty()
	elif v.is_empty():
		action.text = "暂无客人"
		actionable = false
	elif v.state == Model.State.ORDER:
		action.text = "提醒Tank" if model.tank_attention(v) else "接单"
	elif v.state == Model.State.WAITING:
		action.text = "打断偷钱" if model.mimi_warning(v) else ("送达" if not model.hand.is_empty() else "问订单")
	elif v.state == Model.State.PAYMENT:
		action.text = "收钱"
	else:
		action.text = "饮用中"
		actionable = false
	action.disabled = not can_input() or not actionable

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
	label(modal, Vector2(800,405), Vector2(930,230), record_text()+"\n%d 秒内赚到 %d 金币\n接单 → 出酒口取杯 → 送达 → 收钱\n%s" % [model.day.duration, model.day.target, "辅助：耐心消耗降低25%，收款等待延长50%" if assisted else "标准：原始耐心与收款时间"],25)
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
	button(modal,Vector2(800,540),Vector2(300,65),"关闭教学提示" if tutorial else "重新开启教学",func():
		tutorial = not tutorial
		tutorial_baseline = model.served
		tutorial_time = 0
		close_modal())

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
