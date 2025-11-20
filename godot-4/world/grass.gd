extends Node2D

const GrassEffect = preload("res://effects/grass_effect.tscn")

@onready var area_2d: Area2D = $Area2D

func _ready() -> void:
	area_2d.area_entered.connect(_on_area_2d_area_entered)

func _on_area_2d_area_entered(other_area: Area2D) -> void:
	var grassEffect = GrassEffect.instantiate()
	get_tree().current_scene.add_child(grassEffect)
	grassEffect.global_position = global_position
	queue_free()
