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

func _physics_process(delta):
  knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
  knockback = move_and_slide(knockback)
  
  match state:
    State.IDLE:
      velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
      seek_player()
    
    State.WANDER:
      pass
    
    State.CHASE:
      if playerDetectionZone.can_see_player():
        var player = playerDetectionZone.player
        
        # var direction = (player.global_position - global_position).normalized()
        var direction = global_position.direction_to(player.global_position)
        velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
      
      else:
        state = State.IDLE
  
      sprite.flip_h = velocity.x < 0
    
  if softCollision.is_colliding():
    velocity += softCollision.get_push_vector() * delta * COLLISION_PUSH
    
  velocity = move_and_slide(velocity)

func seek_player():
  if playerDetectionZone.can_see_player():
    state = State.CHASE

func _on_Hurtbox_area_entered(area):
  stats.health -= area.damage
  knockback = area.knockbackVector * KNOCKBACK
  hurtbox.createa_hit_effect()

func _on_Stats_no_health():
  queue_free()
  var deathEffect = EnemyDeathEffect.instance()
  get_parent().add_child(deathEffect)
  deathEffect.global_position = global_position # or self.position
