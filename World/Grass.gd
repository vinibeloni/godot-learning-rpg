extends Node2D

func _process(delta):
	if Input.is_action_just_pressed("attack"):
		var selfPosition = global_position
		var grassEffect = add_effect_in_the_world("Grass")
		
		grassEffect.global_position = selfPosition
		
		queue_free()

func add_effect_in_the_world(effect):
	var GrassEffect = load("res://Effects/{0}Effect.tscn".format([effect]))
	var grassEffect = GrassEffect.instance()
	var world = get_tree().current_scene
	world.add_child(grassEffect)
	return grassEffect
