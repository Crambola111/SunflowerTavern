extends RefCounted

const Maps = preload("res://scripts/map_config.gd")

func run() -> bool:
	assert(Maps.map_name(Maps.MAP02) == "北欧极光峡湾")
	return true
