extends CanvasLayer

@onready var continue_button = $Panel/VBoxContainer/Continue

func _ready():
	continue_button.disabled = not SaveManager.has_save_file()

func _on_new_game_pressed():
	GameManager.load_on_start = false
	get_tree().change_scene_to_file("res://scene/levels/1/level_1.tscn")

func _on_continue_pressed():
	GameManager.load_on_start = true
	get_tree().change_scene_to_file("res://scene/levels/1/level_1.tscn")

func _on_exit_pressed():
	get_tree().quit()
