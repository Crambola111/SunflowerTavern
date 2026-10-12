extends "res://scripts/island.gd"

# Reuse shared UI, themed assets and gameplay; keep Nordic progress separate.
func _ready() -> void:
	map_id = Maps.MAP02
	super._ready()
