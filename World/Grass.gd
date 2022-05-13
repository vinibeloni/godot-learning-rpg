extends Node2D

func create_effect(effect):
	var GrassEffect = load("res://Effects/{0}Effect.tscn".format([effect]))
	var grassEffect = GrassEffect.instance()
	
	var world = get_tree().current_scene
	world.add_child(grassEffect)
	
	grassEffect.global_position = global_position

func _on_Hurtbox_area_entered(area):
	create_effect("Grass")
	queue_free()
