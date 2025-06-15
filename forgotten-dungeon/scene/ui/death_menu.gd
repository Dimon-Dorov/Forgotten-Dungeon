extends CanvasLayer

func _ready():
	hide()

func show_menu():
	show()
	get_tree().paused = true

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit_pressed():
	get_tree().quit()
