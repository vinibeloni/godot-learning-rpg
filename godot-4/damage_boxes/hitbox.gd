class_name Hitbox extends Area2D

@export var damage = 1
@export var knockback_amount: = 200
@export var knockback_direction: Vector2
@export var store_targets: bool = false

var targets: Array

func hit() -> Vector2:
	return knockback_direction * knockback_amount

func clear_targets() -> void:
	targets.clear()
