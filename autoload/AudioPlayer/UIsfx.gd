extends Node

@onready var music_player = $music_player
@onready var click_player: AudioStreamPlayer = $click_player


func _enter_tree() -> void:
	# Connect as early as possible
	get_tree().node_added.connect(_on_node_added)

func _ready() -> void:
	_connect_existing(get_tree().root)

func _connect_existing(n: Node) -> void:
	if n is BaseButton:
		_connect_button(n as BaseButton)
	for c in n.get_children():
		_connect_existing(c)

func _on_node_added(n: Node) -> void:
	if n is BaseButton:
		_connect_button(n as BaseButton)

func _connect_button(b: BaseButton) -> void:
	if not b.pressed.is_connected(_generic_click_sound):
		b.pressed.connect(_generic_click_sound)

func _generic_click_sound() -> void:
	click_player.stop()
	click_player.play()

func play_sound(sound: AudioStream, skip: float = 0.0):
	music_player.stop()
	music_player.stream = sound
	music_player.play(skip)
