extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export var ACCELERATION = 300
export var MAX_SPEED = 50
export var FRICTION = 200
export var KNOCKBACK = 130
export var COLLISION_PUSH = 400

enum State {
  IDLE,
  WANDER,
  CHASE
 }

var velocity = Vector2.ZERO
var knockback = Vector2.ZERO

var state = State.IDLE

onready var sprite = $AnimatedSprite
onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var hurtbox = $Hurtbox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController
onready var blinkAnimation = $BlinkAnimation

func _ready():
  state = pick_random_state([State.IDLE, State.WANDER])

func _physics_process(delta):
  knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
  knockback = move_and_slide(knockback)
  
  match state:
    State.IDLE:
      velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
      seek_player()
      check_for_new_state()
   
    State.WANDER:
      seek_player()
      check_for_new_state()
      accelerate_towards_point(wanderController.targetPosition, delta)
    
      if global_position.distance_to(wanderController.targetPosition) <= MAX_SPEED * .05:
        check_for_new_state()
    
    State.CHASE:
      if playerDetectionZone.can_see_player():
        var player = playerDetectionZone.player
        accelerate_towards_point(player.global_position, delta)
      else:
        state = State.IDLE

  if softCollision.is_colliding():
    velocity += softCollision.get_push_vector() * delta * COLLISION_PUSH
    
  velocity = move_and_slide(velocity)

func seek_player():
  if playerDetectionZone.can_see_player():
    state = State.CHASE

func accelerate_towards_point(point, delta):
  var direction = global_position.direction_to(point)
  velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
  sprite.flip_h = velocity.x < 0

func check_for_new_state():
  if wanderController.get_time_left() == 0:
    state = pick_random_state([State.IDLE, State.WANDER])
    wanderController.start_wander_timer(rand_range(1, 3))

func pick_random_state(states):
  states.shuffle()
  return states.pop_front()

func _on_Hurtbox_area_entered(area):
  stats.health -= area.damage
  knockback = area.knockbackVector * KNOCKBACK
  hurtbox.create_hit_effect()
  hurtbox.start_invincibility(0.4)

func _on_Stats_no_health():
  queue_free()
  var deathEffect = EnemyDeathEffect.instance()
  get_parent().add_child(deathEffect)
  deathEffect.global_position = global_position # or self.position

func _on_Hurtbox_invincibility_started():
  blinkAnimation.play("Start")

func _on_Hurtbox_invincibility_ended():
  blinkAnimation.play("Stop")
