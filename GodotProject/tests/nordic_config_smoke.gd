extends SceneTree

const Maps = preload("res://scripts/map_config.gd")

func _initialize() -> void:
	var checks := 0
	for day in range(1, 5):
		var config := Maps.for_day(Maps.MAP02, day)
		assert(config.duration == 120 and config.target > 0)
		assert(config.arrivals.size() >= 5 and config.arrivals.size() <= 10)
		checks += 3
	assert(Maps.available_guests(Maps.MAP02).size() == 10)
	assert(Maps.for_day(Maps.MAP02, 4).arrivals[-1].guest == "santa")
	checks += 2
	print("Nordic config smoke: %d checks" % checks)
	quit()
