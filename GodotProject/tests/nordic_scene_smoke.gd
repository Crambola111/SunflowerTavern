extends RefCounted

const Maps = preload("res://scripts/map_config.gd")

func run() -> bool:
	assert(Maps.map_name(Maps.MAP02) == "北欧极光峡湾")
	assert(Maps.next_map(Maps.MAP02) == Maps.MAP03)
	assert(Maps.next_map_name(Maps.MAP02) == "希腊古城")
	assert(not Maps.playable(Maps.MAP03, 1))
	return true
