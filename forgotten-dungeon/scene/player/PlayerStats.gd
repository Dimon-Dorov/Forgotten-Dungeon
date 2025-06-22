class_name PlayerStats
extends Resource

signal stats_changed
signal xp_changed(current_xp, xp_to_next_level)
signal level_upped(new_level, skill_points)

@export var level: int = 1:
	set(value):
		if level != value:
			level = value
			level_upped.emit(level, skill_points)
			stats_changed.emit()

@export var current_xp: float = 0.0:
	set(value):
		if not is_equal_approx(current_xp, value):
			current_xp = value
			xp_changed.emit(current_xp, xp_to_next_level)

@export var xp_to_next_level: float = 100.0

@export var skill_points: int = 0:
	set(value):
		if skill_points != value:
			skill_points = value
			stats_changed.emit()

@export var max_health: float = 100.0:
	set(value):
		if not is_equal_approx(max_health, value):
			max_health = value
			self.current_health = min(current_health, max_health)
			stats_changed.emit()

@export var current_health: float = 100.0:
	set(value):
		var new_health = clamp(value, 0, max_health)
		if not is_equal_approx(current_health, new_health):
			current_health = new_health
			stats_changed.emit()

@export var max_stamina: float = 100.0:
	set(value):
		if not is_equal_approx(max_stamina, value):
			max_stamina = value
			self.current_stamina = min(current_stamina, max_stamina)
			stats_changed.emit()

@export var current_stamina: float = 100.0:
	set(value):
		var new_stamina = clamp(value, 0, max_stamina)
		if not is_equal_approx(current_stamina, new_stamina):
			current_stamina = new_stamina
			stats_changed.emit()

@export var attack_power: float = 20.0:
	set(value):
		if not is_equal_approx(attack_power, value):
			attack_power = value
			stats_changed.emit()

@export var defense: float = 50.0:
	set(value):
		if not is_equal_approx(defense, value):
			defense = value
			stats_changed.emit()

@export var crit_chance: float = 0.10:
	set(value):
		var new_value = clamp(value, 0.0, 1.0)
		if not is_equal_approx(crit_chance, new_value):
			crit_chance = new_value
			stats_changed.emit()

@export var crit_damage_multiplier: float = 1.55:
	set(value):
		var new_value = max(1.0, value)
		if not is_equal_approx(crit_damage_multiplier, new_value):
			crit_damage_multiplier = new_value
			stats_changed.emit()

const BASE_WALK_SPEED = 45.0
const BASE_SPRINT_SPEED = 85.0
@export var move_speed_multiplier: float = 1.0:
	set(value):
		if not is_equal_approx(move_speed_multiplier, value):
			move_speed_multiplier = value
			stats_changed.emit()

func _init():
	current_health = max_health
	current_stamina = max_stamina

func add_xp(amount: float):
	current_xp += amount
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		_level_up()
	stats_changed.emit()

func _level_up():
	level += 1
	xp_to_next_level = round(100.0 * pow(1.2, level - 1))
	skill_points += 1
	current_health = max_health
	current_stamina = max_stamina

func take_damage(raw_damage: float):
	var final_damage = DamageCalculator.CalculateReceivedDamage(raw_damage, defense)
	current_health -= final_damage

func spend_point_on_health() -> bool:
	if skill_points < 1: return false
	skill_points -= 1
	max_health += 20.0
	current_health = max_health
	return true

func spend_point_on_stamina() -> bool:
	if skill_points < 1: return false
	skill_points -= 1
	max_stamina += 15.0
	current_stamina = max_stamina
	return true
	
func spend_point_on_attack() -> bool:
	if skill_points < 1: return false
	skill_points -= 1
	attack_power += 2.0
	return true

func spend_point_on_defense() -> bool:
	if skill_points < 1: return false
	skill_points -= 1
	defense += 25.0
	return true
	
func spend_point_on_crit_chance() -> bool:
	if skill_points < 1: return false
	skill_points -= 1
	crit_chance += 0.03
	return true

func spend_point_on_crit_damage() -> bool:
	if skill_points < 1: return false
	skill_points -= 1
	crit_damage_multiplier += 0.10
	return true
	
func spend_point_on_move_speed() -> bool:
	if skill_points < 1: return false
	skill_points -= 1
	move_speed_multiplier += 0.05
	return true
