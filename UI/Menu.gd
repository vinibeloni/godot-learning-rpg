extends Control

onready var startButton = $VBoxContainer/Start

func _ready():
  startButton.grab_focus()

func _on_Start_pressed():
 get_tree().change_scene("res://World.tscn")

func _on_Quit_pressed():
 get_tree().quit()
