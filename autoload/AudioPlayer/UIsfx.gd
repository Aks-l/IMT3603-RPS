extends Node

var click_player: AudioStreamPlayer
var click_stream: AudioStream = preload("res://audio/click_002.wav")

func _enter_tree() -> void:
	# Connect as early as possible
	get_tree().node_added.connect(_on_node_added)

func _ready() -> void:
	# Create the player in code (no node needed)
	click_player = AudioStreamPlayer.new()
	click_player.bus = "UI"
	click_player.stream = click_stream
	add_child(click_player)

	# Also connect buttons that already exist (main menu, first scene, etc.)
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
