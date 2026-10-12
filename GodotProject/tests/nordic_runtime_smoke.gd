extends SceneTree

const Runtime = preload("res://scripts/nordic_runtime.gd")

func _initialize() -> void:
	var path := "user://nordic_runtime_smoke.json"
	DirAccess.remove_absolute(path)
	var runtime := Runtime.new(path)
	var model := runtime.start(1)
	assert(model.day.map_id == "nordic" and model.day.map_name == "北欧极光峡湾")
	assert(model.day.target == 150 and runtime.current_day == 1)
	assert(runtime.next_map_id() == "greece" and not runtime.next_map_ready())
	assert(runtime.use_campfire())
	assert(model.campfire_uses == 1)
	model.ended = true
	model.coins = 150
	assert(runtime.settle() and runtime.can_enter(2))
	assert(not runtime.map_cleared() and runtime.next_map_ready() == false)
	DirAccess.remove_absolute(path)
	print("Nordic runtime smoke: 4 checks")
	quit()
