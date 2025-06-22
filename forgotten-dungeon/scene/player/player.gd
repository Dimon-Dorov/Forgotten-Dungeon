class_name Player
extends CharacterBody2D

var stats: PlayerStats

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var up_attack1 = $up_attack1
@onready var up_attack2 = $up_attack2
@onready var down_attack1 = $down_attack1
@onready var down_attack2 = $down_attack2
@onready var left_attack1 = $left_attack1
@onready var left_attack2 = $left_attack2
@onready var right_attack1 = $right_attack1
@onready var right_attack2 = $right_attack2

@export var ui: CanvasLayer
@onready var death_menu = get_node("../DeathMenu") 

var acceleration = 0.1
var attack_step = 1
var is_attacking = false
var last_direction = Vector2.DOWN
var time_since_last_stamina_use = 0.0
var is_recovering_stamina = false
var is_dead = false

func initialize(player_stats: PlayerStats):
	stats = player_stats
	if ui and stats:
		stats.stats_changed.connect(_on_stats_changed)
		_on_stats_changed()

func _on_stats_changed():
	if ui:
		ui.update_stamina(stats.current_stamina, stats.max_stamina)
		ui.update_health(stats.current_health, stats.max_health)
	
func _physics_process(delta):
	if is_dead or is_attacking:
		move_and_slide()
		return
	if not stats: return
	var direction = movement_vector()
	var is_sprinting = Input.is_action_pressed("sprint") and stats.current_stamina > 0
	if is_sprinting and direction.length() > 0:
		stats.current_stamina -= 15.0 * delta
		time_since_last_stamina_use = 0.0
		is_recovering_stamina = false
	else:
		time_since_last_stamina_use += delta
		if time_since_last_stamina_use >= 1.5:
			is_recovering_stamina = true
	if is_recovering_stamina and stats.current_stamina < stats.max_stamina:
		stats.current_stamina += 10.0 * delta
	if Input.is_action_just_pressed("attack") and stats.current_stamina >= 10.0:
		stats.current_stamina -= 10.0
		time_since_last_stamina_use = 0.0
		is_recovering_stamina = false
		play_next_attack()
		return
	var current_walk_speed = stats.BASE_WALK_SPEED * stats.move_speed_multiplier
	var current_sprint_speed = stats.BASE_SPRINT_SPEED * stats.move_speed_multiplier
	var speed = current_sprint_speed if is_sprinting else current_walk_speed
	velocity = velocity.lerp(direction.normalized() * speed, acceleration)
	move_and_slide()
	update_animation(direction.normalized(), is_sprinting)

func get_hit(raw_damage: float):
	if is_dead: return
	if stats:
		stats.take_damage(raw_damage)
	if stats and stats.current_health <= 0:
		die()

func die():
	if is_dead: return
	is_dead = true
	velocity = Vector2.ZERO
	animated_sprite_2d.play("death")
	collision_shape.call_deferred("set_disabled", true)
	set_physics_process(false)

func _on_attack_area_body_entered(body):
	if body.is_in_group("enemies"):
		var damage_info = DamageCalculator.CalculateOutgoingDamage(stats.attack_power, stats.crit_chance, stats.crit_damage_multiplier)
		var damage_to_deal = damage_info.Damage
		if damage_info.IsCrit:
			print("CRITICAL HIT!")
		if body.has_method("take_damage"):
			body.take_damage(damage_to_deal)

func movement_vector():
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

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
	var attack_name = dir_name + "_attack" + str(attack_step)
	match attack_name:
		"up_attack1": attack_node = up_attack1
		"up_attack2": attack_node = up_attack2
		"down_attack1": attack_node = down_attack1
		"down_attack2": attack_node = down_attack2
		"left_attack1": attack_node = left_attack1
		"left_attack2": attack_node = left_attack2
		"right_attack1": attack_node = right_attack1
		"right_attack2": attack_node = right_attack2
	animated_sprite_2d.play(attack_name)
	if attack_node:
		attack_node.monitoring = true
	attack_step += 1
	if attack_step > 2:
		attack_step = 1

func update_animation(direction: Vector2, is_sprinting: bool):
	if direction.length() > 0:
		last_direction = direction
		var anim_prefix: String
		if abs(direction.x) > abs(direction.y):
			anim_prefix = "right" if direction.x > 0 else "left"
		else:
			anim_prefix = "down" if direction.y > 0 else "up"
		animated_sprite_2d.play(anim_prefix + ("_sprint" if is_sprinting else "_run"))
	else:
		match_direction_idle(last_direction)

func match_direction_idle(direction: Vector2):
	var anim_prefix: String
	if abs(direction.x) > abs(direction.y):
		anim_prefix = "right" if direction.x > 0 else "left"
	else:
		anim_prefix = "down" if direction.y > 0 else "up"
	animated_sprite_2d.play(anim_prefix + "_idle")

func disable_all_attacks():
	for child in get_children():
		if child is Area2D and "attack" in child.name:
			child.monitoring = false

func _on_animated_sprite_2d_animation_finished():
	if is_attacking:
		is_attacking = false
		disable_all_attacks()
	if is_dead and animated_sprite_2d.animation == "death":
		death_menu.show_menu()
