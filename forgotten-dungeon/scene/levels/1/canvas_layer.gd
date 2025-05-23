extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var stamina_bar = $StaminaBar

func update_health(value: float, max_value: float):
	health_bar.value = value
	health_bar.max_value = max_value

func update_stamina(value: float, max_value: float):
	stamina_bar.value = value
	stamina_bar.max_value = max_value
