extends RefCounted

const Rules = preload("res://scripts/nordic_rules.gd")

func run() -> bool:
	assert(Rules.active({"map_id":"nordic"}))
	assert(Rules.warmth_required("moose"))
	assert(not Rules.warmth_required("seal"))
	assert(Rules.is_hot("肉桂热可可"))
	assert(Rules.is_cold("极光莓果苏打"))
	assert(Rules.warmth_limit(false) < Rules.warmth_limit(true))
	return true
