extends Resource
class_name EventOptionData

##Represents a single option/choice in an event

@export var option_text: String  ##The text displayed on the button/choice
@export_multiline var outcome_description: String  ##What happens when this option is chosen

## Outcome effects
@export_group("Rewards")
@export var gold_reward: int = 0
@export var health_change: int = 0  ##Positive for heal, negative for damage
@export var items_received: Array[ItemData] = []
@export var hands_received: Array[HandData] = []

@export_group("Consequences")
@export var removes_items: Array[ItemData] = []  ##Items to remove from inventory
@export var gold_cost: int = 0  ##Gold required/lost

## Optional: Lead to another event or encounter
@export var next_event_id: int = -1  ##-1 means no follow-up event
@export var triggers_combat: bool = false  ##If true, starts a combat encounter
@export var combat_enemy: EnemyData = null  ##Enemy to fight if triggers_combat is true

@export_group("Advanced/Custom")
@export var custom_script: Script = null  ##Custom script with execute() method for complex logic
@export_multiline var custom_code: String = ""  ##GDScript code to execute (alternative to custom_script)
@export var custom_data: Dictionary = {}  ##Key-value pairs for custom logic use
