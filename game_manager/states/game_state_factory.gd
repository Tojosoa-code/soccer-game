class_name GameStateFactory

var states : Dictionary 

func _init() -> void:
	states = {
		GameManager.State.IN_PLAY : GameStateInPlay,
		GameManager.State.GAMEOVER : GameStateGameOver,
		GameManager.State.OVERTIME : GameStateOvertime,
		GameManager.State.SCORED : GameStateScored,
		GameManager.State.RESET : GameStateReset
	}

func get_fresh_state(state : GameManager.State) -> GameState :
	assert(states.has(state), "Cette état n'existe pas")
	return states.get(state).new()
