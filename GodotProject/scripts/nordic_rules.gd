class_name NordicRules
extends RefCounted

const MAP_ID := "nordic"
const WARM_GUESTS := ["moose", "lynx", "squirrel", "reindeer", "ingrid", "santa"]
const COLD_GUESTS := ["seal", "puffin", "arctic_fox", "raven"]
const HOT_DRINKS := ["越橘热饮", "烤苹果肉桂饮", "雪顶枫糖拿铁", "云莓热果饮", "豆蔻燕麦热乳", "肉桂热可可"]
const COLD_DRINKS := ["极光莓果苏打"]
const CAMPFIRE_COOLDOWN := 18.0
const CAMPFIRE_WARMTH := 5.0
const HOT_DRINK_WARMTH := 8.0
const COLD_DRINK_PATIENCE := 2.0

static func active(config: Dictionary) -> bool:
	return config.get("map_id", "") == MAP_ID

static func warmth_required(guest_id: String) -> bool:
	return guest_id in WARM_GUESTS

static func cold_preferred(guest_id: String) -> bool:
	return guest_id in COLD_GUESTS

static func is_hot(drink: String) -> bool:
	return drink in HOT_DRINKS

static func is_cold(drink: String) -> bool:
	return drink in COLD_DRINKS

static func drink_effect(guest_id: String, drink: String) -> String:
	if warmth_required(guest_id) and is_hot(drink):
		return "warmth"
	if cold_preferred(guest_id) and is_cold(drink):
		return "refresh"
	return ""

static func warmth_limit(assisted: bool) -> float:
	return 22.0 if assisted else 16.0
