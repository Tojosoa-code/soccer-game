class_name PlayerStateTackling
extends PlayerState

const DURATION_PRIOR_RECOVERY := 200
const GROUND_FRICTION := 250.0

var is_tackle_finished := false
var time_finish_tackle := Time.get_ticks_msec()

func _enter_tree() -> void:
	animation_player.play(player.ANIMATIONS.TACKLE)
	tackle_damage_emitter_area.monitoring = true

func _process(_delta: float) -> void:
	if not is_tackle_finished :
		player.velocity = player.velocity.move_toward(Vector2.ZERO, _delta * GROUND_FRICTION)
		if player.velocity == Vector2.ZERO :
			is_tackle_finished = true
			time_finish_tackle = Time.get_ticks_msec()
	if Time.get_ticks_msec() - time_finish_tackle > DURATION_PRIOR_RECOVERY :
		transition_state(player.State.RECOVERING)

func _exit_tree() -> void:
	tackle_damage_emitter_area.monitoring = false
