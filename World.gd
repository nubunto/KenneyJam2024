extends Node3D

@onready var game_over_screen = $GameOverScreen

@onready var player = %Player

func _ready():
	player.died.connect(_on_player_died)

func _on_player_died():
	game_over_screen.visible = true
