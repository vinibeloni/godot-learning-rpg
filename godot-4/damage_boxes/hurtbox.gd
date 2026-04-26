class_name Hurtbox extends Area2D

signal hurt(hitbox: Hitbox)

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	
func _on_area_entered(hitbox: Area2D) -> void:
	# print(hitbox.get_parent().name)
	if hitbox is not Hitbox: return
	hurt.emit(hitbox)
