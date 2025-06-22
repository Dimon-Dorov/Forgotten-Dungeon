extends Node

@onready var player: Player = $Player
@onready var upgrade_menu = $UpgradeMenu
@onready var pause_menu = $PausMenu

func _ready():
	add_to_group("level_manager")

	GameManager.setup_session(GameManager.load_on_start)
	
	if player and is_instance_valid(GameManager.player_stats):
		player.initialize(GameManager.player_stats)
	else:
		print("FATAL: Could not initialize Player in Level1, stats not found.")

func on_menu_closed():
	get_tree().paused = false

func _unhandled_input(event):
	if Input.is_action_just_pressed("toggle_upgrade_menu"):
		if get_tree().paused:
			return
		
		get_tree().paused = true
		upgrade_menu.open_menu()
	
	elif Input.is_action_just_pressed("ui_cancel"):
		if upgrade_menu.visible:
			return

		if pause_menu.visible:
			pause_menu.hide_menu()
			get_tree().paused = false
		else:
			pause_menu.show_menu()
			get_tree().paused = true
