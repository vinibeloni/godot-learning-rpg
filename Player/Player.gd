extends KinematicBody2D

const IDLE_ANIM = "Idle"
const RUN_ANIM = "Run"
const ROLL_ANIM = "Roll"
const ATTACK_ANIM = "Attack"

const ACCELERATION_FRICTION = 500

export var ACCELERATION = ACCELERATION_FRICTION
export var MAX_SPEED = 100
export var FRICTION = ACCELERATION_FRICTION
export var ROLL_SPEED = 120

enum State {
  MOVE,
  ROLL,
  ATTACK
}

var state = State.MOVE
var velocity = Vector2.ZERO
var rollVector = Vector2.DOWN
var stats = PlayerStats

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var swordHitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox

func _ready():
  stats.connect("no_health", self, "queue_free")
  animationTree.active = true
  swordHitbox.knockbackVector = rollVector

func _physics_process(delta):
  match state:
    State.MOVE:
      move_state(delta)
    State.ROLL:
      roll_state()
    State.ATTACK:
      attack_state()
  
func move_state(delta):
  var input = Vector2.ZERO
  input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
  input.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
  input = input.normalized()
  
  if input != Vector2.ZERO:
    rollVector = input
    swordHitbox.knockbackVector = input
    
    set_blend_position(IDLE_ANIM, input)
    set_blend_position(RUN_ANIM, input)
    set_blend_position(ROLL_ANIM, input)
    set_blend_position(ATTACK_ANIM, input)
    
    animationState.travel(RUN_ANIM)
    
    velocity = velocity.move_toward(input * MAX_SPEED, ACCELERATION * delta)
  else:
    animationState.travel(IDLE_ANIM)
    velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
    
  move_me()
  
  if Input.is_action_just_pressed("roll"):
    state = State.ROLL
  
  if Input.is_action_just_pressed("attack"):
    state = State.ATTACK

func set_blend_position(animationName, vector):
  animationTree.set("parameters/{0}/blend_position".format([animationName]), vector)

func roll_state():
  velocity = rollVector * ROLL_SPEED
  animationState.travel(ROLL_ANIM)
  move_me()

func attack_state():
  velocity = Vector2.ZERO
  animationState.travel(ATTACK_ANIM)
  
func move_me():
  velocity = move_and_slide(velocity)

func roll_animation_finished():
  velocity = rollVector * (MAX_SPEED / 2)
  state = State.MOVE

func attack_animation_finished():
  state = State.MOVE

func _on_Hurtbox_area_entered(area):
  stats.health -= 1
  hurtbox.start_invincibility(0.5)
  hurtbox.createa_hit_effect()
