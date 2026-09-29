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
	ui.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	print("Godot UI smoke: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
