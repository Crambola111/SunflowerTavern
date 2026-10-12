class_name NordicProgressStore
extends RefCounted

const VERSION := 2
const DECOR_PRICES := [40, 55, 65, 70, 80, 95, 60, 75, 85, 90, 100, 115]
var path: String
var data := {"version": VERSION, "best": [[0,0],[0,0],[0,0],[0,0]], "cleared": [[false,false],[false,false],[false,false],[false,false]], "decorations": [false, false, false, false, false, false, false, false, false, false, false, false]}
var error := ""

func _init(save_path := "user://nordic_progress_v1.json") -> void:
	path = save_path
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary and parsed.get("version", 0) == 1:
			parsed.version = VERSION
			parsed.decorations = [false, false, false, false, false, false, false, false, false, false, false, false]
		if not valid(parsed):
			error = "北欧地图存档损坏或版本不受支持。"
			return
		data = parsed

func valid(value: Variant) -> bool:
	if not value is Dictionary or value.version != VERSION or not value.has_all(["best", "cleared", "decorations"]):
		return false
	if not value.decorations is Array or value.decorations.size() != DECOR_PRICES.size():
		return false
	for owned in value.decorations:
		if not owned is bool:
			return false
	if value.best.size() != 4 or value.cleared.size() != 4:
		return false
	for i in 4:
		if value.best[i].size() != 2 or value.cleared[i].size() != 2:
			return false
		for mode in 2:
			if not (value.best[i][mode] is int or value.best[i][mode] is float) or value.best[i][mode] < 0 or not value.cleared[i][mode] is bool:
				return false
			if i > 0 and value.cleared[i][mode] and not (value.cleared[i-1][0] or value.cleared[i-1][1]):
				return false
	return true

func cleared(day: int) -> bool:
	return day >= 1 and day <= 4 and (data.cleared[day-1][0] or data.cleared[day-1][1])

func unlocked(day: int) -> bool:
	return day >= 1 and day <= 4 and (day == 1 or cleared(day-1))

func owns_decor(index: int) -> bool:
	return index >= 0 and index < data.decorations.size() and data.decorations[index]

func purchase_decor(index: int, wallet: int) -> Dictionary:
	if index < 0 or index >= DECOR_PRICES.size() or owns_decor(index) or wallet < DECOR_PRICES[index] or not error.is_empty():
		return {"ok": false, "wallet": wallet}
	data.decorations[index] = true
	if not save():
		data.decorations[index] = false
		return {"ok": false, "wallet": wallet}
	return {"ok": true, "wallet": wallet - DECOR_PRICES[index]}

func reset_all() -> bool:
	if not error.is_empty():
		return false
	data = {"version": VERSION, "best": [[0,0],[0,0],[0,0],[0,0]], "cleared": [[false,false],[false,false],[false,false],[false,false]], "decorations": [false, false, false, false, false, false, false, false, false, false, false, false]}
	return save()

func record(day: int, income: int, target: int, assisted: bool) -> bool:
	if not unlocked(day) or income < 0 or target <= 0 or not error.is_empty():
		return false
	var mode := 1 if assisted else 0
	data.best[day-1][mode] = maxi(data.best[day-1][mode], income)
	data.cleared[day-1][mode] = data.cleared[day-1][mode] or income >= target
	return save()

func save() -> bool:
	if not error.is_empty():
		return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		error = "无法写入北欧地图存档。"
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var result := DirAccess.rename_absolute(path + ".tmp", path)
	if result != OK:
		error = "北欧地图存档替换失败。"
		return false
	return true
