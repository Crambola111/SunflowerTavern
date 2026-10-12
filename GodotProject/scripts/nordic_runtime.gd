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
