class_name NordicRuntime
extends RefCounted

const Maps = preload("res://scripts/map_config.gd")
const Model = preload("res://scripts/tavern_model.gd")
const Store = preload("res://scripts/nordic_progress_store.gd")

var progress: RefCounted
var current_day := 1
var assisted := false
var model: RefCounted

func _init(save_path := "user://nordic_progress_v1.json") -> void:
	progress = Store.new(save_path)

func can_enter(day: int) -> bool:
	return progress.unlocked(day)

func map_cleared() -> bool:
	return progress.cleared(4)

func next_map_id() -> String:
	return Maps.next_map(Maps.MAP02)

func next_map_ready() -> bool:
	# The route is recorded for the future Greece slice, but the scene remains locked.
	return map_cleared() and not Maps.playable(next_map_id(), 1)

func use_campfire() -> bool:
	return model != null and model.use_campfire()

func start(day: int, use_assistance := false) -> RefCounted:
	assert(can_enter(day), "Nordic day is locked")
	current_day = day
	assisted = use_assistance
	model = Model.new(Maps.for_day(Maps.MAP02, day), assisted)
	model.started = true
	return model

func settle() -> bool:
	if model == null or not model.ended:
		return false
	return progress.record(current_day, model.coins, model.day.target, assisted)
