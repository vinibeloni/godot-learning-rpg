extends Node

# Velocity
var ACCELERATION = 0
var MAX_SPEED = 0
var FRICTION = 0
var ROLL_SPEED = 0
var ROLL_FRICTION = 0

var _velocity = Vector2.ZERO
var _input = Vector2.ZERO
var looking_position = Vector2.DOWN

var player = null

func setup(parent, acceleration, max_speed, friction, roll_speed):
  player = parent
  ACCELERATION = acceleration
  MAX_SPEED = max_speed
  FRICTION = friction
  ROLL_SPEED = roll_speed
  ROLL_FRICTION = (MAX_SPEED / 2)

# Specific control functions

func apply_roll_acceleration():
  _velocity = looking_position * ROLL_SPEED
  
func apply_roll_friction():
  _velocity = looking_position * ROLL_FRICTION

# Basic control functions

func reset_velocity():
  _velocity = Vector2.ZERO

func move_player():
  _velocity = player.move_and_slide(_velocity)

func set_input(input):
  _input = input

func get_looking_position():
  _input = Vector2.ZERO
  _input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
  _input.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
  return _input.normalized()

func apply_player_acceleration(delta):
  _set_velocity(_input * MAX_SPEED, ACCELERATION * delta)

func apply_player_friction(delta):
  _set_velocity(Vector2.ZERO, FRICTION * delta)
  
func _set_velocity(to, delta):
  _velocity = _velocity.move_toward(to, delta)
