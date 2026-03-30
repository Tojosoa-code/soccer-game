class_name BallStateFactory

var states : Dictionary

func _init() -> void:
	states = {
		Ball.State.CARRIED : BallStateCarried,
		Ball.State.FREEFORM : BallStateFreeForm,
		Ball.State.SHOT : BallStateShot,
	}

func get_fresh_state(state : Ball.State) -> BallState :
	assert(states.has(state), "Ce State n'existe PAS !!!")
	return states.get(state).new()
