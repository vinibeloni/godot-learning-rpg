class_name Hurtbox extends Area2D

signal hurt(hitbox: Hitbox)

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	
func _on_area_entered(area2d: Area2D) -> void:
	# print(hitbox.get_parent().name)
	if area2d is not Hitbox: return

	# gambiarra pra previnir duplo ataque
	var hitbox = area2d as Hitbox
	if self in hitbox.targets: return
	if hitbox.store_targets: hitbox.targets.append(self)
	# -
	
	hurt.emit(hitbox)
