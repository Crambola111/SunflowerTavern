class_name TavernModel
extends RefCounted

const Config = preload("res://scripts/day_config.gd")
enum State { ORDER, WAITING, DRINKING, PAYMENT }
var day: Dictionary
var assisted := false
var visitors: Array[Dictionary] = []
var queue: Array[Dictionary] = []
var codex := {}
var ready: Dictionary = {}
var hand: Dictionary = {}
var elapsed := 0.0
var patience_multiplier := 1.0
var brew_speed := 1.0
var tip_multiplier := 1.0
var tip_remainder := 0.0
var direction := 0
var coins := 0
var combo := 0
var best_combo := 0
var served := 0
var missed := 0
var stolen_coins := 0
var started := false
var paused := false
var ended := false
var message := "欢迎来到南风岛。开始营业后，面向客人接单。"
var spawned := {}
var settlement_claimed := false

func _init(config: Dictionary = {}, use_assistance := false) -> void:
	day = Config.for_day(1) if config.is_empty() else config.duplicate(true)
	assert(Config.validate(day))
	assisted = use_assistance

func passed() -> bool:
	return ended and coins >= day.target

# -1 means unavailable; zero is a valid payout.
func claim_settlement() -> int:
	if not ended or settlement_claimed:
		return -1
	settlement_claimed = true
	return coins

func at(seat: int) -> Dictionary:
	for v in visitors:
		if v.seat == seat:
			return v
	return {}

func blocked(seat: int) -> bool:
	for v in visitors:
		if seat != 0 and v.blocked == seat:
			return true
	return false

func owner(cup: Dictionary) -> Dictionary:
	if cup.is_empty():
		return {}
	for v in visitors:
		if v.id == cup.owner:
			return v
	return {}

func needs_cooling(v: Dictionary) -> bool:
	return v.guest.id == "snowy" and v.state in [State.ORDER, State.WAITING]

func mimi_warning(v: Dictionary) -> bool:
	return v.guest.id == "mimi" and v.state == State.WAITING and not v.mimi_attempted and v.mimi_away >= 3

func tank_attention(v: Dictionary) -> bool:
	return v.guest.id == "tank" and not v.tank_ready

func order_text(v: Dictionary) -> String:
	return v.guest.drink + (" · 已送 %d/%d 杯" % [v.delivered, v.guest.cups] if v.guest.cups > 1 else "")

func turn(delta: int) -> void:
	if started and not paused and not ended:
		direction = posmod(direction + delta, 8)

func interact() -> void:
	if not started or paused or ended:
		return
	if direction == 0:
		if not hand.is_empty():
			message = "先把手上的饮品送出去。"
		elif not ready.is_empty():
			hand = ready
			ready = {}
			message = "取杯成功，去杯子标注的座位送达。"
		else:
			message = "正在制作，先照顾其他客人。" if not queue.is_empty() else "先向客人接单。"
		return
	var v := at(direction)
	if v.is_empty():
		message = "Coco 的行李占着这里。" if blocked(direction) else "这里暂时没有客人。"
		return
	match v.state:
		State.ORDER:
			if tank_attention(v):
				v.tank_ready = true
				v.bubble = 2.5
				message = "Tank 摘下呼吸器：原来这里不是水下免税店。再互动正式接单。"
				return
			v.state = State.WAITING
			v.bubble = 2.5
			for n in int(v.guest.cups):
				queue.append({"owner": v.id, "drink": v.guest.drink, "remaining": float(v.guest.brew), "duration": float(v.guest.brew)})
			message = "订单已送到出酒口，自动开始制作。"
		State.WAITING:
			if mimi_warning(v):
				v.mimi_attempted = true
				message = "Mimi：我只是帮金币拍张游客照！已打断，再互动可送饮品。"
				return
			if hand.is_empty():
				v.bubble = 2.5
				message = v.guest.name + "：" + order_text(v)
				return
			if hand.owner != v.id:
				v.patience = maxf(0, v.patience - 2)
				v.bubble = 2.5
				if v.patience <= 0:
					miss(v)
				else:
					var recipient := owner(hand)
					message = "送错了，耐心 -2 秒。" + ("这杯请送到 P%d。" % recipient.seat if not recipient.is_empty() else "")
				return
			hand = {}
			v.delivered += 1
			if v.delivered < v.guest.cups:
				v.bubble = 2.5
				message = "已送 %d/%d 杯，再去取剩下的饮品。" % [v.delivered, v.guest.cups]
				return
			v.tip = 3 if v.patience >= 17.5 else (1 if v.patience >= 7.5 else 0)
			v.state = State.DRINKING
			v.timer = 2.0
			message = "Snowy：终于从雪水切回雪人模式了。喝完记得收钱！" if v.guest.id == "snowy" else "送达！喝完之后记得收钱。"
		State.PAYMENT:
			combo += 1
			best_combo = maxi(combo, best_combo)
			var gain: int = int(v.guest.price + v.tip) + mini(5, maxi(0, combo - 2))
			tip_remainder += v.tip * maxf(0, tip_multiplier - 1)
			var extra := int(floor(tip_remainder))
			tip_remainder -= extra
			coins += gain + extra
			served += 1
			codex[v.guest.id] = true
			remove_visit(v)
			message = "收到 %d 金币！" % (gain + extra)
		_:
			message = "客人正在喝饮品。"

func remove_visit(v: Dictionary) -> void:
	visitors.erase(v)
	queue = queue.filter(func(c): return c.owner != v.id)
	if not ready.is_empty() and ready.owner == v.id:
		ready = {}
	if not hand.is_empty() and hand.owner == v.id:
		hand = {}

func miss(v: Dictionary) -> void:
	missed += 1
	combo = 0
	remove_visit(v)
	message = v.guest.name + " 走了。下一单继续！"

func update(delta: float) -> void:
	if not started or paused or ended or not is_finite(delta) or delta <= 0:
		return
	while delta > 0 and not ended:
		var dt := minf(0.05, delta)
		tick(dt)
		delta -= dt

func tick(dt: float) -> void:
	elapsed = minf(day.duration, elapsed + dt)
	# Stable two-pass ordering: due Jiwoo reservations before ordinary arrivals.
	var indices: Array = range(day.arrivals.size())
	var surprise_due := func(i): return not spawned.has(i) and elapsed >= day.arrivals[i].time and day.arrivals[i].guest == "jiwoo"
	var ordered: Array = indices.filter(surprise_due)
	ordered.append_array(indices.filter(func(i): return not surprise_due.call(i)))
	for i in ordered:
		var arrival: Dictionary = day.arrivals[i]
		if spawned.has(i) or elapsed < arrival.time:
			continue
		var surprise: bool = arrival.guest == "jiwoo"
		if not surprise and elapsed > arrival.time + 6:
			spawned[i] = true
			continue
		if surprise and visitors.any(func(v): return v.guest.id == "jiwoo"):
			continue
		if visitors.size() >= 2:
			continue
		var seat := 0
		for n in 7:
			var candidate := (int(arrival.seat) - 1 + n) % 7 + 1
			if at(candidate).is_empty() and not blocked(candidate):
				seat = candidate
				break
		if seat == 0:
			continue
		var v := {"id": i, "seat": seat, "blocked": 0, "guest": Config.guest(arrival.guest, arrival.time >= day.duration * 0.5),
			"state": State.ORDER, "patience": 25.0 * patience_multiplier, "timer": 0.0, "bubble": 2.5,
			"tip": 0, "delivered": 0, "tank_ready": false, "gecko_attempted": false, "gecko_wait": 0.0,
			"mimi_attempted": false, "mimi_away": 0.0, "mimi_warning_time": 0.0, "heat_limit": 0.0, "heat_remaining": 0.0}
		if v.guest.id == "snowy":
			v.heat_limit = 18.0 if assisted else 12.0
			v.heat_remaining = v.heat_limit
		if v.guest.id == "coco":
			var b: int = seat % 7 + 1
			if at(b).is_empty() and not blocked(b):
				v.blocked = b
		visitors.append(v)
		spawned[i] = true
		message = ("惊喜客人 · " if surprise else "") + v.guest.name + " 入座了！"
	for v in visitors.duplicate():
		v.bubble = maxf(0, v.bubble - dt)
		if needs_cooling(v):
			v.heat_remaining = maxf(0, v.heat_remaining - dt)
			if v.heat_remaining <= 0:
				miss(v)
				message = "Snowy：先撤了，再坐下去就得用杯子装我了。"
				continue
		if v.state in [State.ORDER, State.WAITING]:
			v.patience -= dt * (0.5 if direction == v.seat else 1.0) * (0.75 if assisted else 1.0)
			if v.patience <= 0:
				miss(v)
			else:
				update_gecko(v, dt)
				update_mimi(v, dt)
		else:
			v.timer -= dt
			if v.timer <= 0:
				if v.state == State.DRINKING:
					v.state = State.PAYMENT
					v.timer = (6.0 if v.guest.id == "bobo" else 12.0) * (1.5 if assisted else 1.0)
				else:
					miss(v)
	if ready.is_empty() and not queue.is_empty():
		queue[0].remaining -= dt * brew_speed
		if queue[0].remaining <= 0:
			ready = queue.pop_front()
			message = "饮品做好了，去出酒口取杯。"
	if elapsed >= day.duration:
		ended = true
		message = "今日目标达成！" if passed() else "今天差一点，重开再试一次。"

func update_gecko(v: Dictionary, dt: float) -> void:
	if v.guest.id != "gecko" or v.state != State.WAITING or v.gecko_attempted:
		return
	v.gecko_wait += dt
	if v.gecko_wait < 5:
		return
	v.gecko_attempted = true
	var previous: int = v.seat
	for n in range(1, 7):
		var next := (previous - 1 + n) % 7 + 1
		if not at(next).is_empty() or blocked(next):
			continue
		v.seat = next
		v.bubble = 2.5
		message = "Gecko：这边光线好。P%d → P%d，原订单继续！" % [previous, next]
		return
	message = "Gecko：没有空座？那先给这张桌子打五星。"

func update_mimi(v: Dictionary, dt: float) -> void:
	if v.guest.id != "mimi" or v.state != State.WAITING or v.mimi_attempted:
		return
	if not mimi_warning(v):
		if direction != v.seat:
			v.mimi_away += dt
		if mimi_warning(v):
			message = "Mimi 伸手了！面向她互动，打断偷钱。"
		return
	v.mimi_warning_time += dt
	if v.mimi_warning_time < (4.0 if assisted else 2.0):
		return
	v.mimi_attempted = true
	var taken := mini(5, maxi(0, coins))
	coins -= taken
	stolen_coins += taken
	message = "Mimi 顺走了 %d 金币！本次不会再偷。" % taken if taken > 0 else "Mimi：零钱盒比我的旅游预算还干净。"

func service_hint() -> Dictionary:
	if ended:
		return {"target": -1, "text": "今日营业结束。"}
	for v in visitors:
		if mimi_warning(v):
			return {"target": v.seat, "text": "Mimi 伸手了！去 P%d 互动打断，手中的饮品会保留。" % v.seat}
	for v in visitors:
		if needs_cooling(v) and v.heat_remaining <= 5 and hand.is_empty():
			if v.state == State.ORDER:
				return {"target": v.seat, "text": "Snowy快热化了！去 P%d 接单。" % v.seat}
			if not ready.is_empty() and ready.owner == v.id:
				return {"target": 0, "text": "去出酒口取杯，快给Snowy降温！"}
	var recipient := owner(hand)
	if not recipient.is_empty():
		return {"target": recipient.seat, "text": "③ 送达：去 P%d 再互动。" % recipient.seat}
	var payments: Array = visitors.filter(func(v): return v.state == State.PAYMENT)
	payments.sort_custom(func(a, b): return a.timer < b.timer)
	if not payments.is_empty():
		return {"target": payments[0].seat, "text": "④ 收钱：金币收取后才会入账！"}
	if not ready.is_empty():
		return {"target": 0, "text": "② 取杯：去下方出酒口互动。"}
	if not queue.is_empty():
		return {"target": -1, "text": "② 制作中：留意下方出酒口。"}
	var orders: Array = visitors.filter(func(v): return v.state == State.ORDER)
	orders.sort_custom(func(a, b): return a.patience < b.patience)
	if not orders.is_empty():
		return {"target": orders[0].seat, "text": "① 提醒Tank摘呼吸器，再正式接单。" if tank_attention(orders[0]) else "① 接单：点击客位转向，再次点击交谈。"}
	return {"target": -1, "text": "等客人喝完后收钱。" if not visitors.is_empty() else "客人正在路上。"}
