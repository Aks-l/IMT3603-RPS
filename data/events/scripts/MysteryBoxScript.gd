extends CustomEventScript

## Example: Mystery Box - Random reward (item or hand card)

func execute(context: Dictionary) -> Dictionary:
	var globals = context.get("globals")
	
	# Randomly choose between item and hand
	var roll = randf()
	
	if roll < 0.5 and not ItemDatabase.items.is_empty():
		# Give random item
		var items = ItemDatabase.items.values()
		var random_item = items[randi() % items.size()]
		globals.consumables.append(random_item)
		
		return {
			"success": true,
			"message": "You found a %s!" % random_item.name,
			"reward_type": "item",
			"reward": random_item
		}
	else:
		# Give random hand card
		var hands = HandDatabase.hands.values()
		# Filter out placeholder
		var valid_hands = hands.filter(func(h): return h.id != 9999)
		
		if valid_hands.is_empty():
			return {"success": false, "message": "Nothing inside..."}
		
		var random_hand = valid_hands[randi() % valid_hands.size()]
		
		if globals.inventory.has(random_hand):
			globals.inventory[random_hand] += 1
		else:
			globals.inventory[random_hand] = 1
		
		return {
			"success": true,
			"message": "You found a %s card!" % random_hand.name.capitalize(),
			"reward_type": "hand",
			"reward": random_hand
		}

func can_execute(context: Dictionary) -> bool:
	# Always available
	return true

func get_tooltip(context: Dictionary) -> String:
	return "Open the mystery box to receive a random reward!"
