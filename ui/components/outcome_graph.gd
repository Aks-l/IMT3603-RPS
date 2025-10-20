extends Control
class_name OutcomeGraph

##A circular visualization showing all hands and their win/lose relationships

@export_group("Layout config")
##Radius of graph
@export var circle_radius: float = 250.0
##Size of each hand icon
@export var hand_icon_size: float = 80.0
##Line width
@export var line_width_normal: float = 1.0
##Highlighted line width
@export var line_width_highlighted: float = 3.0

##Color settings
@export_group("Colors config")
##Color for winning connections
@export var win_color: Color = Color(0.2, 0.8, 0.2, 0.6)
##Color for losing connections
@export var lose_color: Color = Color(0.8, 0.2, 0.2, 0.6)
##Color for neutral connections
@export var neutral_color: Color = Color(0.4, 0.4, 0.4, 0.3)

var center: Vector2
var hands: Array[HandData] = []
var hand_buttons: Dictionary = {}
var hand_positions: Dictionary = {}
var hovered_hand: HandData = null

func _ready() -> void:
	load_hands()
	setup_ui()
	queue_redraw()

##Load hands from the HandDatabase
func load_hands() -> void:
	if HandDatabase.hands.is_empty():
		push_warning("HandDatabase is empty!")
		return
	
	var hand_ids = HandDatabase.hands.keys()
	hand_ids.sort()
	
	for id in hand_ids:
		var hand = HandDatabase.hands[id]
		if hand.id != 9999 and hand.discovered:
			hands.append(hand)

###Setup the UI elements for each hand
func setup_ui() -> void:
	if hands.is_empty():
		return
	
	center = custom_minimum_size / 2 if custom_minimum_size != Vector2.ZERO else size / 2
	
	var num_hands = hands.size()
	var angle_step = TAU / num_hands
	
	for i in range(num_hands):
		var hand = hands[i]
		var angle = angle_step * i - PI / 2
		
		#Calculate position on circle
		var pos = center + Vector2(cos(angle), sin(angle)) * circle_radius
		hand_positions[hand] = pos
		
		#Create button for hand
		var button = TextureRect.new()
		button.texture = hand.sprite
		button.custom_minimum_size = Vector2(hand_icon_size, hand_icon_size)
		button.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		button.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		#Position the button
		button.position = pos - Vector2(hand_icon_size, hand_icon_size) / 2
		button.size = Vector2(hand_icon_size, hand_icon_size)
		
		# Connect hover signals
		button.mouse_entered.connect(_on_hand_hover.bind(hand))
		button.mouse_exited.connect(_on_hand_unhover)
		
		#Add tooltip
		button.tooltip_text = hand.name.capitalize()
		
		add_child(button)
		hand_buttons[hand] = button


##Draw the outcome graph
func _draw() -> void:
	if hands.is_empty():
		return
	
	#Draw connections
	for hand_a in hands:
		for hand_b in hands:
			if hand_a == hand_b:
				continue
	
			var result = HandsDb.get_result(hand_a, hand_b)
			if result == 0:  # Tie - skip
				continue
			var should_highlight = false
			var color = neutral_color
			var width = line_width_normal
			
			#Highlighting logic
			if hovered_hand != null:
				if hand_a == hovered_hand:
					should_highlight = true
					
					if result == 1:  #hand_a wins
						color = win_color
					
					else:  #hand_a loses
						color = lose_color
					width = line_width_highlighted

				elif hand_b == hovered_hand:
					should_highlight = true

					if result == 1:  #hand_a wins -> hand_b loses
						color = lose_color

					else:  # hand_a loses -> hand_b wins
						color = win_color
					
					width = line_width_highlighted
			
			#Only draw if hovered
			if hovered_hand == null or should_highlight:
				var pos_a = hand_positions[hand_a]
				var pos_b = hand_positions[hand_b]
				
				#Draw line from winner to loser
				if result == 1:  # hand_a beats hand_b
					_draw_connection_line(pos_a, pos_b, color, width)
				else:  # hand_b beats hand_a
					_draw_connection_line(pos_b, pos_a, color, width)

##Draw a line with optional arrowhead
func _draw_connection_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	#Draw line
	draw_line(from, to, color, width, true)
	
	#Draw arrow if line is highlighted
	if width > line_width_normal:
		var direction = (to - from).normalized()
		var arrow_size = 10.0
		var arrow_angle = PI / 6
		
		var left = to - direction.rotated(-arrow_angle) * arrow_size
		var right = to - direction.rotated(arrow_angle) * arrow_size
		
		draw_line(to, left, color, width, true)
		draw_line(to, right, color, width, true)

##Handle hover events
func _on_hand_hover(hand: HandData) -> void:
	hovered_hand = hand
	queue_redraw()

##Handle unhover events
func _on_hand_unhover() -> void:
	hovered_hand = null
	queue_redraw()
