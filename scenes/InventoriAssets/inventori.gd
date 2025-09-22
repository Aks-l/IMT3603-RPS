extends CanvasLayer

var invSize = 5

var itemsLoad = [
	"res://scenes/InventoriAssets/TemporariItemAssets/nail_cliper.tres"
]

func _ready():
	for i in invSize:
		var slot := tempItemInvSlot.new()
		slot.init(tempItems.Type.ACCESSORY, Vector2(128,128))
		%tempItemInv.add_child(slot)

	for i in itemsLoad.size():
		var item := tempInvItem.new()
		item.init(load(itemsLoad[i]))
		%tempItemInv.get_child(i).add_child(item)

func _process(delta):
	if Input.is_action_just_pressed("ui_text_indent"):
		self.visible = !self.visible
	
