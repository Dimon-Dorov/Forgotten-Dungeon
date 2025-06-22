extends CanvasLayer

@onready var continue_button = $Panel/VBoxContainer/Continue
@onready var restart_button = $Panel/VBoxContainer/Restart
@onready var exit_button = $Panel/VBoxContainer/Exit

func _ready():
	hide()
	continue_button.pressed.connect(_on_continue_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func show_menu():
	show()

func hide_menu():
	hide()

func _on_continue_pressed():
	hide()
	get_tree().call_group("level_manager", "on_menu_closed")

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit_pressed():
	get_tree().quit()
