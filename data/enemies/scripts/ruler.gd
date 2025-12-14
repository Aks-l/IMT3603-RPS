extends "res://data/enemies/EnemyData.gd"

@export var concept := true
@export var weird := true
@export var land := true

var is_dead: bool = false
var next_line: String = ""
var turn_count: int = 0

var battle_lines: Array[String] = [
	"'No picture, no proof.'",
	"'I don’t argue — I demonstrate.'",
	"'Words are invisible things.'",
	"'Show me, or you do not exist.'",
	"'Will you allow me to take a picture of you?'",
	"'Everything is explainable... with a picture.'"
]

var death_lines: Array[String] = [
	"'This shouldn't be possible!'",
	"'Evidence... deleted.'",
	"'I must remain...'",
	"'You cannot capture what never was.'"
]

func on_combat_start(players_cards: Array[HandData]) -> void:
	is_dead = false
	next_line = ""
	turn_count = 0

func react_to_card(card: HandData) -> void:
	if is_dead or card == null:
		return

	turn_count += 1
	
	# Store a random battle line for this turn
	next_line = battle_lines.pick_random()

	if _is_unphotographable(card):
		emit_signal("feedback", "'Rule 32: " + card.name + " is too unspecific.'")
		return

func modify_result(card: HandData, enemy_card: HandData, result: int) -> int:
	if is_dead or card == null:
		return result

	if _is_unphotographable(card):
		return -1  # Auto-lose if card cannot be pictured

	return result

func emit_round_line() -> void:
	# Don't emit battle lines here - handled by on_damage_taken/on_round_end
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
	# Called at the end of every round
	# Emit battle line if enemy is still alive
	if not is_dead and next_line != "":
		_emit_stored_line()

func _emit_stored_line() -> void:
	if next_line != "":
		emit_signal("feedback", next_line)
	next_line = ""

# --- Helpers ---
func _is_unphotographable(card: HandData) -> bool:
	# Any card that is elemental, conceptual, holy, or evil is invalid
	if card.elemental or card.concept or card.holy or card.evil:
		return true
	return false
