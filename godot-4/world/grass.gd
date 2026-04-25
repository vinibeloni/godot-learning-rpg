extends Node2D

@export var GrassEffect: PackedScene
@onready var hurtbox: Hurtbox = $Hurtbox

func _ready() -> void:
	hurtbox.hurt.connect(_on_hurt)

func _on_hurt(hitbox: Hitbox) -> void:
	var grassEffect = GrassEffect.instantiate()
	get_tree().current_scene.add_child(grassEffect)
	grassEffect.global_position = global_position
	queue_free()
