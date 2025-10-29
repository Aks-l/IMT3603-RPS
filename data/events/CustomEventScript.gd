extends RefCounted
class_name CustomEventScript

## Base class for custom event option scripts
## Override the execute() method to implement custom event logic

## Called when the option is chosen
## @param context: Dictionary containing game state and references
##   - "player_health": Reference to player health component
##   - "globals": Reference to Globals autoload
##   - "encounter_handler": Reference to EncounterHandler
##   - "event_ui": Reference to the event UI displaying this event
##   - "option_data": The EventOptionData that triggered this
## @return: Dictionary with results/feedback to display
func execute(context: Dictionary) -> Dictionary:
	push_warning("CustomEventScript.execute() not overridden!")
	return {
		"success": false,
		"message": "This event has no custom logic implemented."
	}

## Optional: Check if this option should be available
## @param context: Same as execute()
## @return: bool - true if option should be shown/enabled
func can_execute(context: Dictionary) -> bool:
	return true

## Optional: Get dynamic tooltip/description based on game state
## @param context: Same as execute()
## @return: String - additional info to show player
func get_tooltip(context: Dictionary) -> String:
	return ""
