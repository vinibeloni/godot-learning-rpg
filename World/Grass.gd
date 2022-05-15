extends Node2D

const GrassEffect = preload("res://Effects/GrassEffect.tscn")

func create_effect():
  var effect = GrassEffect.instance()
  effect.global_position = global_position # or self.position
  
  get_parent().add_child(effect)

func _on_Hurtbox_area_entered():
  create_effect()
  queue_free()
