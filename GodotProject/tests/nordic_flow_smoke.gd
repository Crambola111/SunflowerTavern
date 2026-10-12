extends RefCounted

const Maps = preload("res://scripts/map_config.gd")
const Model = preload("res://scripts/tavern_model.gd")
const Rules = preload("res://scripts/nordic_rules.gd")
const Event = preload("res://scripts/nordic_event.gd")

func run() -> bool:
	var expected_targets := [150, 205, 275, 350]
	var seen := {}
	for day in range(1, 5):
		var config: Dictionary = Maps.for_day(Maps.MAP02, day)
		assert(config.map_id == Maps.MAP02)
		assert(config.map_name == "北欧极光峡湾")
		assert(config.target == expected_targets[day - 1])
		assert(config.arrivals.size() >= 5 and config.arrivals.size() <= 10)
		for id in config.guests:
			seen[id] = true
			assert(id in Maps.NORDIC_GUESTS)
		for arrival in config.arrivals:
			assert(arrival.guest in config.guests)
	assert(seen.size() == 10)
	assert(Rules.is_hot("肉桂热可可") and Rules.is_cold("极光莓果苏打"))
	assert(Rules.warmth_required("moose") and not Rules.warmth_required("seal"))
	assert(Rules.cold_preferred("puffin") and Rules.cold_preferred("raven"))
	assert(Event.santa_finale(Maps.for_day(Maps.MAP02, 4)))
	var model := Model.new(Maps.for_day(Maps.MAP02, 1))
	model.started = true
	model.update(8.1)
	assert(model.at(2).guest.id == "moose")
	var before := model.at(2).warmth_remaining
	assert(model.use_campfire())
	assert(model.at(2).warmth_remaining > before)
	assert(not model.use_campfire())
	return true
