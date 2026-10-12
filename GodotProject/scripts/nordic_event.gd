class_name NordicEvent
extends RefCounted

const SANTA_ID := "santa"
const REWARD := 50

static func santa_finale(config: Dictionary) -> bool:
	return config.get("map_id", "") == "nordic" and config.get("day", 0) == 4 and config.arrivals.back().guest == SANTA_ID

static func dialogue(step: int) -> String:
	match step:
		0:
			return "圣诞老人：今年不送礼，我只是请年假。"
		1:
			return "圣诞老人：肉桂热可可，少糖。假期也不能太放纵。"
		2:
			return "圣诞老人：这杯热得刚好。给你一枚‘临时好老板’奖章。"
	return ""

static func reward(codex: Dictionary, passed: bool) -> int:
	return REWARD if passed and codex.has(SANTA_ID) else 0
