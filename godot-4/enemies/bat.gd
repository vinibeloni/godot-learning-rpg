# Processo de criação
# Cria todos os sprites + animação
# Adiciona state machine para o animation tree
# Corrige Motion Mode para Floating
# Busca player no grupo global "player" para evitar fazer manualmente
# Faz o Bat olhar para o player e se estiver dentro do rage muda o state para Chase
# Para mudar para Chase precisa alterar de Idle -> Chase via Expression
# Configure o RayCast e Layers para buscar o Player

class_name Bat extends CharacterBody2D

const RANGE: = 80
const SPEED: = 50

@onready var sprite: Sprite2D = $Sprite
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback

func _physics_process(delta: float) -> void:
	var state = playback.get_current_node()
	match state: 
		"Idle": pass
		"Chase":
			var player = get_player()
			if player is Player:
				var direction = global_position.direction_to(player.global_position)
				velocity = direction * SPEED
				sprite.scale.x = sign(velocity.x) # normaliza para 1, -1 ou 0
			else:
				velocity = Vector2.ZERO
			move_and_slide()

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")

func is_player_in_range() -> bool:
	var result = false
	var player = get_player()
	if player is Player:
		var distance = global_position.distance_to(player.global_position)
		result = distance < RANGE
		
	return result
