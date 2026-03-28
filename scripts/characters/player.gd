class_name Player
extends CharacterBody2D

#region // Dictionnary 
const CONTROL_SCHEME_MAP : Dictionary = {
	ControlScheme.CPU : preload("res://assets/art/props/cpu.png"),
	ControlScheme.P1 : preload("res://assets/art/props/1p.png"),
	ControlScheme.P2 : preload("res://assets/art/props/2p.png")
}

const ANIMATIONS : Dictionary = {
	IDLE = "idle",
	RUN = "run",
	TACKLE = "tackle",
	RECOVER = "recover",
	KICK = "kick",
	PREP_KICK = "prep_kick",
	HEADER = "header",
	VOLLEY_KICK = "volley_kick",
	BICYCLE_KICK = "bicycle_kick",
	CHEST_CONTROL = "chest_control",
}
#endregion

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
	HEADER,
	VOLLEY_KICK,
	BICYCLE_KICK,
	CHEST_CONTROL,
}
#endregion

#region // variable d'exportation
@export var control_scheme : ControlScheme
@export var speed : float
@export var power : float
@export var ball : Ball
@export var own_goal : Goal
@export var target_goal : Goal
#endregion

#region // variable onready
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var player_sprite: Sprite2D = %PlayerSprite
@onready var teammate_detection_area: Area2D = %TeammateDetectionArea
@onready var control_sprite: Sprite2D = %ControlSprite
@onready var ball_detection_area: Area2D = %BallDetectionArea
#endregion

#region // variable standart
var heading : Vector2 = Vector2.RIGHT
var current_state : PlayerState = null
var state_factory := PlayerStateFactory.new()
var height := 0.0
var height_velocity := 0.0
#endregion

#region // variable constant
const GRAVITY := 8.0
const BALL_CONTROL_HEIGHT_MAX := 5.0
#endregion

func _ready() -> void :
	set_control_texture()
	switch_state(State.MOVING)

func _process(delta: float) -> void:
	flip_sprites()
	set_sprite_visibility()
	process_gravity(delta)
	move_and_slide()

func switch_state(state : State, state_data : PlayerStateData = PlayerStateData.new()) -> void :
	if current_state != null :
		current_state.queue_free()
	current_state = state_factory.get_fresh_state(state)
	current_state.setup(self, teammate_detection_area, ball, state_data, animation_player, ball_detection_area, own_goal, target_goal)
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

func process_gravity(delta : float) -> void :
	if height > 0 :
		height_velocity -= GRAVITY * delta
		height += height_velocity
		if height <= 0 :
			height = 0
	player_sprite.position = Vector2.UP * height

func flip_sprites() -> void :
	if heading == Vector2.RIGHT :
		player_sprite.flip_h = false
	elif heading == Vector2.LEFT :
		player_sprite.flip_h = true

func set_sprite_visibility() -> void :
	control_sprite.visible = has_ball() or not control_scheme == ControlScheme.CPU

func has_ball() -> bool :
	return ball.carrier == self

func set_control_texture() -> void :
	control_sprite.texture = CONTROL_SCHEME_MAP[control_scheme]

func on_animation_complete() -> void :
	if current_state != null :
		current_state.on_animation_complete()

func control_ball() -> void :
	if ball.height > BALL_CONTROL_HEIGHT_MAX :
		switch_state(Player.State.CHEST_CONTROL)
