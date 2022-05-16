extends Node

const IDLE = "Idle"
const RUN = "Run"
const ROLL = "Roll"
const ATTACK = "Attack"

var animationTree = null
var animationState = null

func setup(tree):
  animationTree = tree
  animationTree.active = true
  animationState = animationTree.get("parameters/playback")

# Specific functions

func idle():
  _travel(IDLE)

func run():
  _travel(RUN)

func roll():
  _travel(ROLL)

func attack():
  _travel(ATTACK)

# Control functions

func set_animations_position(input):
    _set_blend_position(IDLE, input)
    _set_blend_position(RUN, input)
    _set_blend_position(ROLL, input)
    _set_blend_position(ATTACK, input)

func _set_blend_position(animationName, vector):
  animationTree.set("parameters/{0}/blend_position".format([animationName]), vector)

func _travel(to):
  animationState.travel(to)
