extends SceneTree
const Scene = preload("res://scenes/island.tscn")
const Model = preload("res://scripts/tavern_model.gd")
const Config = preload("res://scripts/day_config.gd")
const Progress = preload("res://scripts/progress_store.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# Isolated save path; never overwrite a developer's real progress.
	var path := "user://ui_smoke_only.json"
	DirAccess.remove_absolute(path)
	var ui = Scene.instantiate()
	root.add_child(ui)
	ui.progress = Progress.new(path)
	ui.reset_day()
	check(ui.has_method("santa_dialogue"), "Nordic surprise guest exposes a three-beat event dialogue")
	check(not ui.tutorial and not ui.tutorial_panel.visible, "Tutorial is opt-in and hidden by default")
	ui.welcome()
	check(ui.modal != null and ui.model.paused,"Welcome pauses game")
	check(ui.modal.name == "WelcomeModal" and ui.modal.get_node("StartPanelArtwork").texture != null, "Welcome mounts the approved Southwind start panel")
	check(ui.modal.get_node("StartPrimaryButton").size.y >= 72 and ui.modal.get_node("StartModeButton").size.x >= 300, "Welcome actions use thick wide button targets")
	for day in range(1,5):
		var day_button: Button = ui.modal.get_node("DayButton%d" % day)
		check(day_button.size.x >= 280 and day_button.size.y >= 64, "Day selector keeps long labels inside an authored wide tab")
	var welcome_labels: Array[Node] = ui.modal.find_children("*", "Label", true, false)
	check(welcome_labels.size() > 0, "Welcome panel contains readable labels")
	for welcome_label in welcome_labels:
		if welcome_label.name == "WelcomeTitle":
			check(welcome_label.get_theme_color("font_color").v > 0.7, "Welcome title stays readable on the dark wood plaque")
		else:
			check(welcome_label.get_theme_color("font_color").v < 0.7, "Welcome body uses dark high-contrast text")
	var breath_before: Texture2D = ui.sunny.texture
	ui.close_modal()
	ui._process(0.5)
	check(ui.sunny.texture != breath_before, "Sunny idle uses the approved three-frame breathing loop")
	# Approved guests use real baseline-locked frame loops; guests without a
	# confirmed set retain the restrained transform fallback.
	var bobo_idle_a: Texture2D = ui.art.guest_idle("bobo", 0)
	var bobo_idle_b: Texture2D = ui.art.guest_idle("bobo", 1)
	check(bobo_idle_a != null and bobo_idle_b != null and bobo_idle_a != bobo_idle_b, "Approved seated guest breathing frames load independently")
	ui.guest_breath_time = 0.0
	ui.refresh_guest_breath(2, true, "bobo")
	var mounted_guest_frame: Texture2D = ui.sprites[2].texture
	ui.guest_breath_time = 0.32
	ui.refresh_guest_breath(2, true, "bobo")
	check(ui.sprites[2].texture != mounted_guest_frame and ui.sprites[2].scale == Vector2.ONE, "Approved seated frame loop replaces procedural scaling")
	ui.guest_breath_time = 0.0
	ui.refresh_guest_breath(2, true)
	var guest_breath_a: Vector2 = ui.sprites[2].scale
	ui.guest_breath_time = 0.9
	ui.refresh_guest_breath(2, true)
	var guest_breath_b: Vector2 = ui.sprites[2].scale
	check(guest_breath_a != guest_breath_b, "Seated guest has a restrained breathing motion")
	ui.refresh_guest_breath(2, false)
	check(ui.sprites[2].scale == Vector2.ONE, "Empty guest seat resets breathing transform")
	check(ui.ambient.glow_layers.size() == 8 and ui.ambient.flame_layers.size() == 7, "Approved candle glow and flame layers are mounted at all anchors")
	ui.welcome()
	for asset in ui.art.UI_REGIONS:
		var atlas = ui.art.ui_texture(asset)
		check(atlas.atlas != null and Rect2(Vector2.ZERO, atlas.atlas.get_size()).encloses(atlas.region), "Approved UI atlas loads within original: " + asset)
	check(ui.get_node("ProductionDock").texture != null and ui.get_node("ProductionTaskCard").texture != null, "Approved production dock and task card are mounted")
	check(ui.get_node("ProductionDock").stretch_mode == TextureRect.STRETCH_SCALE and ui.get_node("ProductionProgressFrame").stretch_mode == TextureRect.STRETCH_SCALE, "Wide production artwork fills its authored runtime bounds")
	check(ui.get_node("HeldDrinkSlot").position.x < ui.get_node("ReadyDrinkTray").position.x, "Held and ready drink zones have a stable left-to-right hierarchy")
	check(ui.get_node("ProductionTaskLabel").size.x <= 220 and ui.get_node("ProductionProgress").size.x <= 180, "Dynamic production text and fill stay inside the primary task zone")
	check(ui.toast_panel != null and ui.tutorial_panel != null, "Approved toast and tutorial panel skins are mounted")
	var icon_count := 0
	for child in ui.get_children():
		if child is Button and child.has_node("ButtonIcon"):
			icon_count += 1
			check(child.get_node("ButtonIcon").mouse_filter == Control.MOUSE_FILTER_IGNORE and not child.tooltip_text.is_empty(), "Round icon preserves click and tooltip")
	check(icon_count == 5, "Five native controls use approved independent icons")
	check(ui.bubbles.size() == 8 and ui.bubbles[2].mouse_filter == Control.MOUSE_FILTER_IGNORE, "Order artwork preserves table input")
	for seat in ui.seats:
		check(seat.size.x >= 240 and seat.size.y >= 140, "Each table has a full-table click target")
	check(ui.decor_nodes.has("table_0") and ui.decor_nodes.has("table_6"), "Shop mounts seven table replacement instances")
	ui.close_modal()
	await process_frame
	await process_frame
	check(ui.can_input(),"Closing modal restores input")
	ui.model.update(8.1)
	ui.model.direction=2
	ui.interact()
	check(ui.modal != null and ui.model.paused,"Order opens paused dialogue")
	check(ui.modal.name == "OrderDialogue" and ui.modal.get_node("DialoguePanel").position.y >= 600, "Dialogue uses bottom panel layout")
	check(ui.modal.get_node("GuestPortrait").texture != null and ui.modal.get_node("SunnyDialogueFallback").texture != null, "Both dialogue sides have explicit configured art")
	check(ui.modal.get_node("OrderText").text.contains("芒果冰沙"), "Dialogue keeps live order text")
	var pending_jobs: int = ui.model.queue.size()
	for child in ui.modal.get_children():
		if child is Button and child.text == "稍后再来":
			child.pressed.emit()
			break
	check(ui.modal == null and ui.model.queue.size() == pending_jobs, "Deferring dialogue cannot accept order")
	await process_frame
	await process_frame
	ui.interact()
	# Find the real signal callback and accept through it.
	for child in ui.modal.get_children():
		if child is Button and child.text == "马上来！":
			child.pressed.emit()
			break
	check(ui.model.queue.size()==1 and ui.modal==null,"Dialogue acceptance queues order")
	ui._process(0.1)
	check(ui.brew_progress.visible and ui.brew_progress.value < 100, "Brewing exposes a live progress bar")
	ui.pause_game()
	var before: float=ui.model.elapsed
	ui._process(2)
	check(ui.model.elapsed==before,"Pause menu freezes clock")
	ui.codex(0)
	check(ui.modal != null,"Locked codex opens")
	check(ui.modal.find_children("*", "TextureRect", true, false).size() >= 18, "Codex mounts approved slots, selection and lock artwork")
	ui.model.codex["bobo"]=true
	ui.codex(0)
	check(ui.art.portrait("bobo")!=null,"Unlocked codex portrait loads")
	ui.progress.data.wallet=100
	ui.shop()
	check(ui.modal.find_children("*", "TextureRect", true, false).size() >= 20, "Shop mounts approved price plates, selection and bonus art")
	for child in ui.modal.get_children():
		if child is Button and child.position.y > 600 and not child.disabled:
			child.pressed.emit()
			break
	check(ui.progress.owns(0) and ui.model.patience_multiplier==1.05,"Shop signal purchases and applies bonus")
	ui.progress.complete_day(1,79,70,0,false)
	ui.model.ended=true
	ui.choose_day(2)
	check(ui.current_day==2 and ui.model.paused and ui.model.elapsed==0,"Choose unlocked Day2 resets and opens welcome")
	ui.progress.complete_day(2,124,90,0,false)
	ui.progress.complete_day(3,190,140,0,false)
	check(Config.playable(4) and ui.progress.can_enter(4),"First-map Day4 is unlocked after Day3")
	ui.choose_day(4)
	check(ui.current_day==4 and ui.model.paused and ui.model.day.target==160,"Choose unlocked Day4 loads final-day target")
	ui.restart(true)
	check(ui.model.assisted and ui.current_day==4,"Assist restart preserves final day")
	ui.close_modal()
	ui.model.update(120)
	ui._process(0)
	var wallet: int=ui.progress.data.wallet
	ui.settlement()
	check(ui.modal.find_children("*", "TextureRect", true, false).size() >= 6, "Settlement mounts approved panel, title, rows and result badge")
	ui.close_modal()
	ui._process(0)
	check(ui.progress.data.wallet==wallet,"Reopening settlement cannot double pay")
	for id in ["bobo","coco","horn","tank","gecko"]:
		check(ui.art.portrait(id)!=null,"Portrait loaded: "+id)
	for drink in ui.art.DRINKS:
		check(ui.art.drink(drink)!=null,"Drink loaded: "+drink)
	for id in ["bobo", "coco", "horn", "tank", "gecko", "mimi", "spf8", "snowy", "jiwoo"]:
		check(ui.art.chibi(id)!=null,"Seated sprite loaded: "+id)
	check(ui.art.chibi("bobo")!=ui.art.portrait("bobo") and ui.art.chibi("tank")!=ui.art.portrait("tank"),"Seated sprites load separately from portraits")
	for slot in ui.art.DECOR_ASSETS:
		check(ui.art.decor(slot) != null, "Approved decor loads: " + slot)
	for drink in ui.art.FUTURE_DRINKS:
		check(ui.art.drink(drink) != null, "Approved future drink loads: " + drink)
	check(ui.decor_nodes.size() == 25, "All approved decor replacement instances are mounted in the scene layer")
	check(not ui.decor_nodes["counter"].visible and not ui.decor_nodes["deck"].visible, "Unpurchased decor stays hidden in live scene")
	ui.progress.data.wallet = 100
	ui.shop()
	check(ui.modal.get_node_or_null("Panel") == null, "Decor shop uses native modal")
	check(ui.modal.get_child_count() > 15, "Decor shop previews all six produced replacement assets")
	ui.close_modal()
	# Exercise UI for special visits used by the final-day schedule.
	for id in ["snowy","jiwoo","spf8","mimi"]:
		ui.close_modal()
		ui.model=Model.new({"duration":60,"target":10,"guests":[id],"arrivals":[{"time":1,"guest":id,"seat":2}]})
		ui.model.started=true
		ui.model.update(1.1)
		ui._process(0)
		ui.dialogue(ui.model.at(2))
		check(ui.modal!=null,"Special guest dialogue: "+id)
	ui.close_modal()
	ui.model.hand = {"drink":"芒果冰沙"}
	ui.model.ready = {"drink":"椰子水"}
	await process_frame
	await process_frame
	ui.confirm_discard()
	check(ui.modal != null and ui.model.paused, "Discard confirmation pauses gameplay")
	ui.close_modal()
	check(not ui.model.hand.is_empty() and not ui.model.ready.is_empty(), "Cancel preserves both cups")
	await process_frame
	await process_frame
	ui.confirm_discard()
	for child in ui.modal.get_children():
		if child is Button and child.text.begins_with("确认倒掉出酒口"):
			child.pressed.emit()
			break
	check(ui.model.ready.is_empty() and not ui.model.hand.is_empty() and ui.modal == null, "Confirm targets only selected supply slot")
	ui._process(0)
	check(ui.held_icon.texture != null and ui.held_caption.text == "手持 · 有杯", "Held drink remains visible in its independent production slot")
	ui.close_modal()
	ui.model = Model.new({"duration":60,"target":10,"guests":["bobo"],"arrivals":[{"time":1,"guest":"bobo","seat":2}]})
	ui.model.started = true
	ui.model.update(1.1)
	ui.model.direction = 2
	ui.model.interact()
	ui.model.hand = {"drink":"芒果冰沙"}
	ui.model.reconcile_queue()
	ui.model.interact()
	ui.model.update(2.1)
	await process_frame
	await process_frame
	ui._process(0)
	check(ui.sprites[2].modulate.a == 0 and not ui.bars[2].visible and ui.seats[2].text.contains("用过的杯子 ×1"), "Bill UI hides guest and timer, shows used cups")
	check(ui.action.text == "收钱清台" and not ui.action.disabled, "Empty visitor table still exposes collection action")
	ui.interact()
	ui._process(0)
	check(ui.modal == null and ui.model.served == 1 and ui.seats[2].text.is_empty() and not ui.bubbles[2].visible, "Collection bypasses dialogue and frees table")
	ui.restart(false)
	check(ui.model.bills.is_empty() and ui.model.visitors.is_empty(), "Restart clears transient table state")
	ui.close_modal()
	await process_frame
	await process_frame
	ui.model = Model.new({"duration":60,"target":10,"guests":["horn"],"arrivals":[{"time":1,"guest":"horn","seat":2}]})
	ui.model.started = true
	ui.model.update(1.1)
	ui.model.direction = 2
	ui.model.interact()
	ui.model.hand = {"drink":"芒果冰沙"}
	ui._process(0)
	check(not ui.has_method("review_selected_order"), "Order review control is removed")
	check(ui.bubbles[2].visible and ui.bubble_labels[2].text == "青柠苏打", "Pending drink stays in the guest speech bubble")
	check(ui.icons[2].texture != null, "Pending drink keeps its table icon")
	ui.tutorial = false
	ui._process(0)
	check(not ui.tutorial_label.visible and not ui.tutorial_panel.visible, "Hidden tutorial also removes empty panel")
	ui._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var focus_time: float = ui.model.elapsed
	ui._process(2)
	check(ui.model.elapsed == focus_time and ui.model.paused, "Focus loss freezes gameplay")
	ui._notification(Control.NOTIFICATION_APPLICATION_FOCUS_IN)
	ui.close_modal()
	ui.restart(false)
	var ambient_path := "user://ambient_smoke_only.cfg"
	ui.ambient.settings_path = ambient_path
	ui.ambient.set_reduced_motion(false)
	ui.close_modal()
	var clock: float = ui.ambient.clock
	ui._process(0.5)
	check(ui.ambient.clock > clock, "Ambient runs during service")
	ui.pause_game()
	clock = ui.ambient.clock
	ui._process(1)
	check(ui.ambient.clock == clock, "Paused ambient clock freezes")
	ui.close_modal()
	ui.focus_paused = true
	ui._process(1)
	check(ui.ambient.clock == clock, "Focus loss freezes ambient")
	ui.focus_paused = false
	check(ui.ambient.set_reduced_motion(true) == OK, "Reduced motion preference saves")
	ui._process(1)
	check(ui.ambient.clock == clock and ui.ambient.water_material.get_shader_parameter("motion_amount") == 0.0, "Reduced motion disables water and light updates")
	var preferences := ConfigFile.new()
	check(preferences.load(ambient_path) == OK and preferences.get_value("accessibility","reduced_motion") == true, "Reduced motion persists on disk")
	ui.ambient.set_reduced_motion(false)
	check(ui.ambient.light_strength(0) != ui.ambient.light_strength(1), "Lamps have independent phases")
	var bounded := true
	for n in 600:
		ui.ambient.advance(1.0/60.0)
		for i in 8:
			bounded = bounded and ui.ambient.light_strength(i) >= 0.61 and ui.ambient.light_strength(i) <= 0.95
	check(bounded, "Ten second light envelope bounded")
	ui.model.ended = true
	clock = ui.ambient.clock
	ui._process(0.5)
	check(ui.ambient.clock == clock, "Closing freezes ambient")
	DirAccess.remove_absolute(ambient_path)
	ui.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	print("Godot UI smoke: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
