class_name PlayerStateChestControl
extends PlayerState

const DURATION_CONTROL := 500

var time_since_control := Time.get_ticks_msec()

func _enter_tree() -> void:
	print("CHEST")
	animation_player.play(player.ANIMATIONS.CHEST_CONTROL)
	player.velocity = Vector2.ZERO
	time_since_control = Time.get_ticks_msec()

func _process(_delta: float) -> void:
	if Time.get_ticks_msec() - time_since_control > DURATION_CONTROL :
		transition_state(Player.State.MOVING)
