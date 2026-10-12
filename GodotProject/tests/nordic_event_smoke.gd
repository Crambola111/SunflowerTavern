extends RefCounted

const Maps = preload("res://scripts/map_config.gd")
const Event = preload("res://scripts/nordic_event.gd")

func run() -> bool:
	var day4 := Maps.for_day(Maps.MAP02, 4)
	assert(Event.santa_finale(day4))
	assert(Event.dialogue(0).begins_with("圣诞老人"))
	assert(Event.reward({"santa": true}, true) == 50)
	assert(Event.reward({}, true) == 0)
	return true
