extends Node2D

export(int) var wanderRange = 32

onready var startPosition = global_position
onready var targetPosition = global_position
onready var timer = $Timer

func _ready():
  update_target_position()

func update_target_position():
  var targetVector = Vector2(rand_range(-wanderRange, wanderRange), rand_range(-wanderRange, wanderRange))
  targetPosition = startPosition + targetVector

func get_time_left():
  return timer.time_left
  
func start_wander_timer(duration):
  timer.start(duration)

func _on_Timer_timeout():
  update_target_position()
