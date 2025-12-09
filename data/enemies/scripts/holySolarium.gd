extends "res://data/enemies/EnemyData.gd"

@export var holy := true
@export var concept := true
@export var land := true

var is_dead: bool = false
var next_line: String = ""

var battle_lines: Array[String] = [
	"'Fear my light!'",
	"'Your shadow cannot hide from truth.'",
	"'Have you seen my scissors, actually?'",
	"'I am but a moment. An eternal one!'"
]

var death_lines: Array[String] = [
	"'You cannot keep the light in this world...'",
	"'Can I come back like you?'",
	"'I shouldn't have underestimated you...'"
]

func on_combat_start(players_cards: Array[HandData]) -> void:
	is_dead = false
	next_line = ""

func react_to_card(card: HandData) -> void:
	if is_dead or card == null:
		return

	# Store a random battle line for this turn
	next_line = battle_lines.pick_random()

	# Block evil and holy cards
	if card.evil:
		emit_signal("feedback", "'I reject your " + card.name + "' — evil cannot act under sacred light.")
		# Turn card white
		card.status_revealed = true
		card.status_tint = Color.WHITE
		emit_signal("update_hand_visual", card)
		return
	
	if card.holy:
		emit_signal("feedback", "'I reject your " + card.name + "' — only I am truly holy here.")
		# Turn card white
		card.status_revealed = true
		card.status_tint = Color.WHITE
		emit_signal("update_hand_visual", card)
		return

	# Block the Sun card (check by name)
	if _is_sun_card(card):
		emit_signal("feedback", "I reject imitation. Your fake Sun cannot act here.")
		# Turn card white
		card.status_revealed = true
		card.status_tint = Color.WHITE
		emit_signal("update_hand_visual", card)
		return

func modify_result(card: HandData, enemy_card: HandData, result: int) -> int:
	if is_dead or card == null:
		return result

	if card.evil or card.holy or _is_sun_card(card):
		return -1  # Auto-lose if forbidden
	return result

func emit_round_line() -> void:
	# Don't emit battle lines here - they're handled by on_damage_taken/on_round_end
	pass

func on_damage_taken(current_hp: int) -> void:
	if is_dead:
		return
	
	if current_hp <= 0:
		is_dead = true
		next_line = ""  # Clear battle line so only death line shows
		emit_signal("feedback", death_lines.pick_random())
		return
	
	# Enemy survived - emit the stored battle line
	_emit_stored_line()

func on_round_end() -> void:
	# Called at the end of every round (even ties and player losses)
	# Emit battle line if enemy is still alive
	if not is_dead and next_line != "":
		_emit_stored_line()

func _emit_stored_line() -> void:
	if next_line != "":
		emit_signal("feedback", next_line)
	next_line = ""

# --- Helpers ---
func _is_sun_card(card: HandData) -> bool:
	# Some decks duplicate cards, losing their original resource path.
	# The safest way is to check the name field only.
	return card.name.strip_edges().to_lower() == "the sun"
