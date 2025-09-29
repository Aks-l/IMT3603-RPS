extends Resource
class_name DeckBuilder

#builds a deck from a list of handdata resources
func build_deck(hands: Array[HandData], total_max: = 15) -> Array[HandData]:
	var deck: Array[HandData] = []
	#var total := 0
	
	#add up to max_count copies of each hand
	for h in hands:
		for i in range(h.max_count):
			deck.append(h)
	
	#enforce total deck limits
	if deck.size() > total_max:
		deck = deck.slice(0, total_max)
	
	return deck
