extends Node2D

signal finished

@onready var hand1: RigidBody2D = %Hand1
@onready var hand2: RigidBody2D = %Hand2
var dead := preload("res://scenes/FightScene/DeadObject/dead_object.tscn")

const HAND_TARGET_SIZE := Vector2(250, 250)
const BATTLE_SPEED: float = 300.0

var _winner_id: int = 0
var _resolved: bool = false


func _ready() -> void:
	randomize()

	hand1.contact_monitor = true
	hand1.max_contacts_reported = 4
	hand2.contact_monitor = true
	hand2.max_contacts_reported = 4

	hand1.body_entered.connect(_on_hand_body_entered)
	hand2.body_entered.connect(_on_hand_body_entered)


func setup(player_hand: HandData, enemy_hand: HandData, winner_id: int) -> void:
	var sprite1 := hand1.get_node("Sprite2D") as Sprite2D
	var sprite2 := hand2.get_node("Sprite2D") as Sprite2D

	sprite1.texture = enemy_hand.sprite
	sprite2.texture = player_hand.sprite

	_setup_hand_size(hand1)
	_setup_hand_size(hand2)

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


func _animate_clash() -> void:
	hand1.linear_velocity = Vector2(BATTLE_SPEED, 0.0)
	hand2.linear_velocity = Vector2(-BATTLE_SPEED, 0.0)


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
	queue_free()


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
		base_speed_x = BATTLE_SPEED
	elif hand == hand2:
		base_speed_x = -BATTLE_SPEED

	for piece in dead_instance.get_children():
		if piece is RigidBody2D:
			var body_piece := piece as RigidBody2D
			var x_mult := randf_range(0.8, 1.2)
			var vx := base_speed_x * x_mult
			var vy := randf_range(-BATTLE_SPEED * 0.3, BATTLE_SPEED * 0.3)
			body_piece.linear_velocity = Vector2(vx, vy)

	hand.queue_free()
