class_name Ball
extends AnimatableBody2D

enum State  {
	CARRIED,
	FREEFORM,
	SHOT
}

const ANIMATIONS : Dictionary = {
	IDLE = "idle",
	ROLL = "roll",
}

@onready var ball_sprite: Sprite2D = %BallSprite
@onready var player_detection_area: Area2D = %PlayerDetectionArea
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var current_state : BallState = null
var velocity := Vector2.ZERO
var state_factory := BallStateFactory.new()
var carrier : Player = null
var height := 0.0

func _ready() -> void:
	switch_state(State.FREEFORM)

func _process(_delta: float) -> void:
	ball_sprite.position = Vector2.UP * height

func switch_state(state : Ball.State) -> void :
	if current_state != null :
		current_state.queue_free()
	current_state = state_factory.get_fresh_state(state)
	current_state.setup(self, player_detection_area, carrier, animation_player, ball_sprite)
	current_state.state_transition_requested.connect(switch_state.bind())
	current_state.name = "BallStateMachine"
	call_deferred("add_child", current_state)

func shoot(shot_velocity : Vector2) -> void :
	velocity = shot_velocity
	carrier = null
	switch_state(Ball.State.SHOT)
