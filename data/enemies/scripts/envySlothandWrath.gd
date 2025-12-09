extends "res://data/enemies/EnemyData.gd"

@export var concept := true
@export var evil := true
@export var land := true
@export var weird := true

var is_dead: bool = false
var next_line: String = ""
var active_sin: String = ""

# Sloth tracking
var last_played_card: HandData = null
var played_same_twice: bool = false
var sloth_skip_chance: float = 0.3

# Wrath tracking
var wrath_consecutive_ties: int = 0
var wrath_dice_rolled: bool = false
var wrath_punish_mode: bool = false

var sins = ["Envy", "Sloth", "Wrath"]

# Envy dialogue
var envy_intro: Array[String] = [
	"'Why do *you* get to go first?'",
	"'Nice cards... I want them.'",
	"'We're not so different, are we?'"
]

var envy_battle: Array[String] = [
	"'That should be mine!'",
	"'I deserve that victory!'",
	"'Your cards match mine... how fitting.'",
	"'We are the same, you and I.'"
]

var envy_tie: Array[String] = [
	"'See? We ARE the same!'",
	"'I have what you have!'",
	"'Perfect mirror...'"
]

# Sloth dialogue
var sloth_intro: Array[String] = [
	"'Do we *really* have to fight?'",
	"'I'm already tired...'",
	"'Can't we just... not?'"
]

var sloth_battle: Array[String] = [
	"'Maybe later...'",
	"'Too much effort.'",
	"'Ugh, fine. I'll play.'"
]

var sloth_skip: Array[String] = [
	"'*yawn* ...I'm not playing this round.'",
	"'Nope. Too lazy.'",
	"'You win by default. I don't care.'"
]

var sloth_punish: Array[String] = [
	"'You're lazier than ME? Pathetic.'",
	"'Can't even think of a new move? I win.'",
	"'Repeating yourself? How... slothful. I win.'"
]

# Wrath dialogue
var wrath_intro: Array[String] = [
	"'You DARE challenge me?!'",
	"'I'll tear you apart!'",
	"'Prepare to suffer!'"
]

var wrath_battle: Array[String] = [
	"'You think you can beat me?!'",
	"'I'm not losing again!'",
	"'Feel my RAGE!'"
]

var wrath_tie_rage: Array[String] = [
	"'A TIE?! Unacceptable! Let fate decide!'",
	"'No draws! I'll roll the dice of fury!'",
	"'Ties mean NOTHING! *rolls dice*'"
]

var wrath_punish_win: Array[String] = [
	"'You won... but now the stakes are DOUBLED!'",
	"'Victory? Fine! But lose next and pay TWICE!'",
	"'You got lucky! Next round: double or nothing!'"
]

var wrath_punish_lose: Array[String] = [
	"'You LOSE! Feel DOUBLE the pain!'",
	"'My rage takes TWO lives from you!'",
	"'SUFFER TWICE for your failure!'"
]

var death_lines: Array[String] = [
	"'Fine. Whatever.'",
	"'I'll get you next time...'",
	"'My anger fades... for now.'",
	"'At least... you tried...'"
]

func on_combat_start(players_cards: Array[HandData]) -> void:
	is_dead = false
	next_line = ""
	active_sin = sins.pick_random()
	last_played_card = null
	played_same_twice = false
	sloth_skip_chance = 0.3
	wrath_consecutive_ties = 0
	wrath_dice_rolled = false
	wrath_punish_mode = false

	# Announce which sin you're fighting
	match active_sin:
		"Envy":
			emit_signal("feedback", "You face ENVY!\n" + envy_intro.pick_random())
		"Sloth":
			emit_signal("feedback", "You face SLOTH!\n" + sloth_intro.pick_random())
		"Wrath":
			emit_signal("feedback", "You face WRATH!\n" + wrath_intro.pick_random())
	
	print("[EnvySlothWrath] Active sin: ", active_sin)

func react_to_card(card: HandData) -> void:
	if is_dead or card == null:
		return
	
	# Store battle line for later
	match active_sin:
		"Envy":
			next_line = envy_battle.pick_random()
		"Sloth":
			# Check if player played same card twice
			if last_played_card != null and last_played_card.name == card.name:
				played_same_twice = true
				next_line = sloth_punish.pick_random()
			else:
				next_line = sloth_battle.pick_random()
			last_played_card = card
		"Wrath":
			next_line = wrath_battle.pick_random()

func modify_result(card: HandData, enemy_card: HandData, result: int) -> int:
	if is_dead or card == null:
		return result
	
	match active_sin:
		"Envy":
			# Envy: If tags match, force tie
			if _share_tags(card, enemy_card):
				next_line = envy_tie.pick_random()
				return 0
		
		"Sloth":
			# Sloth: Random skip (player auto-wins but gets nothing special)
			if randf() < sloth_skip_chance:
				next_line = sloth_skip.pick_random()
				# Note: No gold reward handled elsewhere
				return 1
			
			# Sloth: If player played same card twice, sloth auto-wins
			if played_same_twice:
				played_same_twice = false
				return -1
		
		"Wrath":
			# Wrath: Handle ties
			if result == 0:
				wrath_consecutive_ties += 1
				if wrath_consecutive_ties >= 2:
					# Roll dice
					next_line = wrath_tie_rage.pick_random()
					var dice = randi() % 2  # 0 or 1
					wrath_consecutive_ties = 0
					if dice == 0:
						wrath_punish_mode = true
						return -1  # Wrath wins dice, player loses
					else:
						wrath_punish_mode = true
						return 1  # Player wins dice
			else:
				wrath_consecutive_ties = 0
			
			# Wrath punish mode: double damage
			if wrath_punish_mode:
				wrath_punish_mode = false
				if result == 1:
					# Player wins: they take life from wrath normally
					next_line = wrath_punish_win.pick_random()
					# Next round still matters
				elif result == -1:
					# Player loses: they lose TWO lives (handled in battle_ui via signal)
					next_line = wrath_punish_lose.pick_random()
					# TODO: Need to signal battle_ui to do double damage
	
	return result

func emit_round_line() -> void:
	pass  # Handled by on_damage_taken/on_round_end

func on_damage_taken(current_hp: int) -> void:
	if is_dead:
		return
	
	if current_hp <= 0:
		is_dead = true
		next_line = ""
		emit_signal("feedback", death_lines.pick_random())
		return
	
	# Enemy survived - emit stored battle line
	_emit_stored_line()

func on_round_end() -> void:
	if not is_dead and next_line != "":
		_emit_stored_line()

func _emit_stored_line() -> void:
	if next_line != "":
		emit_signal("feedback", next_line)
	next_line = ""

# Helper to detect shared tags for Envy
func _share_tags(a: HandData, b: HandData) -> bool:
	var tags = [
		"living", "aquatic", "dry", "holy", "concept", "evil", "plant", "elemental",
		"metalic", "airborne", "land", "weird", "wood", "electric", "equal", "human"
	]
	for tag in tags:
		if a.get(tag) and b.get(tag):
			return true
	return false
