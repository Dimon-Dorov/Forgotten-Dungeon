extends GutTest

const EnemyScript = preload("res://tests/enemy_2.gd")
var enemy

func before_each():
	enemy = partial_double(EnemyScript).new()
	enemy.state = "chasing"

func after_each():
	enemy.free()

func test_state_changes_to_searching():
	stub(enemy, "set_random_search_target").to_do_nothing()
	enemy.start_searching()
	assert_eq(enemy.state, "searching", "State should change to 'searching'")
	assert_eq(enemy.search_timer, enemy.SEARCH_DURATION, "Search timer should be reset")
	assert_false(enemy.is_patrol_paused, "Patrol pause should be reset")

func test_get_random_point_in_area_is_within_radius():
	var mock_shape = CircleShape2D.new()
	mock_shape.radius = 150.0
	var mock_area = CollisionShape2D.new()
	mock_area.shape = mock_shape
	
	var patrol_center = Vector2(1000, 1000)
	enemy.patrol_area_center = patrol_center
	var random_point = enemy.get_random_point_in_area(mock_area)
	var distance_from_center = random_point.distance_to(patrol_center)
	assert_true(distance_from_center <= mock_shape.radius, "Generated point must be within the patrol radius")
