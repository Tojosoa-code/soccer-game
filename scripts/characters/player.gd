class_name Player
extends CharacterBody2D

#region // enum
enum ControlScheme {
	CPU, 
	P1,
	P2
}

enum State {
	MOVING,
	TACKLING,
	RECOVERING,
	PREPPING_SHOT,
	SHOOTING,
	PASSING,
}
#endregion

#region // variable d'exportation
@export var control_scheme : ControlScheme
@export var speed : float
@export var power : float
@export var ball : Ball
#endregion

#region // variable onready
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var player_sprite: Sprite2D = %PlayerSprite
@onready var teammate_detection_area: Area2D = %TeammateDetectionArea
#endregion

#region // variable standart
var heading : Vector2 = Vector2.RIGHT
var current_state : PlayerState = null
var state_factory := PlayerStateFactory.new()
#endregion

#region // variable constant
const ANIMATIONS : Dictionary = {
	IDLE = "idle",
	RUN = "run",
	TACKLE = "tackle",
	RECOVER = "recover",
	KICK = "kick",
	PREP_KICK = "prep_kick",
}
#endregion

func _ready() -> void :
	switch_state(State.MOVING)

func _process(_delta: float) -> void:
	flip_sprites()
	move_and_slide()

func switch_state(state : State, state_data : PlayerStateData = PlayerStateData.new()) -> void :
	if current_state != null :
		current_state.queue_free()
	current_state = state_factory.get_fresh_state(state)
	current_state.setup(self, teammate_detection_area, ball, state_data, animation_player)
	current_state.state_transition_requested.connect(switch_state.bind())
	current_state.name = "PlayerStateMachine : " + str(state)
	call_deferred("add_child", current_state)
	
func set_movement_animation() -> void :
	if velocity.length() > 0 :
		animation_player.play(ANIMATIONS.RUN)
	else :
		animation_player.play(ANIMATIONS.IDLE)
	
func set_heading() -> void :
	if velocity.x > 0 :
		heading = Vector2.RIGHT
	elif  velocity.x < 0 :
		heading = Vector2.LEFT

func flip_sprites() -> void :
	if heading == Vector2.RIGHT :
		player_sprite.flip_h = false
	elif heading == Vector2.LEFT :
		player_sprite.flip_h = true

func has_ball() -> bool :
	return ball.carrier == self

func on_animation_complete() -> void :
	if current_state != null :
		current_state.on_animation_complete()
