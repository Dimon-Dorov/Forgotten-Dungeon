class_name Player
extends CharacterBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@export var ui: CanvasLayer
@onready var collision_shape = $CollisionShape2D
@onready var death_menu = get_node("../DeathMenu")

@onready var up_attack1 = $up_attack1
@onready var up_attack2 = $up_attack2
@onready var down_attack1 = $down_attack1
@onready var down_attack2 = $down_attack2
@onready var left_attack1 = $left_attack1
@onready var left_attack2 = $left_attack2
@onready var right_attack1 = $right_attack1
@onready var right_attack2 = $right_attack2

var walk_speed = 45
var sprint_speed = 85
var acceleration = 0.1

var attack_step = 1
var is_attacking = false
var last_direction = Vector2.DOWN

var max_health = 100
var health = max_health

var max_stamina = 100
var stamina = max_stamina
var stamina_recovery_rate = 10
var stamina_drain_rate = 15
var attack_stamina_cost = 10
var stamina_recovery_delay = 1.5
var time_since_last_stamina_use = 0
var is_recovering_stamina = false

var is_dead = false

func _process(delta):
	if ui:
		ui.update_stamina(stamina, max_stamina)
		ui.update_health(health, max_health)

	if is_attacking:
		return

	var direction = movement_vector().normalized()
	var is_sprinting = Input.is_action_pressed("sprint") and stamina > 0

	if is_sprinting and direction.length() > 0:
		stamina -= stamina_drain_rate * delta
		stamina = max(stamina, 0)
		time_since_last_stamina_use = 0
		is_recovering_stamina = false
	else:
		time_since_last_stamina_use += delta
		if time_since_last_stamina_use >= stamina_recovery_delay:
			is_recovering_stamina = true

	if is_recovering_stamina and stamina < max_stamina:
		stamina += stamina_recovery_rate * delta
		stamina = min(stamina, max_stamina)

	if Input.is_action_just_pressed("attack") and stamina >= attack_stamina_cost:
		stamina -= attack_stamina_cost
		time_since_last_stamina_use = 0
		is_recovering_stamina = false
		play_next_attack()
		return

	var speed = sprint_speed if is_sprinting else walk_speed
	var target_velocity = direction * speed
	
	if direction.length() > 0:
		last_direction = direction
		velocity = velocity.lerp(target_velocity, acceleration)
		move_and_slide()
		
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				animated_sprite_2d.play("right_sprint" if is_sprinting else "right_run")
			else:
				animated_sprite_2d.play("left_sprint" if is_sprinting else "left_run")
		else:
			if direction.y > 0:
				animated_sprite_2d.play("down_sprint" if is_sprinting else "down_run")
			else:
				animated_sprite_2d.play("up_sprint" if is_sprinting else "up_run")
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		match_direction_idle(last_direction)

func movement_vector():
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

func play_next_attack():
	is_attacking = true
	velocity = Vector2.ZERO

	var attack_node
	var dir = last_direction
	var dir_name := ""

	if abs(dir.x) > abs(dir.y):
		dir_name = "right" if dir.x > 0 else "left"
	else:
		dir_name = "down" if dir.y > 0 else "up"

	match dir_name + "_attack" + str(attack_step):
		"up_attack1": attack_node = up_attack1
		"up_attack2": attack_node = up_attack2
		"down_attack1": attack_node = down_attack1
		"down_attack2": attack_node = down_attack2
		"left_attack1": attack_node = left_attack1
		"left_attack2": attack_node = left_attack2
		"right_attack1": attack_node = right_attack1
		"right_attack2": attack_node = right_attack2

	animated_sprite_2d.play(dir_name + "_attack" + str(attack_step))
	if attack_node:
		attack_node.visible = true
		attack_node.monitoring = true

	attack_step += 1
	if attack_step > 2:
		attack_step = 1

func disable_all_attacks():
	for child in get_children():
		if child is Area2D and "attack" in child.name:
			child.visible = false
			child.monitoring = false

func match_direction_idle(direction):
	if abs(direction.x) > abs(direction.y):
		animated_sprite_2d.play("right_idle" if direction.x > 0 else "left_idle")
	else:
		animated_sprite_2d.play("down_idle" if direction.y > 0 else "up_idle")

func take_damage(amount: int):
	health -= amount
	health = max(health, 0)
	print("Player takes damage: ", amount, ", current health: ", health) # Додано для дебагу
	if ui:
		ui.update_health(health, max_health)
	if health <= 0:
		die()

func die():
	velocity = Vector2.ZERO
	animated_sprite_2d.play("death")
	collision_shape.call_deferred("set_disabled", true)
	set_process(false)
	set_physics_process(false)
	is_dead = true

func _on_animated_sprite_2d_animation_finished():
	if is_attacking:
		is_attacking = false
		disable_all_attacks()
	if is_dead and animated_sprite_2d.animation == "death":
		death_menu.show_menu()

func _on_down_attack_1_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(20)

func _on_down_attack_2_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(20)

func _on_up_attack_1_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(20)

func _on_up_attack_2_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(20)

func _on_right_attack_1_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(20)

func _on_right_attack_2_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(20)

func _on_left_attack_1_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(20)

func _on_left_attack_2_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(20)
