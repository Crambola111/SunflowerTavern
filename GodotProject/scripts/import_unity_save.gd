extends SceneTree
# Explicit one-time command, refuses to overwrite an existing Godot save.
const Progress = preload("res://scripts/progress_store.gd")
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Usage: godot --headless --path GodotProject --script res://scripts/import_unity_save.gd -- /absolute/path/unity_save.json")
		quit(1)
		return
	var target := "user://progress_v2.json"
	if FileAccess.file_exists(target):
		push_error("Godot save already exists. Back it up and move it aside before importing. No changes made.")
		quit(1)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var store := Progress.new()
	if not store.valid(parsed):
		push_error("Invalid exported save; no changes made.")
		quit(1)
		return
	store.data = parsed
	if not store.save():
		push_error(store.error)
		quit(1)
		return
	print("Imported save to ",ProjectSettings.globalize_path(target))
	quit(0)
