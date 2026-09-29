class_name DayConfig
extends RefCounted

const GUESTS = preload("res://data/guests.json")
const DAYS = preload("res://data/days.json")

static func guest(id: String, night := false) -> Dictionary:
	var g: Dictionary = GUESTS.data[id].duplicate(true)
	if id == "jiwoo" and night:
		g.drink = "夜间无酒精特调"
		g.price = 16
		g.brew = 4.0
	return g

static func available_guests() -> Array:
	return ["bobo", "coco", "horn", "tank", "gecko", "mimi", "spf8"]

static func playable(day: int) -> bool:
	return day >= 1 and day <= 3

static func for_day(day: int) -> Dictionary:
	assert(playable(day), "Day not implemented")
	var config: Dictionary = DAYS.data[day - 1].duplicate(true)
	assert(validate(config))
	return config

static func validate(config: Dictionary) -> bool:
	if not config.has_all(["duration", "target", "guests", "arrivals"]):
		return false
	if not is_finite(float(config.duration)) or config.duration <= 0 or config.target <= 0:
		return false
	if config.guests.is_empty() or config.arrivals.is_empty():
		return false
	var seen := {}
	for id in config.guests:
		if not GUESTS.data.has(id) or seen.has(id):
			return false
		seen[id] = true
		var g: Dictionary = GUESTS.data[id]
		if g.price <= 0 or g.cups < 1 or g.cups > 2 or not is_finite(float(g.brew)) or g.brew <= 0:
			return false
	var previous := -1.0
	for a in config.arrivals:
		if not a.has_all(["time", "guest", "seat"]):
			return false
		if not is_finite(float(a.time)) or a.time < 0 or a.time >= config.duration or a.time < previous:
			return false
		if not seen.has(a.guest) or a.seat < 1 or a.seat > 7:
			return false
		previous = a.time
	return true
