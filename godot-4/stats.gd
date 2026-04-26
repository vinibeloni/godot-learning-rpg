class_name Stats extends Resource

signal health_changed(new_health)
signal no_health()

@export var health: = 1:
	set(value):
		var previous_health = health
		health = value
		if previous_health != health: health_changed.emit(health)
		if health <= 0: no_health.emit()

@export var max_health: = 1
