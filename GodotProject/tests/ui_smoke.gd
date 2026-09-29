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
	ui.welcome()
	check(ui.modal != null and ui.model.paused,"Welcome pauses game")
	for asset in ui.art.UI_REGIONS:
		var atlas = ui.art.ui_texture(asset)
		check(atlas.atlas != null and Rect2(Vector2.ZERO, atlas.atlas.get_size()).encloses(atlas.region), "Approved UI atlas loads within original: " + asset)
	check(ui.bubbles.size() == 8 and ui.bubbles[2].mouse_filter == Control.MOUSE_FILTER_IGNORE, "Order artwork preserves table input")
	ui.close_modal()
	await process_frame
	await process_frame
	check(ui.can_input(),"Closing modal restores input")
	ui.model.update(8.1)
	ui.model.direction=2
	ui.interact()
	check(ui.modal != null and ui.model.paused,"Order opens paused dialogue")
	# Find the real signal callback and accept through it.
	for child in ui.modal.get_children():
		if child is Button and child.text == "马上来！":
			child.pressed.emit()
			break
	check(ui.model.queue.size()==1 and ui.modal==null,"Dialogue acceptance queues order")
	ui.pause_game()
	var before: float=ui.model.elapsed
	ui._process(2)
	check(ui.model.elapsed==before,"Pause menu freezes clock")
	ui.codex(0)
	check(ui.modal != null,"Locked codex opens")
	ui.model.codex["bobo"]=true
	ui.codex(0)
	check(ui.art.portrait("bobo")!=null,"Unlocked codex portrait loads")
	ui.progress.data.wallet=100
	ui.shop()
	for child in ui.modal.get_children():
		if child is Button and child.text=="30 金币":
			child.pressed.emit()
			break
	check(ui.progress.owns(0) and ui.model.patience_multiplier==1.05,"Shop signal purchases and applies bonus")
	ui.progress.complete_day(1,79,70,0,false)
	ui.model.ended=true
	ui.choose_day(2)
	check(ui.current_day==2 and ui.model.paused and ui.model.elapsed==0,"Choose unlocked Day2 resets and opens welcome")
	ui.restart(true)
	check(ui.model.assisted and ui.current_day==2,"Assist restart preserves day")
	ui.close_modal()
	ui.model.update(120)
	ui._process(0)
	var wallet: int=ui.progress.data.wallet
	ui.settlement()
	ui.close_modal()
	ui._process(0)
	check(ui.progress.data.wallet==wallet,"Reopening settlement cannot double pay")
	for id in ["bobo","coco","horn","tank","gecko"]:
		check(ui.art.portrait(id)!=null,"Portrait loaded: "+id)
	for drink in ui.art.DRINKS:
		check(ui.art.drink(drink)!=null,"Drink loaded: "+drink)
	check(ui.art.chibi("tank")==null and ui.art.chibi("horn")!=null and ui.art.chibi("mimi")!=null and ui.art.chibi("bobo")!=null and ui.art.chibi("coco")!=null and ui.art.chibi("bobo")!=ui.art.portrait("bobo"),"Seated sprites load separately; missing chibi has no portrait fallback")
	# Exercise UI for special visits outside the still-unimplemented Day4 schedule.
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
	check(ui.queue_label.text == "手持：芒果冰沙 · 同款可互送", "HUD does not assign an exclusive recipient")
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
	ui.model.at(2).bubble = 0
	ui.model.hand = {"drink":"芒果冰沙"}
	ui._process(0)
	check(ui.review_order.visible and not ui.review_order.disabled, "Held cup exposes explicit order review")
	var review_patience: float = ui.model.at(2).patience
	var review_jobs: int = ui.model.queue.size()
	ui.review_order.pressed.emit()
	check(ui.modal != null and ui.model.paused and ui.model.hand.drink == "芒果冰沙", "Review pauses and preserves held cup")
	ui._process(3)
	check(ui.model.at(2).patience == review_patience and ui.model.queue.size() == review_jobs, "Review neither penalizes nor duplicates orders")
	ui.close_modal()
	await process_frame
	await process_frame
	ui._process(0)
	check(ui.model.at(2).bubble > 0 and ui.icons[2].texture != null, "Explicit review restores Horn short-lived bubble")
	ui.tutorial = false
	ui._process(0)
	check(not ui.tutorial_label.visible and not ui.tutorial_panel.visible, "Hidden tutorial also removes empty panel")
	ui._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var focus_time: float = ui.model.elapsed
	ui._process(2)
	check(ui.model.elapsed == focus_time and ui.model.paused, "Focus loss freezes gameplay with review controls present")
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
