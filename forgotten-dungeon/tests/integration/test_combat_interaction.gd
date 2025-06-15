extends GutTest

const TestScene = preload("res://tests/integration/test_combat_interaction_scene.tscn")
var scene_instance
var player: Player
var enemy1
var enemy2

func before_each():
	scene_instance = TestScene.instantiate()
	add_child(scene_instance)
	player = scene_instance.get_node("TestPlayer")
	enemy1 = scene_instance.get_node("TestEnemy1")
	enemy2 = scene_instance.get_node("TestEnemy2")
	enemy1.player = player
	enemy2.player = player

func after_each():
	if is_instance_valid(scene_instance):
		scene_instance.queue_free()

func test_enemy_detects_and_chases_player():
	assert_eq(enemy2.state, "patrolling", "Enemy should initially be in 'patrolling' state.")
	enemy2._on_detection_area_body_entered(player)
	assert_eq(enemy2.state, "chasing", "Enemy state should switch to 'chasing' after detection.")

func test_player_attack_damages_enemy():
	var initial_enemy_health = enemy2.health
	player._on_left_attack_1_body_entered(enemy2)
	var expected_health = initial_enemy_health - 20
	assert_eq(enemy2.health, expected_health, "Enemy health should decrease by 20 after player's attack.")

func test_enemy_charge_attack_damages_player():
	var initial_player_health = player.health
	enemy1._on_charge_attack_area_body_entered(player)
	var expected_health = initial_player_health - 25
	assert_eq(player.health, expected_health, "Player health should decrease by 25 after enemy_1's charge attack.")

func test_player_death_disables_collision_and_state():
	var player_collision_shape = player.get_node("CollisionShape2D")
	assert_false(player.is_dead, "Player should not be dead initially.")
	assert_false(player_collision_shape.disabled, "Player collision should be enabled initially.")
	player.take_damage(player.max_health + 50)
	await get_tree().process_frame
	assert_true(player.is_dead, "Player's 'is_dead' flag should be true after lethal damage.")
	assert_true(player_collision_shape.disabled, "Player collision shape should be disabled after death.")
