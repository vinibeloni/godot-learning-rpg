extends Node2D

const GrassEffect = preload("res://Effects/GrassEffect.tscn")

func create_effect(effect):
  var grassEffect = GrassEffect.instance()
  grassEffect.global_position = global_position # or self.position
  
  get_parent().add_child(grassEffect)

func _on_Hurtbox_area_entered(area):
  create_effect("Grass")
  queue_free()
