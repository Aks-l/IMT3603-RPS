extends "res://data/enemies/EnemyData.gd"

var phase := 1
var used_ids: Array[int] = []

func on_combat_start(inv: Array[HandData]) -> void:
	phase = 1
	used_ids.clear()
	print("Six enters the arena.")

func on_damage_taken(hp: int) -> void:
	if hp == 2 and phase != 2:
		phase = 2
		emit_signal("feedback", "Seven pushes Six aside and takes over!")
		print("Phase change → Phase 2: Seven")

	elif hp == 1 and phase != 3:
		phase = 3
		emit_signal("feedback", "Six and Seven fuse into a chaotic entity!")
		print("Phase change → Phase 3: Fusion")

func react_to_card(card: HandData) -> void:
	match phase:
		1: _six_react(card)
		2: _seven_react(card)
		3: _fusion_react(card)

func modify_result(player: HandData, enemy: HandData, result: int) -> int:
	match phase:
		1: return result
		2: return _seven_modify(player, result)
		3: return _fusion_modify(result)
	return result

# -------------------------
# PHASE 1: SIX (no gimmicks)
# -------------------------
func _six_react(card: HandData) -> void:
	emit_signal("feedback", "%s stands firm before Six." % card.name)

# -------------------------
# PHASE 2: SEVEN (punish repeats)
# -------------------------
func _seven_react(card: HandData) -> void:
	if card.id in used_ids:
		emit_signal("feedback", "Seven punishes repetition!")
	else:
		emit_signal("feedback", "Seven observes your move...")

	if card.id not in used_ids:
		used_ids.append(card.id)

func _seven_modify(card: HandData, result: int) -> int:
	if card.id in used_ids and result == 1:
		print("Seven converts win into loss:", card.name)
		return -1
	return result

# -------------------------
# PHASE 3: FUSION (chaos)
# -------------------------
func _fusion_react(card: HandData) -> void:
	emit_signal("feedback", "Chaos swirls around %s!" % card.name)

func _fusion_modify(result: int) -> int:
	return [1, 0, -1].pick_random()
