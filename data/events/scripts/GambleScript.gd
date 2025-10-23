extends CustomEventScript

## Example: Gamble event - risk gold for a chance to win more

func execute(context: Dictionary) -> Dictionary:
	var globals = context.get("globals")
	var option_data = context.get("option_data")
	
	# Get bet amount from custom_data
	var bet_amount = option_data.custom_data.get("bet_amount", 50)
	
	# Check if player has enough gold
	if globals.funds < bet_amount:
		return {
			"success": false,
			"message": "You don't have enough gold to bet!"
		}
	
	# Take the bet
	globals.funds -= bet_amount
	
	# 50/50 chance
	if randf() > 0.5:
		# Win! Triple the bet
		var winnings = bet_amount * 3
		globals.funds += winnings
		return {
			"success": true,
			"message": "You won! You gain %d gold!" % winnings,
			"gold_gained": winnings - bet_amount
		}
	else:
		# Lose
		return {
			"success": false,
			"message": "You lost the bet. %d gold gone." % bet_amount,
			"gold_lost": bet_amount
		}

func can_execute(context: Dictionary) -> bool:
	var globals = context.get("globals")
	var option_data = context.get("option_data")
	var bet_amount = option_data.custom_data.get("bet_amount", 50)
	return globals.funds >= bet_amount

func get_tooltip(context: Dictionary) -> String:
	var option_data = context.get("option_data")
	var bet_amount = option_data.custom_data.get("bet_amount", 50)
	return "Requires %d gold. 50%% chance to triple your bet!" % bet_amount
