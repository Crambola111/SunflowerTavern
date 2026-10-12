extends SceneTree

const Store = preload("res://scripts/nordic_progress_store.gd")

func _initialize() -> void:
	var path := "user://nordic_progress_smoke.json"
	DirAccess.remove_absolute(path)
	var store := Store.new(path)
	assert(store.unlocked(1) and not store.unlocked(2))
	assert(store.record(1,150,150,false) and store.unlocked(2))
	assert(not store.record(3,275,275,false))
	assert(store.record(2,205,205,true) and store.unlocked(3))
	var reload := Store.new(path)
	assert(reload.data.best[1][1] == 205 and reload.cleared(2))
	DirAccess.remove_absolute(path)
	print("Nordic progress smoke: 5 checks")
	quit()
