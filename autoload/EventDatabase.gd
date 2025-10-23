extends Node

##Singleton that loads and provides access to all event data
##Loads all EventData resources from data/events/events/ subdirectories

var events: Dictionary = {}

##Load all events from data/events/events/ subdirectories
func load_events():
	var events_dir = DirAccess.open("res://data/events/events")
	if not events_dir:
		push_error("[EventDatabase] Failed to open events directory")
		return

	#Iterate through /events/events/ subdirectories
	events_dir.list_dir_begin()
	var folder_name = events_dir.get_next()
	
	while folder_name != "":
		if events_dir.current_is_dir() and not folder_name.begins_with("."):
			#Look for event.tres in this folder
			var event_path = "res://data/events/events/" + folder_name + "/event.tres"
			if ResourceLoader.exists(event_path):
				var event = load(event_path)
				if event and event is EventData:
					events[event.id] = event
					print("[EventDatabase] Loaded event: ", event.event_name, " (ID: ", event.id, ")")
				else:
					push_warning("[EventDatabase] Failed to load event from: ", event_path)
		
		folder_name = events_dir.get_next()
	
	events_dir.list_dir_end()

func _ready():
	load_events()
	print("[EventDatabase] Total events loaded: ", events.size())

##Get event by ID
func get_event(event_id: int) -> EventData:
	if events.has(event_id):
		return events[event_id]
	else:
		push_warning("[EventDatabase] Event with ID %d not found" % event_id)
		return null

##Get random event with optional requirements checking
func get_random_event(check_requirements: bool = true) -> EventData:
	if events.is_empty():
		push_warning("[EventDatabase] No events available")
		return null
	
	var available_events: Array[EventData] = []
	
	for event in events.values():
		if not check_requirements:
			available_events.append(event)
		else:
			#Check requirements
			if event.min_gold <= Globals.funds:
				var has_required_items = true
				for required_item in event.required_items:
					if not Globals.consumables.has(required_item):
						has_required_items = false
						break
				
				if has_required_items:
					available_events.append(event)
	
	if available_events.is_empty():
		push_warning("[EventDatabase] No available events match requirements")
		return null
	
	#Only events with weight > 0 are eligible for random selection
	var weighted_events = available_events.filter(func(e): return e.weight > 0.0)
	
	#If no weighted events, return null, !this should never happen!
	if weighted_events.is_empty():
		push_warning("[EventDatabase] No weighted events available (all are chain-only)")
		return null
	
	#Weighted random selection
	var total_weight = 0.0
	for event in weighted_events:
		total_weight += event.weight
	
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for event in weighted_events:
		current_weight += event.weight
		if random_value <= current_weight:
			return event
	
	#Return first event if nothing else was selected
	return weighted_events[0]
