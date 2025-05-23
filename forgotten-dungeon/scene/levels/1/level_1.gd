extends Node

@onready var pause_menu = $PausMenu

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			pause_menu.hide_menu()
		else:
			pause_menu.show_menu()
