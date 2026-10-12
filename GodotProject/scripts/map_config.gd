class_name MapConfig
extends RefCounted


const Base = preload("res://scripts/day_config.gd")
const NORDIC_DAYS = preload("res://data/nordic_days.json")


const MAP01 := "southwind"
const MAP02 := "nordic"
const MAP03 := "greece"
const NORDIC_GUESTS := ["moose", "seal", "puffin", "lynx", "squirrel", "raven", "reindeer", "arctic_fox", "ingrid", "santa"]


static func days(map_id: String) -> Array:
	if map_id == MAP02:
		return NORDIC_DAYS.data
	return [Base.for_day(1), Base.for_day(2), Base.for_day(3), Base.for_day(4)]


static func playable(map_id: String, day: int) -> bool:
	return map_id in [MAP01, MAP02] and day >= 1 and day <= 4


static func next_map(map_id: String) -> String:
	if map_id == MAP01:
		return MAP02
	if map_id == MAP02:
		return MAP03
	return ""

static func for_day(map_id: String, day: int) -> Dictionary:
	assert(playable(map_id, day), "Map day not implemented")
	var config: Dictionary = days(map_id)[day - 1].duplicate(true)
	config.map_id = map_id
	config.map_name = map_name(map_id)
	assert(Base.validate(config))
	return config


static func available_guests(map_id: String) -> Array:
	return NORDIC_GUESTS if map_id == MAP02 else Base.available_guests()


static func map_name(map_id: String) -> String:
	if map_id == MAP02:
		return "北欧极光峡湾"
	if map_id == MAP03:
		return "希腊古城"
	return "椰风岛"

static func next_map_name(map_id: String) -> String:
	return map_name(next_map(map_id)) if not next_map(map_id).is_empty() else ""

