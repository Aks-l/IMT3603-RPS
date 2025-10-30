extends Control

var invSize = Globals.item_inventory_size
var itemsLoad = Globals.consumables

func _ready():
	_setup_inventory_layout()
	_load_items_into_slots()

##Setup inventory slots with dynamic sizing
func _setup_inventory_layout() -> void:
	var container = %tempItemInv
	
	#Get the ui panel and its margins
	var panel = %Panel
	print(panel.size)
	var margin_container = %MarginContainer
	
	var margin_left = margin_container.get_theme_constant("margin_left")
	var margin_right = margin_container.get_theme_constant("margin_right")
	var margin_top = margin_container.get_theme_constant("margin_top")
	var margin_bottom = margin_container.get_theme_constant("margin_bottom")
	
	#Calculate available space
	var available_width = panel.size.x - margin_left - margin_right
	var available_height = panel.size.y - margin_top - margin_bottom
	print(available_width, available_height, "---------------------------")
	
	#Calculate slot size
	var columns = 2
	var rows = ceil(float(invSize) / columns)
	
	#Get spacing from GridContainer
	var h_spacing = container.get_theme_constant("h_separation")
	var v_spacing = container.get_theme_constant("v_separation")
	
	var slot_width = (available_width - h_spacing * (columns - 1)) / columns
	var slot_height = (available_height - v_spacing * (rows - 1)) / rows
	var slot_size = min(slot_width, slot_height)
	
	# Create slots with calculated size
	for i in invSize:
		var slot := tempItemInvSlot.new()
		slot.init(ItemData.Type.ACCESSORY, Vector2(slot_size, slot_size))
		container.add_child(slot)

##Load items from Globals into inventory slots
func _load_items_into_slots() -> void:
	var container = %tempItemInv
	print(itemsLoad.size())

	#Add items to slots
	for i in min(itemsLoad.size(), invSize):
		var item := tempInvItem.new()
		item.init(itemsLoad[i])
		container.get_child(i).add_child(item)

func _process(delta):
	if Input.is_action_just_pressed("ui_text_indent"):
		self.visible = !self.visible
