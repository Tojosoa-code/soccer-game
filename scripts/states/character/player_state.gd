class_name PlayerState
extends Node

signal state_transition_requested(new_state : Player.State, state_data : PlayerStateData)

var player : Player = null
var animation_player : AnimationPlayer = null
var ball : Ball = null
var state_data : PlayerStateData = null
var teammate_detection_area : Area2D = null

func setup(context_player : Player, context_teammate_detection_area : Area2D, context_ball : Ball, context_state_data : PlayerStateData, context_animation_player : AnimationPlayer) -> void :
	player = context_player
	state_data = context_state_data
	ball = context_ball
	teammate_detection_area = context_teammate_detection_area
	animation_player = context_animation_player

@warning_ignore("shadowed_variable")
func transition_state(new_state : Player.State, state_data : PlayerStateData = PlayerStateData.new()) -> void :
	state_transition_requested.emit(new_state, state_data)

func on_animation_complete() -> void :
	pass
