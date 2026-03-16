class_name PlayerStateFactory

var states : Dictionary

func _init() -> void:
	states = {
		Player.State.MOVING : PlayerStateMoving,
		Player.State.TACKLING : PlayerStateTackling,
		Player.State.RECOVERING : PlayerStateRecovering,
		Player.State.SHOOTING : PlayerStateShooting,
		Player.State.PREPPING_SHOT : PlayerStatePreppingShot,
		Player.State.PASSING : PlayerStatePassing,
		Player.State.HEADER : PlayerStateHeader,
		Player.State.VOLLEY_KICK : PlayerStateVolleyKick,
		Player.State.BICYCLE_KICK : PlayerStateBicycleKick,
	}

func get_fresh_state(state : Player.State) -> PlayerState :
	assert(states.has(state), "Ce State n'existe PAS !!!")
	return states.get(state).new()
