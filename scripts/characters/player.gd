class_name Player
extends CharacterBody2D

#region // Signal
@warning_ignore("unused_signal")
signal swap_requested
#endregion

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
	WALK = "walk",
	HURT = "hurt",
	DIVE_DOWN = "dive_down",
	DIVE_UP = "dive_up",
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
	HURT,
	DIVING,
}

enum Role {
	GOALIE,
	DEFENSE,
	MIDFIELD,
	OFFENSE,
}

enum SkinColor {
	LIGHT,
	MEDIUM,
	DARK,
}
#endregion

#region // variable d'exportation
@export var control_scheme : ControlScheme
@export var speed : float
@export var power : float
@export var ball : Ball
@export var own_goal : Goal
@export var target_goal : Goal
@export var circle_radius := 10.0
@export var border_color := Color(1, 1, 1, 0.5)
@export var border_width := 2.0
@export var triangle_size := 8.0
@export var triangle_color := Color(0.15, 0.75, 1.0, 1)
@export var direction_angle_deg := 0.0   
#endregion

#region // variable onready
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var player_sprite: Sprite2D = %PlayerSprite
@onready var teammate_detection_area: Area2D = %TeammateDetectionArea
@onready var control_sprite: Sprite2D = %ControlSprite
@onready var ball_detection_area: Area2D = %BallDetectionArea
@onready var tackle_damage_emitter_area: Area2D = %TackleDamageEmitterArea
@onready var opponent_detection_area: Area2D = %OpponentDetectionArea
@onready var permanent_damage_emitter_area: Area2D = %PermanentDamageEmitterArea
@onready var goalie_hands_collider: CollisionShape2D = %GoalieHandsCollider
#endregion

#region // variable standart
var fullname : String = ""
var country : String = ""
var heading : Vector2 = Vector2.RIGHT
var spawn_position := Vector2.ZERO
var height := 0.0
var height_velocity := 0.0
var weight_on_duty_steering := 0.0
var current_state : PlayerState = null
var current_ai_behavior : AIBehavior = null
var state_factory := PlayerStateFactory.new()
var ai_behavior_factory := AIBehaviorFactory.new()
var skin_color := Player.SkinColor.MEDIUM
var role := Player.Role.MIDFIELD
#endregion

#region // variable constant
const GRAVITY := 8.0
const BALL_CONTROL_HEIGHT_MAX := 5.0
const WALK_ANIM_THRESHOLD := 0.6
const COUNTRIES := ["DEFAULT", "FRANCE", "ARGENTINA", "BRAZIL", "ENGLAND", "GERMANY", "ITALY", "SPAIN", "USA"]
#endregion

func _ready() -> void :
	set_control_texture()
	setup_ai_behavior()
	switch_state(State.MOVING)
	set_shader_properties()
	spawn_position = position
	permanent_damage_emitter_area.monitoring = role == Role.GOALIE
	goalie_hands_collider.disabled = role != Role.GOALIE
	tackle_damage_emitter_area.body_entered.connect(on_tackle_player.bind())
	permanent_damage_emitter_area.body_entered.connect(on_tackle_player.bind())

func _process(delta: float) -> void:
	flip_sprites()
	set_sprite_visibility()
	process_gravity(delta)
	move_and_slide()
	queue_redraw()

func initialize(context_position : Vector2, context_ball : Ball, context_own_goal : Goal, context_target_goal : Goal, context_player_data : PlayerResource, context_country : String) -> void :
	position = context_position
	ball = context_ball
	own_goal = context_own_goal
	target_goal = context_target_goal
	fullname = context_player_data.full_name
	speed = context_player_data.speed
	power = context_player_data.power
	skin_color = context_player_data.skin_color
	role = context_player_data.role
	heading = Vector2.LEFT if target_goal.position.x < position.x else Vector2.RIGHT
	country = context_country

func switch_state(state : State, state_data : PlayerStateData = PlayerStateData.new()) -> void :
	if current_state != null :
		current_state.queue_free()
	current_state = state_factory.get_fresh_state(state)
	current_state.setup(self, teammate_detection_area, ball, state_data, animation_player, ball_detection_area, own_goal, target_goal, current_ai_behavior, tackle_damage_emitter_area)
	current_state.state_transition_requested.connect(switch_state.bind())
	current_state.name = "PlayerStateMachine : " + str(state)
	call_deferred("add_child", current_state)

func setup_ai_behavior() -> void :
	current_ai_behavior = ai_behavior_factory.get_ai_behavior(role)
	current_ai_behavior.setup(self, ball, opponent_detection_area, teammate_detection_area)
	current_ai_behavior.name = "AI Behavior"
	add_child(current_ai_behavior)

func set_shader_properties() -> void :
	player_sprite.material.set_shader_parameter("skin_color", skin_color)
	var country_color := COUNTRIES.find(country)
	country_color = clampi(country_color, 0, COUNTRIES.size() - 1)
	player_sprite.material.set_shader_parameter("team_color", country_color)

func set_movement_animation() -> void :
	var vel_length := velocity.length()
	if vel_length < 1 : 
		animation_player.play(ANIMATIONS.IDLE)
	elif vel_length < speed * WALK_ANIM_THRESHOLD :
		animation_player.play(ANIMATIONS.WALK)
	else :
		animation_player.play(ANIMATIONS.RUN)
	
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
		tackle_damage_emitter_area.scale.x = 1
		opponent_detection_area.scale.x = 1
	elif heading == Vector2.LEFT :
		player_sprite.flip_h = true
		tackle_damage_emitter_area.scale.x = -1
		opponent_detection_area.scale.x = -1

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

func is_facing_target_goal() -> bool :
	var direction_to_target_goal := position.direction_to(target_goal.position)
	var dot_product := heading.dot(direction_to_target_goal)
	
	return dot_product > 0

func get_hurt(hurt_origin : Vector2) -> void :
	switch_state(Player.State.HURT, PlayerStateData.build().set_hurt_direction(hurt_origin))

func on_tackle_player(player : Player) :
	if player != self and player.country != country and player == ball.carrier :
		player.get_hurt(position.direction_to(player.position))

func can_carry_ball() -> bool : 
	return current_state != null and current_state.can_carry_ball()

func get_pass_request(player : Player) -> void :
	if ball.carrier == self and current_state != null and current_state.can_pass() :
		switch_state(Player.State.PASSING, PlayerStateData.build().set_pass_target(player))

func _draw() -> void:
	if not (control_scheme == ControlScheme.P1 and has_ball()):
		return 

	var center := Vector2(0.0, -1)

	# Cercle avec bordure
	draw_circle(center, circle_radius, Color(0,0,0,0))
	draw_arc(center, circle_radius, 0, TAU, 64, border_color, border_width)

	# Déterminer l'angle en fonction du mouvement ou du heading
	var angle : float
	if velocity != Vector2.ZERO:
		angle = velocity.angle()
	else:
		angle = heading.angle()

	# Triangle équilatéral sur le bord du cercle
	var base_center := center + Vector2(cos(angle), sin(angle)) * circle_radius
	var tip := center + Vector2(cos(angle), sin(angle)) * (circle_radius + triangle_size)
	var offset := triangle_size * 0.6
	var base_left := base_center + Vector2(cos(angle + PI/2), sin(angle + PI/2)) * offset
	var base_right := base_center + Vector2(cos(angle - PI/2), sin(angle - PI/2)) * offset

	var triangle := PackedVector2Array([tip, base_left, base_right])
	draw_polygon(triangle, [triangle_color])
