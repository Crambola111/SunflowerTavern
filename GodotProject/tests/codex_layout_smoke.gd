extends SceneTree

const Scene = preload("res://scenes/island.tscn")
const Config = preload("res://scripts/day_config.gd")
const Maps = preload("res://scripts/map_config.gd")
const Progress = preload("res://scripts/progress_store.gd")

var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var save_path := "user://codex_layout_smoke.json"
	DirAccess.remove_absolute(save_path)
	var ui = Scene.instantiate()
	root.add_child(ui)
	ui.progress = Progress.new(save_path)
	ui.reset_day()
	var available: Array = Maps.available_guests(ui.map_id)
	var first_id: String = available[0]
	var second_id: String = available[1]
	ui.model.codex[first_id] = true
	ui.model.codex[second_id] = true
	ui.codex(0)
	var first_card: Button = ui.modal.get_node("CodexCard_%s" % first_id)
	var second_card: Button = ui.modal.get_node("CodexCard_%s" % second_id)
	check(first_card.position.x >= 150 and second_card.position.x + second_card.size.x < 720, "Guest cards stay within the left-page safe area")
	check(first_card.size.x >= 150 and first_card.size.y >= 150, "Guest card hit target covers the full portrait card")
	var detail_name: Label = ui.modal.get_node("CodexDetailName")
	check(detail_name.position.x + detail_name.size.x / 2.0 == 1150, "Right-page detail is centered")
	check(ui.modal.get_node("PagePreviousButton").get_child_count() > 0 and ui.modal.get_node("PageNextButton").get_child_count() > 0, "Pagination uses dedicated previous and next artwork")
	second_card.pressed.emit()
	check(ui.modal.get_meta("selected_index") == 1, "Guest card click changes the selected guest")
	check(ui.modal.get_node("CodexDetailName").text == Config.guest(second_id).name, "Right-page detail updates to the clicked guest")
	print("CODEX_LAYOUT_SMOKE %d checks, %d failures" % [checks, failures])
	DirAccess.remove_absolute(save_path)
	quit(1 if failures > 0 else 0)
