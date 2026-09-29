class_name ProgressStore
extends RefCounted

const Config = preload("res://scripts/day_config.gd")
const VERSION := 2
const PRICES := [30, 45, 60]
var path: String
var data := {"version": VERSION, "wallet": 0, "tip_remainder": 0.0, "tutorial_done": false,
	"decorations": [false, false, false], "codex": [], "best": [[0,0],[0,0],[0,0],[0,0]],
	"cleared": [[false,false],[false,false],[false,false],[false,false]]}
var error := ""

func _init(save_path := "user://progress_v2.json") -> void:
	path = save_path
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not valid(parsed):
			error = "存档损坏或版本不受支持；原文件未修改。请备份后恢复存档。"
			return
		data = parsed

func valid(value: Variant) -> bool:
	if not value is Dictionary or not value.has_all(data.keys()):
		return false
	if value.version != VERSION or not number(value.wallet) or value.wallet < 0 or value.wallet != floor(value.wallet):
		return false
	if not number(value.tip_remainder) or value.tip_remainder < 0 or value.tip_remainder >= 1:
		return false
	if not value.tutorial_done is bool or not value.codex is Array or not value.decorations is Array or value.decorations.size() != 3:
		return false
	for owned in value.decorations:
		if not owned is bool:
			return false
	for id in value.codex:
		if not id is String or not Config.GUESTS.data.has(id):
			return false
	if not value.best is Array or not value.cleared is Array or value.best.size() != 4 or value.cleared.size() != 4:
		return false
	for i in 4:
		if not value.best[i] is Array or not value.cleared[i] is Array or value.best[i].size() != 2 or value.cleared[i].size() != 2:
			return false
		for mode in 2:
			if not number(value.best[i][mode]) or value.best[i][mode] < 0 or value.best[i][mode] != floor(value.best[i][mode]) or not value.cleared[i][mode] is bool:
				return false
			if i > 0 and value.cleared[i][mode] and not (value.cleared[i-1][0] or value.cleared[i-1][1]):
				return false
	return true

func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func save() -> bool:
	if not error.is_empty():
		return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		error = "无法写入存档：" + error_string(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		error = "存档写入失败，原文件保留。"
		return false
	var result := DirAccess.rename_absolute(path + ".tmp", path)
	if result != OK:
		error = "存档替换失败：" + error_string(result)
		return false
	return true

func cleared(day: int) -> bool:
	return day >= 1 and day <= 4 and (data.cleared[day-1][0] or data.cleared[day-1][1])

func unlocked(day: int) -> bool:
	return day >= 1 and day <= 4 and (day == 1 or cleared(day-1))

func can_enter(day: int) -> bool:
	return Config.playable(day) and unlocked(day)

func owns(index: int) -> bool:
	return index >= 0 and index < 3 and data.decorations[index]

func unlock(id: String) -> void:
	if Config.GUESTS.data.has(id) and not data.codex.has(id):
		data.codex.append(id)
		save()

func complete_tutorial() -> void:
	if not data.tutorial_done:
		data.tutorial_done = true
		save()

func purchase(index: int) -> bool:
	if index < 0 or index >= 3 or owns(index) or data.wallet < PRICES[index] or not error.is_empty():
		return false
	data.wallet -= PRICES[index]
	data.decorations[index] = true
	return save()

func complete_day(day: int, income: int, target: int, remainder: float, assisted: bool) -> bool:
	if not unlocked(day) or income < 0 or target <= 0 or not is_finite(remainder) or remainder < 0 or remainder >= 1 or not error.is_empty():
		return false
	var mode := 1 if assisted else 0
	data.best[day-1][mode] = maxi(data.best[day-1][mode], income)
	data.cleared[day-1][mode] = data.cleared[day-1][mode] or income >= target
	data.wallet = mini(2147483647, data.wallet + income)
	data.tip_remainder = remainder
	return save()
