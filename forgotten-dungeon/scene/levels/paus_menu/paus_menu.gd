extends CanvasLayer

@onready var continue_button = $Panel/VBoxContainer/Continue
@onready var restart_button = $Panel/VBoxContainer/Restart
@onready var exit_button = $Panel/VBoxContainer/Exit

func _ready():
	hide()

func show_menu():
	get_tree().paused = true
	show()

func hide_menu():
	get_tree().paused = false
	hide()

func _on_continue_pressed():
	hide_menu()

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit_pressed():
	get_tree().quit()
