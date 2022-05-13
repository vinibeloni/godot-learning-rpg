extends Node2D

onready var animatedSprite = $AnimatedSprite

func _ready():
	animatedSprite.play("Animate")

func _process(delta):
	if Input.is_action_just_pressed("attack"):
		animatedSprite.play("Animate")
