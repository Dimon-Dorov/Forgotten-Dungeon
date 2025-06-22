extends CanvasLayer

@onready var level_label = $Panel/VBoxContainer/Label
@onready var skill_points_label = $Panel/VBoxContainer/Label2
@onready var health_label = $Panel/VBoxContainer/HBoxContainer/Label
@onready var health_button = $Panel/VBoxContainer/HBoxContainer/Button
@onready var endurance_label = $Panel/VBoxContainer/HBoxContainer2/Label
@onready var endurance_button = $Panel/VBoxContainer/HBoxContainer2/Button
@onready var attack_label = $Panel/VBoxContainer/HBoxContainer3/Label
@onready var attack_button = $Panel/VBoxContainer/HBoxContainer3/Button
@onready var defense_label = $Panel/VBoxContainer/HBoxContainer7/Label
@onready var defense_button = $Panel/VBoxContainer/HBoxContainer7/Button
@onready var crit_chance_label = $Panel/VBoxContainer/HBoxContainer4/Label
@onready var crit_chance_button = $Panel/VBoxContainer/HBoxContainer4/Button
@onready var crit_damage_label = $Panel/VBoxContainer/HBoxContainer5/Label
@onready var crit_damage_button = $Panel/VBoxContainer/HBoxContainer5/Button
@onready var speed_label = $Panel/VBoxContainer/HBoxContainer6/Label
@onready var speed_button = $Panel/VBoxContainer/HBoxContainer6/Button
@onready var close_button = $Panel/VBoxContainer/Button

var stats: PlayerStats = null
var is_initialized = false

func _ready():
	hide()
	close_button.pressed.connect(_on_close_button_pressed)

func open_menu():
	if not is_initialized:
		initialize_menu()
	update_ui()
	show()

func _on_close_button_pressed():
	hide()
	get_tree().call_group("level_manager", "on_menu_closed")
func initialize_menu():
	stats = GameManager.player_stats
	if stats:
		stats.stats_changed.connect(update_ui)
		stats.xp_changed.connect(update_ui)
		stats.level_upped.connect(update_ui)
		health_button.pressed.connect(Callable(stats, "spend_point_on_health"))
		endurance_button.pressed.connect(Callable(stats, "spend_point_on_stamina"))
		attack_button.pressed.connect(Callable(stats, "spend_point_on_attack"))
		defense_button.pressed.connect(Callable(stats, "spend_point_on_defense"))
		crit_chance_button.pressed.connect(Callable(stats, "spend_point_on_crit_chance"))
		crit_damage_button.pressed.connect(Callable(stats, "spend_point_on_crit_damage"))
		speed_button.pressed.connect(Callable(stats, "spend_point_on_move_speed"))
		
		is_initialized = true
	else:
		print("UpgradeMenu could not find PlayerStats in GameManager!")


func update_ui():
	if not stats: return
	
	level_label.text = "Досвід: " + str(int(stats.current_xp)) + " / " + str(int(stats.xp_to_next_level))
	skill_points_label.text = "Рівень: " + str(stats.level) + " | Очки навичок: " + str(stats.skill_points)
	
	health_label.text = "Макс. Здоров'я: " + str(stats.max_health)
	endurance_label.text = "Макс. Витривалість: " + str(stats.max_stamina)
	attack_label.text = "Сила Атаки: " + str(stats.attack_power)
	defense_label.text = "Захист: " + str(stats.defense)
	crit_chance_label.text = "Шанс Криту: " + str(snapped(stats.crit_chance * 100, 0.01)) + "%"
	crit_damage_label.text = "Крит. Шкода: " + str(int(stats.crit_damage_multiplier * 100)) + "%"
	speed_label.text = "Множник Швидкості: x" + str(snapped(stats.move_speed_multiplier, 0.01))
	
	var can_upgrade = stats.skill_points > 0
	health_button.disabled = not can_upgrade
	endurance_button.disabled = not can_upgrade
	attack_button.disabled = not can_upgrade
	defense_button.disabled = not can_upgrade
	crit_chance_button.disabled = not can_upgrade
	crit_damage_button.disabled = not can_upgrade
	speed_button.disabled = not can_upgrade
