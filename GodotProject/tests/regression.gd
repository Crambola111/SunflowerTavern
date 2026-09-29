extends SceneTree
const Model = preload("res://scripts/tavern_model.gd")
const Config = preload("res://scripts/day_config.gd")
const Progress = preload("res://scripts/progress_store.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func isolated(id: String, assisted := false, arrival := 1.0) -> RefCounted:
	var m := Model.new({"duration":60,"target":10,"guests":[id],"arrivals":[{"time":arrival,"guest":id,"seat":2}]},assisted)
	m.started = true
	m.update(arrival+0.1)
	m.direction = 2
	return m

func play(m: RefCounted) -> void:
	for n in 2500:
		for v in m.visitors.duplicate():
			if v.state == Model.State.ORDER or m.mimi_warning(v):
				m.direction = v.seat
				m.interact()
		for seat in m.bills.keys():
			m.direction = seat
			m.interact()
		if m.hand.is_empty() and not m.ready.is_empty():
			m.direction = 0
			m.interact()
		if not m.hand.is_empty():
			var matches: Array = m.visitors.filter(func(v): return m.accepts(v, m.hand))
			var v: Dictionary = matches[0] if not matches.is_empty() else {}
			if not v.is_empty():
				m.direction = v.seat
				m.interact()
		m.update(0.05)
		if m.ended:
			return

func _initialize() -> void:
	for assisted in [false,true]:
		for day in range(1,4):
			var m := Model.new(Config.for_day(day),assisted)
			m.started = true
			play(m)
			check(m.ended and m.passed(),"Day %d ends and passes (%s)" % [day,assisted])
			check(m.served == [5,7,9][day-1] and m.coins == [79,124,190][day-1],"Day %d parity: served=%d coins=%d" % [day,m.served,m.coins])
			check(m.codex.size() == [3,5,7][day-1] and m.missed == 0 and m.stolen_coins == 0,"Perfect play codex / misses / theft")
			check(m.claim_settlement() == m.coins and m.claim_settlement() == -1,"One payout only")
			var end_time: float = m.elapsed
			m.update(10)
			check(m.elapsed == end_time,"Ended clock frozen")
	check(Config.available_guests().size() == 7 and not Config.playable(4),"Do not unlock unimplemented Day4")
	var m := isolated("tank")
	m.interact()
	check(m.queue.is_empty() and m.at(2).tank_ready,"Tank first interaction only removes mask")
	m.interact()
	m.interact()
	check(m.queue.size() == 1,"Tank accepts once")
	var before: float = m.elapsed
	m.paused = true
	m.update(10)
	check(m.elapsed == before and m.queue[0].remaining == 5,"Pause freezes brewing")
	m = isolated("coco")
	check(m.blocked(3),"Coco occupies adjacent seat")
	m.update(55)
	check(not m.blocked(3) and m.missed == 1,"Leaving frees luggage and counts once")
	m = isolated("horn")
	m.update(3)
	check(m.at(2).bubble == 0,"Horn bubble expires")
	m.interact()
	check(m.at(2).bubble == 2.5,"Question restores bubble")
	m = isolated("gecko")
	m.interact()
	m.update(5.1)
	check(m.at(2).is_empty() and m.at(3).guest.id == "gecko","Gecko moves after five seconds")
	m.direction = 0
	m.interact()
	check(m.accepts(m.at(3), m.hand),"Drink type accepted after seat change")
	m.direction = 3
	m.interact()
	check(m.at(3).state == Model.State.DRINKING,"Delivery to moved customer")
	for assisted in [false,true]:
		m = isolated("mimi",assisted)
		m.coins = 3
		m.interact()
		m.direction = 0
		m.update(3.1)
		check(m.mimi_warning(m.at(2)),"Mimi warns after facing away")
		m.update(1.8)
		check(m.coins == 3,"Warning gives reaction window")
		m.update(2.3 if assisted else 0.3)
		check(m.coins == 0 and m.stolen_coins == 3,"Theft capped at balance")
		m.coins = 10
		m.update(5)
		check(m.coins == 10,"One theft per visit")
	m = isolated("mimi")
	m.interact()
	m.direction = 0
	m.update(3.2)
	m.interact()
	var cup: Dictionary = m.hand
	m.direction = 2
	m.interact()
	check(m.at(2).mimi_attempted and m.hand == cup and m.at(2).delivered == 0,"Interrupt preserves held cup")
	m.interact()
	check(m.at(2).state == Model.State.DRINKING,"Second interaction delivers")
	m = isolated("spf8")
	m.interact()
	m.interact()
	check(m.queue.size() == 2,"SPF creates exactly two cups")
	for n in 2:
		m.update(5.1)
		m.direction = 0
		m.interact()
		m.direction = 2
		m.interact()
		check(m.at(2).delivered == n+1,"SPF cup count")
		if n == 0:
			check(m.at(2).state == Model.State.WAITING and m.coins == 0,"Partial order not paid")
	m.update(2.1)
	m.interact()
	check(m.served == 1 and m.coins == 31 and m.codex.has("spf8"),"Two cups settle once")
	# Wrong drink consumes patience, not the cup; departures preserve finished drinks.
	m = Model.new({"duration":60,"target":10,"guests":["bobo","spf8"],"arrivals":[{"time":1,"guest":"bobo","seat":2},{"time":1,"guest":"spf8","seat":4}]})
	m.started = true
	m.update(1.1)
	m.direction = 4
	m.interact()
	m.update(5.1)
	m.direction = 0
	m.interact()
	m.direction = 2
	m.interact()
	var patience: float = m.at(2).patience
	m.interact()
	check(m.at(2).patience == patience-2 and not m.hand.is_empty(),"Wrong cup retained, patience -2")
	m.at(4).patience = 0.01
	m.update(0.05)
	check(not m.hand.is_empty() and not m.queue.any(func(c):return c.drink=="椰子水" and not c.started),"Miss preserves hand and cancels unstarted surplus")
	for assisted in [false,true]:
		m = isolated("snowy",assisted)
		var heat: float = m.at(2).heat_remaining
		check(absf(heat-(17.85 if assisted else 11.85)) < 0.1,"Snowy heat duration")
		m.paused = true
		m.update(5)
		check(m.at(2).heat_remaining == heat,"Pause freezes heat")
		m.paused = false
		m.interact()
		check(m.at(2).heat_remaining == heat,"Accepting does not reset heat")
		m.update(heat+0.1)
		check(m.visitors.is_empty() and m.queue.is_empty() and not m.ready.is_empty() and m.missed==1,"Snowy timeout preserves completed cup")
	m = isolated("snowy")
	m.interact()
	m.update(3.1)
	m.direction = 0
	m.interact()
	m.direction = 2
	m.interact()
	m.update(2.1)
	m.interact()
	check(m.coins == 13 and m.served == 1,"Snowy delivery and payment")
	for arrival in [5.0,30.0]:
		m = isolated("jiwoo",false,arrival)
		check(m.at(2).guest.drink == ("冰美式" if arrival==5 else "夜间无酒精特调"),"Jiwoo scheduled time chooses drink")
		m.interact()
		m.update(4.1)
		m.direction=0
		m.interact()
		m.direction=2
		m.interact()
		check(not m.codex.has("jiwoo"),"Jiwoo not unlocked before payment")
		m.update(2.1)
		m.interact()
		check(m.coins == (15 if arrival==5 else 19) and m.codex.has("jiwoo"),"Jiwoo paid and unlocked")
	m = Model.new({"duration":60,"target":10,"guests":["bobo","coco","jiwoo","horn"],"arrivals":[{"time":1,"guest":"bobo","seat":2},{"time":1,"guest":"coco","seat":4},{"time":20,"guest":"jiwoo","seat":6},{"time":35,"guest":"horn","seat":1}]})
	m.started=true
	m.update(1.1)
	for v in m.visitors:
		v.patience=100.0
	m.update(34)
	check(m.visitors.size()==2,"Full table postpones surprise guest")
	m.remove_visit(m.visitors[0])
	m.update(0.1)
	check(m.visitors.any(func(v):return v.guest.id=="jiwoo" and v.guest.drink=="冰美式"),"Reservation survives six seconds, priority and scheduled variant")
	check(m.visitors.filter(func(v):return v.guest.id=="jiwoo").size()==1,"No duplicate surprise guest")
	check_bills()
	check_shared_cups()
	check_progress()
	print("Godot regression: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func check_progress() -> void:
	var path := "user://migration_regression_only.json"
	DirAccess.remove_absolute(path)
	var p := Progress.new(path)
	check(p.can_enter(1) and not p.can_enter(2),"Initial progression")
	check(p.complete_day(1,79,70,0.25,false),"Save Day1")
	check(p.can_enter(2) and p.data.wallet==79,"Unlock Day2 and credit")
	check(p.purchase(0) and not p.purchase(0) and p.data.wallet==49,"Purchase charged once")
	check(not p.purchase(2) and not p.purchase(-1),"Invalid / unaffordable purchases")
	p.unlock("bobo")
	p.complete_tutorial()
	p.complete_day(2,60,90,0.25,false)
	check(not p.can_enter(3),"Failed day does not unlock")
	p.complete_day(2,124,90,0.5,true)
	check(p.can_enter(3) and p.data.best[1]==[60,124],"Separate mode records")
	p.complete_day(3,190,140,0.75,false)
	check(not p.can_enter(4),"Day4 remains pending")
	var reload := Progress.new(path)
	check(reload.error.is_empty() and reload.data.wallet==423 and reload.data.tip_remainder==0.75 and reload.owns(0) and reload.data.codex.has("bobo") and reload.data.tutorial_done,"Reload persists wallet, fraction, decor, codex, tutorial")
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string('{"version":999}')
	file.close()
	var future := Progress.new(path)
	check(not future.error.is_empty() and not future.save() and FileAccess.get_file_as_string(path)=='{"version":999}',"Future or corrupt save preserved")
	DirAccess.remove_absolute(path)

func pair(first: String, second: String) -> RefCounted:
	var m := Model.new({"duration":60,"target":10,"guests":[first,second],"arrivals":[{"time":1,"guest":first,"seat":2},{"time":1,"guest":second,"seat":5}]})
	m.started = true
	m.update(1.1)
	return m

func check_shared_cups() -> void:
	var m := pair("bobo", "snowy")
	m.direction = 2
	m.interact()
	m.update(3.1)
	m.direction = 0
	m.interact()
	check(not m.hand.has("owner"), "Finished cup contains no visitor ownership")
	check(not m.accepts(m.at(5), m.hand), "Unordered same-drink visitor cannot receive")
	m.direction = 5
	m.interact()
	check(m.queue.size() == 1, "Two same-drink orders minus held supply require exactly one new job")
	m.interact()
	check(m.at(5).state == Model.State.DRINKING and m.at(2).state == Model.State.WAITING, "Bobo's first produced drink serves Snowy")
	check(m.queue.size() == 1, "Remaining Bobo demand retains exactly one queued cup")
	m.update(2.1)
	m.interact()
	check(m.codex.has("snowy") and not m.codex.has("bobo") and m.coins == 13, "Actual recipient receives codex and payout")
	m.remove_visit(m.at(2))
	check(m.queue.size() == 1 and m.queue[0].started, "Already started drink survives cancelled demand")
	m.update(1.1)
	check(not m.ready.is_empty() and m.queue.is_empty(), "Orphan in-progress drink finishes")
	m.paused = true
	m.discard_cup(false)
	check(not m.ready.is_empty(), "Paused discard is ignored")
	m.paused = false
	m.discard_cup(false)
	check(m.ready.is_empty() and m.queue.is_empty(), "Discard orphan does not brew without demand")
	m = pair("coco", "spf8")
	m.direction = 2
	m.interact()
	m.update(5.1)
	m.direction = 5
	m.interact()
	check(m.queue.size() == 2, "Three coconut demands minus one ready yields two jobs")
	m.remove_visit(m.at(2))
	check(not m.ready.is_empty() and m.queue.size() == 1, "Departure retains ready and trims last unstarted surplus")
	for n in 2:
		m.direction = 0
		m.interact()
		m.direction = 5
		m.interact()
		if n == 0:
			check(m.at(5).delivered == 1 and m.coins == 0 and not m.codex.has("spf8"), "SPF accepts shared first cup without payout")
			m.update(5.1)
	check(m.at(5).state == Model.State.DRINKING and m.queue.is_empty(), "SPF accepts two generic cups with no duplicate jobs")
	m = isolated("horn")
	m.interact()
	m.update(4.1)
	m.direction = 0
	m.interact()
	check(m.service_hint().target == -1, "Held cup does not reveal hidden Horn seat")
	m.discard_cup(true)
	check(m.hand.is_empty() and m.queue.size() == 1, "Discard demanded cup replaces exactly one job")
	m.reconcile_queue()
	check(m.queue.size() == 1, "Repeated reconciliation cannot duplicate jobs")
	m.update(4.1)
	m.remove_visit(m.visitors[0])
	check(not m.ready.is_empty(), "Completed cup survives departure")
	m.update(60)
	check(m.ready.is_empty() and m.hand.is_empty() and m.queue.is_empty(), "Closing clears all transient drink supply")
	m = isolated("spf8")
	m.interact()
	m.hand = {"drink":"椰子水"}
	m.ready = {"drink":"椰子水"}
	m.reconcile_queue()
	check(m.queue.is_empty(), "Two existing cups cover SPF demand")
	m.discard_cup(false)
	check(not m.hand.is_empty() and m.ready.is_empty() and m.queue.size() == 1, "Discard outlet does not delete held cup")

func finish_drink(m: RefCounted, seat: int) -> void:
	m.direction = seat
	m.interact()
	var cups: int = m.at(seat).guest.cups
	for n in cups:
		m.hand = {"drink":m.at(seat).guest.drink}
		m.reconcile_queue()
		m.interact()
	m.update(2.1)

func check_bills() -> void:
	for assisted in [false,true]:
		var m := isolated("bobo", assisted)
		finish_drink(m,2)
		check(m.visitors.is_empty() and m.bills.has(2) and not m.seat_free(2), "Departed guest leaves occupied bill table")
		check(m.bills[2].guest_id == "bobo" and m.bills[2].cups == 1 and not m.bills[2].has("timer"), "Bill preserves recipient and used cups without timer")
		m.update(20)
		check(m.bills.has(2) and m.missed == 0 and m.coins == 0, "Bill survives old timeout in both modes")
		m.hand = {"drink":"椰子水"}
		m.ready = {"drink":"青柠苏打"}
		m.paused = true
		m.collect_bill(2)
		check(m.bills.has(2), "Paused collection ignored")
		m.paused = false
		m.direction = 2
		m.interact()
		check(m.coins == 13 and m.served == 1 and m.codex.has("bobo") and m.seat_free(2), "Collection pays and clears table once")
		check(m.hand.drink == "椰子水" and m.ready.drink == "青柠苏打", "Cleaning never deletes unserved supply")
		m.collect_bill(2)
		m.interact()
		check(m.coins == 13 and m.combo == 1, "Repeat collection cannot duplicate payout")
	var m := isolated("coco")
	finish_drink(m,2)
	check(not m.blocked(3) and m.seat_free(3) and not m.seat_free(2), "Coco luggage leaves while own bill remains")
	m = isolated("spf8")
	finish_drink(m,2)
	check(m.bills[2].cups == 2 and m.coins == 0, "SPF two used cups share one unpaid bill")
	m.interact()
	check(m.served == 1 and m.coins == 31, "SPF bill pays once for full order")
	m = isolated("spf8")
	m.interact()
	m.hand = {"drink":"椰子水"}
	m.reconcile_queue()
	m.interact()
	m.at(2).patience = 0.001
	m.update(0.05)
	check(m.bills.is_empty() and m.seat_free(2) and m.coins == 0 and not m.codex.has("spf8"), "Partial timeout cleans without bill or reward")
	m = isolated("bobo")
	finish_drink(m,2)
	m.update(60)
	check(m.bills.is_empty() and m.claim_settlement() == 0 and not m.codex.has("bobo"), "Closing discards unpaid bill without auto payment")
	m = Model.new({"duration":60,"target":10,"guests":["bobo","coco","gecko"],"arrivals":[{"time":1,"guest":"bobo","seat":2},{"time":5,"guest":"coco","seat":1},{"time":6,"guest":"gecko","seat":2}]})
	m.started = true
	m.update(1.1)
	finish_drink(m,2)
	m.update(3)
	check(m.visitors.size() == 2 and m.bills.has(2), "Bill does not count against two live guests")
	check(m.at(1).guest.id == "coco" and not m.blocked(2) and m.at(3).guest.id == "gecko", "Arrival and luggage avoid unpaid table")
	m.direction = 3
	m.interact()
	m.at(3).seat = 7
	m.update(5.1)
	check(m.at(3).guest.id == "gecko" and m.bills.has(2), "Gecko skips visitor and unpaid bill when changing seats")
