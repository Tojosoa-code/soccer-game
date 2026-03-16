class_name BallState
extends Node

@warning_ignore("unused_signal")
signal state_transition_requested(new_state : Ball.State)

const GRAVITY := 10.0

var ball : Ball = null
var player_detection_area : Area2D = null
var carrier : Player = null
var animation_player : AnimationPlayer = null
var ball_sprite : Sprite2D = null

func setup(context_ball : Ball, context_player_detection_area : Area2D, context_carrier : Player, context_animation_player : AnimationPlayer, context_ball_sprite : Sprite2D) -> void :
	ball = context_ball
	carrier = context_carrier
	player_detection_area = context_player_detection_area
	animation_player = context_animation_player
	ball_sprite = context_ball_sprite

func set_ball_animation_from_velocity() -> void :
	if ball.velocity == Vector2.ZERO :
		animation_player.play(ball.ANIMATIONS.IDLE)
	elif ball.velocity.x > 0 :
		animation_player.play(ball.ANIMATIONS.ROLL)
		animation_player.advance(0)
	else : 
		animation_player.play_backwards(ball.ANIMATIONS.ROLL)
		animation_player.advance(0)

func process_gravity(delta : float, bouciness : float = 0.0 ) -> void :
	if ball.height > 0 or ball.height_velocity > 0:
		ball.height_velocity -= GRAVITY * delta
		ball.height += ball.height_velocity
		if ball.height < 0 :
			ball.height = 0
			if bouciness > 0 and ball.height_velocity < 0 :
				ball.height_velocity = -ball.height_velocity * bouciness
				ball.velocity *= bouciness

func move_and_bounce(delta : float) -> void :
	var collision := ball.move_and_collide(ball.velocity * delta)
	
	if collision != null :
		ball.velocity = ball.velocity.bounce(collision.get_normal()) * ball.BOUCINESS
		ball.switch_state(Ball.State.FREEFORM)

func can_air_interact() -> bool :
	return false
