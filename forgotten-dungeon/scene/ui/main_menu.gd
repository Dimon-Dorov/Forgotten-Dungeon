extends CanvasLayer

func _on_continue_pressed():
	pass

func _on_new_game_pressed():
	get_tree().change_scene_to_file("res://scene/levels/1/level_1.tscn")

func _on_exit_pressed():
	get_tree().quit()
