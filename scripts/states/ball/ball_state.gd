class_name BallState
extends Node

@warning_ignore("unused_signal")
signal state_transition_requested(new_state : BallState)

var ball : Ball = null
var player_detection_area : Area2D = null
var carrier : Player = null

func setup(context_ball : Ball, context_player_detection_area : Area2D, context_carrier : Player) -> void :
	ball = context_ball
	carrier = context_carrier
	player_detection_area = context_player_detection_area
