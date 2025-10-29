extends Resource
class_name EventData

##Represents a random event encounter in the game

@export var id: int
@export var event_name: String  ##Internal name for the event
@export var image: Texture2D  ##The image displayed with the event
@export_multiline var description: String  ##The main event description/story text

## Event options/choices
@export var options: Array[EventOptionData] = []

##Optional: Requirements to see this event
@export_group("Requirements")
@export var min_gold: int = 0  ##Minimum gold required to encounter this event
@export var required_items: Array[ItemData] = []  ##Items that must be in inventory
@export var weight: float = 1.0  ##Probability weight for random selection (higher = more common)
