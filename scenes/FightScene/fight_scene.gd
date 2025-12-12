extends Node2D

signal finished

@onready var hand1: RigidBody2D = %Hand1
@onready var hand2: RigidBody2D = %Hand2
var dead := preload("res://scenes/FightScene/DeadObject/dead_object.tscn")

const HAND_TARGET_SIZE := Vector2(250, 250)

const BATTLE_SPEED_FACTOR: float = 2.5 # Lower number -> higher speed

var _battle_speed: float = 400.0
var _winner_id: int = 0
var _resolved: bool = false


func _ready() -> void:
	randomize()
	hand1.body_entered.connect(_on_hand_body_entered)
	hand2.body_entered.connect(_on_hand_body_entered)


func setup(player_hand: HandData, enemy_hand: HandData, winner_id: int) -> void:
	var sprite1 := hand1.get_node("Sprite2D") as Sprite2D
	var sprite2 := hand2.get_node("Sprite2D") as Sprite2D

	sprite1.texture = enemy_hand.sprite
	sprite2.texture = player_hand.sprite

	_setup_hand_size(hand1)
	_setup_hand_size(hand2)

	# Center and place hands relative to current window size
	_position_hands()

	# Reset any previous motion
	hand1.linear_velocity = Vector2.ZERO
	hand2.linear_velocity = Vector2.ZERO

	_winner_id = winner_id
	_resolved = false

	_animate_clash()


func _setup_hand_size(hand: RigidBody2D) -> void:
	var sprite := hand.get_node("Sprite2D") as Sprite2D
	var shape_node := hand.get_node("CollisionShape2D") as CollisionShape2D

	if sprite.texture:
		var tex_size := sprite.texture.get_size()
		if tex_size.x != 0.0 and tex_size.y != 0.0:
			var scale_vec := HAND_TARGET_SIZE / tex_size
			sprite.scale = scale_vec

	if shape_node.shape is RectangleShape2D:
		var rect := shape_node.shape as RectangleShape2D
		rect.size = HAND_TARGET_SIZE


# New helper: put hands in the middle, hand1 on the right and hand2 on the left
func _position_hands() -> void:
	var viewport_size := get_viewport_rect().size
	var center := viewport_size * 0.5

	# Distance from center so they are ready to move towards each other
	var half_gap :float = viewport_size.x * 0.3
	print(viewport_size, half_gap)

	# hand1 on the right, hand2 on the left
	hand1.position = center + Vector2(half_gap, 0.0)
	hand2.position = center - Vector2(half_gap, 0.0)
	
	_battle_speed = viewport_size.x / BATTLE_SPEED_FACTOR


func _animate_clash() -> void:
	hand1.linear_velocity = Vector2(-_battle_speed, 0.0)
	hand2.linear_velocity = Vector2(_battle_speed, 0.0)


func _on_hand_body_entered(body: Node2D) -> void:
	if _resolved:
		return
	_resolved = true

	match _winner_id:
		1:
			kill_hand(hand2)  # hand1 wins
		-1:
			kill_hand(hand1)  # hand2 wins
		0:
			kill_hand(hand1)  # draw
			kill_hand(hand2)
		_:
			push_error("Could not decide winner, winner_id is %d" % _winner_id)

	# linger for 2 seconds before telling the outside world we are done
	await get_tree().create_timer(2.0).timeout
	emit_signal("finished")
func kill_hand(hand: RigidBody2D) -> void:
	if hand == null or not is_instance_valid(hand):
		return

	var loser_sprite := hand.get_node_or_null("Sprite2D") as Sprite2D
	if loser_sprite == null:
		return

	var parent := hand.get_parent()
	if parent == null:
		parent = get_tree().current_scene

	var dead_instance := dead.instantiate()
	parent.add_child(dead_instance)

	dead_instance.position = parent.to_local(loser_sprite.global_position)

	var base_speed_x := 0.0
	if hand == hand1:
		base_speed_x = _battle_speed
	elif hand == hand2:
		base_speed_x = -_battle_speed

	for piece in dead_instance.get_children():
		if piece is RigidBody2D:
			var body_piece := piece as RigidBody2D
			var x_mult := randf_range(0.8, 1.2)
			var vx := base_speed_x * x_mult
			var vy := randf_range(-_battle_speed * 0.3, _battle_speed * 0.3)
			body_piece.linear_velocity = Vector2(vx, vy)

	hand.queue_free()
