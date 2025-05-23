extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $Area2D
@onready var attack_area = $AttackArea
@onready var attack_shape = $AttackArea/CollisionShape2D
@onready var charge_attack_area = $ChargeAttackArea
@onready var charge_attack_shape = $ChargeAttackArea/CollisionShape2D
@onready var collision = $CollisionShape2D
@onready var patrol_area = $Area2D/CollisionShape2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var spawn_position = global_position

var patrol_target = Vector2.ZERO
var move_speed = 40
var charge_speed = 180
var player = null
var state = "patrolling"
var last_seen_position = Vector2.ZERO
var search_timer = 0.0
const SEARCH_DURATION = 15.0
var patrol_pause_timer = 0.0
var is_patrol_paused = false
var has_engaged = false

var max_health = 50
var health = max_health
var is_dead = false
var was_close_to_player = false

var can_attack = true
var attack_cooldown = 2.0
var attack_timer = 0.0

var can_charge = true
var charge_cooldown = 8.0
var charge_timer = 0.0
var charging = false
var charge_direction = Vector2.ZERO
var charge_destination = Vector2.ZERO
var ready_to_charge = false

var jump_height = -8.0
var jump_duration = 0.2
var jump_elapsed = 0.0
var original_sprite_position = Vector2.ZERO

var patrol_area_center = Vector2.ZERO

var movement_blocked = false
var movement_block_timer = 0.0

func _ready():
	patrol_area_center = patrol_area.global_position + patrol_area.position
	spawn_position = global_position
	original_sprite_position = animated_sprite.position

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	nav_agent.navigation_finished.connect(_on_navigation_finished)

	call_deferred("set_new_patrol_target")

	attack_area.monitoring = false
	charge_attack_area.monitoring = false

func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if movement_blocked:
		movement_block_timer -= delta
		if movement_block_timer <= 0.0:
			movement_blocked = false

	if !can_attack:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true

	if !can_charge:
		charge_timer -= delta
		if charge_timer <= 0:
			can_charge = true

	if ready_to_charge:
		state = "charging"
		ready_to_charge = false
		animated_sprite.play("charge_attack")

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
		"preparing_charge":
			velocity = Vector2.ZERO
			move_and_slide()
		"charging":
			charge_towards_player(delta)

	if movement_blocked or state in ["attacking", "preparing_charge", "charging"]:
		velocity = Vector2.ZERO
	else:
		if !nav_agent.is_navigation_finished():
			var next_position = nav_agent.get_next_path_position()
			var direction = (next_position - global_position).normalized()
			velocity = direction * move_speed
		else:
			velocity = Vector2.ZERO

	move_and_slide()
	update_animation()

func _on_navigation_finished():
	if state == "patrolling" and !is_patrol_paused:
		is_patrol_paused = true
		patrol_pause_timer = randf_range(5.0, 7.0)

func take_damage(amount: int):
	if is_dead:
		return
	health -= amount
	if health <= 0:
		die()
	if !can_attack:
		attack_timer = max(attack_timer - 0.5, 0.0)
	has_engaged = true
	state = "chasing"

func die():
	is_dead = true
	animated_sprite.play("death")
	detection_area.monitoring = false
	collision.set_deferred("disabled", true)

func patrol(delta):
	if is_patrol_paused:
		patrol_pause_timer -= delta
		velocity = Vector2.ZERO
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

	if dist <= attack_shape.shape.radius:
		was_close_to_player = true

	if dist <= attack_shape.shape.radius and can_attack:
		state = "attacking"
		attack_player()
	elif dist <= attack_shape.shape.radius and !can_attack:
		velocity = Vector2.ZERO
	elif was_close_to_player and dist > attack_shape.shape.radius * 1.8 and can_charge:
		state = "preparing_charge"
		prepare_charge_attack()
	else:
		if nav_agent.target_position != player.global_position:
			nav_agent.target_position = player.global_position
	last_seen_position = player.global_position

func attack_player():
	has_engaged = true
	animated_sprite.play("attack")
	await animated_sprite.animation_finished
	await get_tree().create_timer(0.1).timeout
	attack_area.monitoring = false
	can_attack = false
	attack_timer = attack_cooldown
	state = "chasing"

func prepare_charge_attack():
	if !player:
		return

	state = "preparing_charge"
	charging = true
	charge_direction = (player.global_position - global_position).normalized()
	charge_attack_area.rotation = charge_direction.angle()
	charge_destination = global_position + charge_direction * 100
	charge_attack_area.position = charge_direction * 20
	animated_sprite.play("charge_prepare")

func charge_towards_player(delta):
	velocity = charge_direction * charge_speed
	var collision_info = move_and_slide()

	if jump_elapsed < jump_duration:
		jump_elapsed += delta
		var t = jump_elapsed / jump_duration
		animated_sprite.position.y = original_sprite_position.y + jump_height * (1.0 - t)
	else:
		animated_sprite.position = original_sprite_position

	if global_position.distance_to(charge_destination) < 10:
		end_charge_attack()
		return

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision and !collision.get_collider().is_in_group("player"):
			end_charge_attack()
			return

func end_charge_attack():
	charge_attack_area.monitoring = false
	can_charge = false
	charge_timer = charge_cooldown
	charge_attack_area.position = Vector2.ZERO
	state = "chasing"
	charging = false
	movement_blocked = true
	movement_block_timer = 0.5

func search(delta):
	search_timer -= delta
	if is_patrol_paused:
		patrol_pause_timer -= delta
		velocity = Vector2.ZERO
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
	else:
		if nav_agent.target_position != spawn_position:
			nav_agent.target_position = spawn_position

func set_new_patrol_target():
	patrol_target = get_random_point_in_area(patrol_area)
	nav_agent.target_position = patrol_target

func set_random_search_target():
	patrol_target = last_seen_position + Vector2(randf_range(-64, 64), randf_range(-64, 64))
	nav_agent.target_position = patrol_target

func start_searching():
	was_close_to_player = false
	state = "searching"
	search_timer = SEARCH_DURATION
	is_patrol_paused = false
	set_random_search_target()

func update_animation():
	if is_dead:
		return
	if state in ["attacking", "charging", "preparing_charge"]:
		return
	if velocity.length() > 0.5:
		animated_sprite.play("run")
		animated_sprite.flip_h = velocity.x < 0
	else:
		animated_sprite.play("idle")

func get_random_point_in_area(area: CollisionShape2D) -> Vector2:
	var circle_shape = area.shape as CircleShape2D
	var radius = circle_shape.radius
	var center = patrol_area_center
	var angle = randf() * TAU
	var distance = sqrt(randf()) * radius
	var offset = Vector2(cos(angle), sin(angle)) * distance
	return center + offset

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body
		is_patrol_paused = false
		state = "chasing"
		last_seen_position = player.global_position
		nav_agent.target_position = player.global_position

func _on_detection_area_body_exited(body):
	if body == player:
		await get_tree().process_frame
		var still_inside = false
		for b in detection_area.get_overlapping_bodies():
			if b.is_in_group("player"):
				still_inside = true
				break
		if !still_inside:
			start_searching()

func _on_animated_sprite_2d_animation_finished():
	if is_dead and animated_sprite.animation == "death":
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _on_charge_prepare_finished():
	if animated_sprite.animation == "charge_prepare" and state == "preparing_charge" and charging:
		ready_to_charge = true
		jump_elapsed = 0.0
		charge_attack_area.monitoring = true

func _on_animated_sprite_frame_changed():
	if animated_sprite.animation == "attack" and animated_sprite.frame == 5:
		attack_area.monitoring = true

func _on_attack_area_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(10)

func _on_charge_attack_area_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(25)
