extends KinematicBody2D

const PlayerHurtSound = preload("res://Player/Hurtsound/PlayerHurtSound.tscn")

enum State {
  MOVE,
  ROLL,
  ATTACK
}

var state = State.MOVE
var stats = PlayerStats

onready var swordHitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox
onready var blinkAnimation = $BlinkAnimation

onready var movement = $Movement
onready var animation = $MovementAnimation

func _ready():
  randomize()
  stats.connect("no_health", self, "queue_free")
  
  swordHitbox.knockbackVector = movement.looking_position
  
  movement.setup(self, 500, 100, 500, 120)
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
  var input = movement.get_looking_position()
  
  if input == Vector2.ZERO:
    _stop_moving(delta)
  else:
    _move_to(input, delta)
    
  movement.move_player()
  
  _check_new_state()

func _move_to(input, delta):
  movement.looking_position = input
  swordHitbox.knockbackVector = input
  
  animation.set_animations_position(input)
  
  animation.run()
  movement.apply_player_acceleration(delta)

func _stop_moving(delta):
  animation.idle()
  movement.apply_player_friction(delta)

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
