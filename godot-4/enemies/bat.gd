# Processo de criação
# Cria todos os sprites + animação
# Adiciona state machine para o animation tree
# Corrige Motion Mode para Floating
# Busca player no grupo global "player" para evitar fazer manualmente
# Faz o Bat olhar para o player e se estiver dentro do rage muda o state para Chase
# Para mudar para Chase precisa alterar de Idle -> Chase via Expression
# Configure o RayCast e Layers para buscar o Player

class_name Bat extends CharacterBody2D

const HitMarker = preload("res://effects/hit_effect.tscn")

const MAX_RANGE: = 128
const MIN_RANGE: = 4
const SPEED: = 30
const FRICTION = 500

@export var stats: Stats

@onready var sprite: Sprite2D = $Sprite
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var center: Marker2D = $Center

func _ready() -> void:
	stats = stats.duplicate() # Resources são compartilhados, assim como Sprites
	hurtbox.hurt.connect(_take_hit.call_deferred)
	stats.no_health.connect(queue_free)

func _physics_process(delta: float) -> void:
	var state = playback.get_current_node()
	match state: 
		"IdleState": pass
		"ChaseState":
			var player = get_player()
			if player is Player:
				var direction = global_position.direction_to(player.global_position)
				velocity = direction * SPEED
				sprite.scale.x = sign(velocity.x) # normaliza para 1, -1 ou 0
			else:
				velocity = Vector2.ZERO
			move_and_slide()
		"HitState":
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			move_and_slide()

func _take_hit(hitbox: Hitbox):
	stats.health -= hitbox.damage
	velocity = hitbox.hit()
	playback.start("HitState")
	
	var hit_effect = HitMarker.instantiate()
	get_tree().current_scene.add_child(hit_effect)
	hit_effect.global_position = center.global_position
	

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")

func is_player_in_range() -> bool:
	var result = false
	var player = get_player()
	if player is Player:
		var distance = global_position.distance_to(player.global_position)
		result = distance < MAX_RANGE and distance > MIN_RANGE
		
	return result

# utilizado no AnimationTree
func can_see_player() -> bool:
	if not is_player_in_range(): return false
	
	var player := get_player()
	# target seria a ponta do ray cast, por isso deve calcular a diferença
	ray_cast_2d.target_position = player.global_position - global_position # diferença entre o player e bat
	var vision_is_blocked = ray_cast_2d.is_colliding()
	return not vision_is_blocked
