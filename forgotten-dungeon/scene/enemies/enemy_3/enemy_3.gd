extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $Area2D
@onready var attack_area_1 = $Attack_1
@onready var attack_shape_1 = $Attack_1/CollisionPolygon2D
@onready var attack_area_2 = $Attack_2
@onready var attack_shape_2 = $Attack_2/CollisionPolygon2D
@onready var attack_area_3 = $Attack_3
@onready var attack_shape_3 = $Attack_3/CollisionPolygon2D
@onready var collision = $CollisionShape2D
@onready var patrol_area = $Area2D/CollisionShape2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var xp_value = 100.0
var player_detected = false
var spawn_position = Vector2.ZERO
var patrol_target = Vector2.ZERO
var move_speed = 35
var player = null
var state = "patrolling"
var last_seen_position = Vector2.ZERO
var search_timer = 0.0
const SEARCH_DURATION = 15.0
var patrol_pause_timer = 0.0
var is_patrol_paused = false
var has_engaged = false

var max_health = 85
var health = max_health
var is_dead = false
var was_close_to_player = false

var can_attack = true
var attack_cooldown = 4.0
var attack_timer = 0.0
var current_attack_type = ""

var patrol_area_center = Vector2.ZERO

func _ready():
	spawn_position = global_position
	patrol_area_center = patrol_area.global_position + patrol_area.position
	attack_area_1.monitoring = false
	attack_area_2.monitoring = false
	attack_area_3.monitoring = false
	if !Engine.is_editor_hint():
		await get_tree().process_frame
		set_new_patrol_target()

func _on_navigation_finished():
	if state == "patrolling" and !is_patrol_paused:
		is_patrol_paused = true
		patrol_pause_timer = randf_range(5.0, 7.0)

func _physics_process(delta):
	if is_dead:
		return
	if !can_attack:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
			print("[ATTACK] Cooldown reset.")
	match state:
		"patrolling":
			patrol(delta)
		"chasing":
			chase(delta)
		"searching":
			search(delta)
		"returning":
			return_to_patrol(delta)
		"attacking":
			velocity = Vector2.ZERO
			move_and_slide()
			update_animation()
			return
	if !nav_agent.is_navigation_finished():
		var next_position = nav_agent.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		velocity = direction * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	update_animation()

func patrol(delta):
	if is_patrol_paused:
		patrol_pause_timer -= delta
		if patrol_pause_timer <= 0:
			is_patrol_paused = false
			set_new_patrol_target()
	else:
		if nav_agent.target_position != patrol_target:
			nav_agent.target_position = patrol_target

func chase(delta):
	if player == null:
		return
	var dist = global_position.distance_to(player.global_position)
	if dist <= 70:
		was_close_to_player = true
	if dist <= 70 and can_attack:
		state = "attacking"
		attack_player()
	elif dist <= 70 and !can_attack:
		velocity = Vector2.ZERO
	else:
		if nav_agent.target_position != player.global_position:
			nav_agent.target_position = player.global_position
	last_seen_position = player.global_position

func attack_player():
	has_engaged = true
	can_attack = false
	attack_timer = attack_cooldown
	var attack_choice = randi() % 3
	match attack_choice:
		0:
			current_attack_type = "attack_1"
		1:
			current_attack_type = "attack_2"
		2:
			current_attack_type = "attack_3"
	print("[ATTACK] Performing:", current_attack_type)
	animated_sprite.play(current_attack_type)
	await animated_sprite.animation_finished
	attack_area_1.monitoring = false
	attack_area_2.monitoring = false
	attack_area_3.monitoring = false
	state = "chasing"

func search(delta):
	search_timer -= delta
	if is_patrol_paused:
		patrol_pause_timer -= delta
		if patrol_pause_timer <= 0:
			is_patrol_paused = false
			set_random_search_target()
	else:
		if global_position.distance_to(patrol_target) < 5:
			is_patrol_paused = true
			patrol_pause_timer = randf_range(3.0, 7.0)
		else:
			if nav_agent.target_position != patrol_target:
				nav_agent.target_position = patrol_target
	if search_timer <= 0:
		state = "returning"

func return_to_patrol(delta):
	was_close_to_player = false
	if global_position.distance_to(spawn_position) < 5:
		state = "patrolling"
		set_new_patrol_target()
		velocity = Vector2.ZERO
	else:
		if nav_agent.target_position != spawn_position:
			nav_agent.target_position = spawn_position

func take_damage(amount: int):
	if is_dead:
		return
	health -= amount
	print("[DAMAGE] Taken:", amount, " Remaining:", health)
	if health <= 0:
		die()
	if !can_attack:
		attack_timer = max(attack_timer - 0.5, 0.0)
	has_engaged = true
	state = "chasing"

func die():
	if is_instance_valid(player) and player.stats != null:
		player.stats.add_xp(xp_value)
	is_dead = true
	animated_sprite.play("death")
	detection_area.monitoring = false
	collision.set_deferred("disabled", true)

func update_animation():
	if is_dead or state == "attacking":
		return
	if velocity.length() > 0.5:
		animated_sprite.play("run")
		animated_sprite.flip_h = velocity.x < 0
	else:
		animated_sprite.play("idle")
	if animated_sprite.flip_h:
		attack_area_1.scale.x = -1
		attack_area_2.scale.x = -1
		attack_area_3.scale.x = -1
	else:
		attack_area_1.scale.x = 1
		attack_area_2.scale.x = 1
		attack_area_3.scale.x = 1

func set_new_patrol_target():
	var candidate = get_random_point_in_area(patrol_area)
	patrol_target = candidate
	nav_agent.target_position = patrol_target

func set_random_search_target():
	patrol_target = last_seen_position + Vector2(randf_range(-64, 64), randf_range(-64, 64))

func start_searching():
	was_close_to_player = false
	state = "searching"
	search_timer = SEARCH_DURATION
	is_patrol_paused = false
	set_random_search_target()

func get_random_point_in_area(area: CollisionShape2D) -> Vector2:
	var circle_shape = area.shape as CircleShape2D
	var radius = circle_shape.radius
	var center = patrol_area_center
	var angle = randf() * TAU
	var distance = sqrt(randf()) * (radius - 8)
	var offset = Vector2(cos(angle), sin(angle)) * distance
	return center + offset

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body
		player_detected = true
		is_patrol_paused = false
		state = "chasing"
		last_seen_position = player.global_position
		nav_agent.target_position = player.global_position

func _on_detection_area_body_exited(body):
	if is_dead:
		return 
	if body == player:
		await get_tree().process_frame 
		var still_inside = false
		for b in detection_area.get_overlapping_bodies():
			if b.is_in_group("player"):
				still_inside = true
				break
		player_detected = still_inside
		if !player_detected:
			start_searching()

func _on_attack_1_body_entered(body):
	if current_attack_type == "attack_1" and body.is_in_group("player"):
		body.get_hit(10)

func _on_attack_2_body_entered(body):
	if current_attack_type == "attack_2" and body.is_in_group("player"):
		body.get_hit(15)

func _on_attack_3_body_entered(body):
	if current_attack_type == "attack_3" and body.is_in_group("player"):
		body.get_hit(20)

func _on_animated_sprite_2d_animation_finished():
	if is_dead and animated_sprite.animation == "death":
		queue_free()

func _on_animated_sprite_frame_changed():
	if animated_sprite.animation == "attack_1" and animated_sprite.frame == 5:
		attack_area_1.monitoring = true
	if animated_sprite.animation == "attack_2" and animated_sprite.frame == 5:
		attack_area_2.monitoring = true
	if animated_sprite.animation == "attack_3" and animated_sprite.frame == 6:
		attack_area_3.monitoring = true
