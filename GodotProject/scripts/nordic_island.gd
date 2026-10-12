extends "res://scripts/island.gd"

const Maps = preload("res://scripts/map_config.gd")

# The Nordic map reuses the proven service scene while selecting its own
# day data and progress lane. Keeping this as a thin scene adapter means the
# first map's save/decor/codex data stays backward compatible.
func _ready() -> void:
	map_id = Maps.MAP02
	super._ready()
