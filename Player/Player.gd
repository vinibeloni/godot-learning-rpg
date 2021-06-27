extends KinematicBody2D

const IDLE = "Idle"
const RUN = "Run"

const ACCELERATION = 500
const MAX_SPEED = 90
const FRICTION = 500

var velocity = Vector2.ZERO
onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")

func _physics_process(delta):
	var input = Vector2.ZERO
	input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input = input.normalized()
	
	if input != Vector2.ZERO:
		_set_position(IDLE, input)
		_set_position(RUN, input)
		animationState.travel(RUN)
		
		velocity = velocity.move_toward(input * MAX_SPEED, ACCELERATION * delta)
	else:
		animationState.travel(IDLE)
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
	velocity = move_and_slide(velocity)

func _set_position(animation, input):
	animationTree.set("parameters/{0}/blend_position".format([animation]), input)
