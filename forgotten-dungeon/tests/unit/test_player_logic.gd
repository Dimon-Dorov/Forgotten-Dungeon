extends GutTest

const PlayerScene = preload("res://scene/player/player.tscn")
var player_instance: CharacterBody2D

func before_each():
	player_instance = PlayerScene.instantiate()
	add_child(player_instance)

func after_each():
	if is_instance_valid(player_instance):
		player_instance.queue_free()
	Input.action_release("move_right")
	Input.action_release("move_left")
	Input.action_release("move_up")
	Input.action_release("move_down")


func test_movement_vector_calculates_correctly():
	var result_vector: Vector2
	Input.action_press("move_right")
	await get_tree().physics_frame
	result_vector = player_instance.movement_vector()
	assert_eq(result_vector, Vector2.RIGHT, "Vector should be (1, 0) when 'move_right' is pressed")
	Input.action_release("move_right")
	Input.action_press("move_left")
	Input.action_press("move_up")
	await get_tree().physics_frame
	result_vector = player_instance.movement_vector()
	assert_eq(result_vector, Vector2(-1, -1), "Vector should be (-1, -1) for left and up")
	Input.action_release("move_left")
	Input.action_release("move_up")
