extends Node

var inventory: Array[HandData] = []

func _ready() -> void:
	inventory.clear()

# TODO: CURENTLY ADDS ONE OF ALL POSSIBLE CARD TO INVENTORY, CHANGE LATER

	var dir_path := "res://data/cards"
	if DirAccess.dir_exists_absolute(dir_path):
		var dir := DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name := dir.get_next()
			while file_name != "":
				if !dir.current_is_dir() and file_name.ends_with(".tres"):
					var full_path := dir_path + "/" + file_name
					var res := load(full_path)
					if res is HandData:
						inventory.append(res)
					else:
						push_warning("%s is not a HandData resource" % full_path)
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			push_error("Could not open directory: %s" % dir_path)
	else:
		push_error("Directory does not exist: %s" % dir_path)
