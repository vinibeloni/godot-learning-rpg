extends KinematicBody2D

const PlayerHurtSound = preload("res://Player/Hurtsound/PlayerHurtSound.tscn")

enum State {
  MOVE,
  ROLL,
  ATTACK
}

onready var swordHitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox
onready var blinkAnimation = $BlinkAnimation

onready var movement = $Movement
onready var animation = $MovementAnimation

var state = State.MOVE
var stats = PlayerStats

func _ready():
  randomize()
  stats.connect("no_health", self, "queue_free")
  
  swordHitbox.knockbackVector = movement.looking_position
  
  movement.setup(500, 100, 500, 120)
  animation.setup($AnimationTree)

func _physics_process(delta):
  match state:
    State.MOVE:
      _move_state(delta)
    State.ROLL:
      _roll_state()
    State.ATTACK:
      _attack_state()
  
func _move_state(delta):
  var input = _get_user_input()
  
  if input == Vector2.ZERO:
    _stop_moving(delta)
  else:
    _move_to(input, delta)
    
  movement.move_player()
  
  _check_new_state()
  
func _get_user_input():
  var input = Vector2.ZERO
  input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
  input.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
  return input.normalized()

func _move_to(input, delta):
  movement.looking_position = input
  swordHitbox.knockbackVector = input
  
  animation.set_animations_position(input)
  
  animation.run()
  movement.apply_run_acceleration(input, delta)

func _stop_moving(delta):
  animation.idle()
  movement.apply_run_friction(delta)

func _check_new_state():
  if Input.is_action_just_pressed("roll"):
    state = State.ROLL

  if Input.is_action_just_pressed("attack"):
    state = State.ATTACK

# Execute movements

func _roll_state():
  movement.apply_roll_acceleration()
  animation.roll()
  movement.move_player()

func _attack_state():
  movement.reset_velocity()
  animation.attack()

# Animations call functions

func roll_animation_finished():
  movement.apply_roll_friction()
  state = State.MOVE

func attack_animation_finished():
  state = State.MOVE

# Signals

func _on_Hurtbox_area_entered(area):
  stats.health -= area.damage
  hurtbox.start_invincibility(0.8)
  hurtbox.create_hit_effect()
  
  var hurtSound = PlayerHurtSound.instance()
  get_tree().current_scene.add_child(hurtSound)

func _on_Hurtbox_invincibility_started():
   blinkAnimation.play("Start")

func _on_Hurtbox_invincibility_ended():
   blinkAnimation.play("Stop")
