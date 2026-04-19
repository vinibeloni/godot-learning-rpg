class_name Bat extends CharacterBody2D

const RANGE: = 80
const SPEED: = 50

@onready var sprite: Sprite2D = $Sprite
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback

func _physics_process(delta: float) -> void:
	var state = playback.get_current_node()
	match state: 
		"Idle": pass
		"Chase":
			var player = get_player()
			if player is Player:
				var direction = global_position.direction_to(player.global_position)
				velocity = direction * SPEED
			else:
				velocity = Vector2.ZERO
			move_and_slide()

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")

func is_player_in_range() -> bool:
	var result = false
	var player = get_player()
	if player is Player:
		var distance = global_position.distance_to(player.global_position)
		result = distance < RANGE
		
	return result
