extends Node

# Velocity
var ACCELERATION = 0
var MAX_SPEED = 0
var FRICTION = 0
var ROLL_SPEED = 0
var ROLL_FRICTION = 0

var looking_position = Vector2.DOWN
var _velocity = Vector2.ZERO

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

func apply_run_acceleration(input, delta):
  _move_toward(input * MAX_SPEED, ACCELERATION * delta)

func apply_run_friction(delta):
  _move_toward(Vector2.ZERO, FRICTION * delta)
  
func _move_toward(to, delta):
  _velocity = _velocity.move_toward(to, delta)
