extends KinematicBody2D

const IDLE_ANIM = "Idle"
const RUN_ANIM = "Run"
const ATTACK_ANIM = "Attack"

const ACCELERATION = 500
const MAX_SPEED = 100
const FRICTION = ACCELERATION

enum {
	MOVE_STATE,
	ROLL_STATE,
	ATTACK_STATE
}

var state = MOVE_STATE
var velocity = Vector2.ZERO

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")

func _ready():
	animationTree.active = true

func _process(delta):
	match state:
		MOVE_STATE:
			move_state(delta)
		ROLL_STATE:
			pass
		ATTACK_STATE:
			attack_state()
	
func move_state(delta):
	var input = Vector2.ZERO
	input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input = input.normalized()
	
	if input != Vector2.ZERO:
		set_blend_position(IDLE_ANIM, input)
		set_blend_position(RUN_ANIM, input)
		set_blend_position(ATTACK_ANIM, input)
		
		animationState.travel(RUN_ANIM)
		
		velocity = velocity.move_toward(input * MAX_SPEED, ACCELERATION * delta)
	else:
		animationState.travel(IDLE_ANIM)
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
	velocity = move_and_slide(velocity)
	
	if Input.is_action_just_pressed("attack"):
		state = ATTACK_STATE

func set_blend_position(animationName, vector):
	animationTree.set("parameters/{0}/blend_position".format([animationName]), vector)

func attack_state():
	velocity = Vector2.ZERO
	animationState.travel(ATTACK_ANIM)
	
func attack_animation_finished():
	state = MOVE_STATE
