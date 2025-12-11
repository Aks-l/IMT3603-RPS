extends Node2D

signal finished

@onready var hand1: RigidBody2D = %Hand1
@onready var hand2: RigidBody2D = %Hand2
var dead := preload("res://scenes/FightScene/DeadObject/dead_object.tscn")

var _winner_id: int = 0
const battle_speed: int = 200

func _ready() -> void:
	hand1.body_entered.connect(_on_hand_body_entered)
	hand2.body_entered.connect(_on_hand_body_entered)
	_animate_clash()

func setup(player_hand: HandData, enemy_hand: HandData, winner_id: int) -> void:
	hand1.get_node("Sprite2D").texture = enemy_hand.sprite
	hand2.get_node("Sprite2D").texture = player_hand.sprite

	_winner_id = winner_id
	_animate_clash()

func _animate_clash() -> void:
	hand1.linear_velocity = Vector2(battle_speed, 0)
	hand2.linear_velocity = Vector2(-battle_speed, 0)

var _resolved := false

func _on_hand_body_entered(body: Node2D) -> void:
	if _resolved:
		return
	_resolved = true

	match _winner_id:
		1:
			kill_hand(hand2)
		-1:
			kill_hand(hand1)
		0:
			# draw, both hands die
			kill_hand(hand1)
			kill_hand(hand2)
		_:
			# fallback if something weird happens
			if body is RigidBody2D:
				kill_hand(body)

	emit_signal("finished")


func kill_hand(hand: RigidBody2D) -> void:
	if hand == null or not is_instance_valid(hand):
		return

	var loser_sprite := hand.get_node_or_null("Sprite2D") as Sprite2D
	if loser_sprite == null:
		return

	var dead_instance = dead.instantiate()
	get_tree().current_scene.add_child(dead_instance)
	dead_instance.global_position = loser_sprite.global_position

	# base x speed depends on which side died
	var base_speed_x := 0.0
	if hand == hand1:
		base_speed_x = battle_speed          # pieces fly to the right
	elif hand == hand2:
		base_speed_x = -battle_speed         # pieces fly to the left

	for piece in dead_instance.get_children():
		if piece is RigidBody2D:
			# small random variation on x
			var x_mult := randf_range(0.8, 1.2)
			var vx := base_speed_x * x_mult

			# random y offset, tweak this range to taste
			var vy := randf_range(-battle_speed * 0.3, battle_speed * 0.3)

			piece.linear_velocity = Vector2(vx, vy)

	hand.queue_free()
