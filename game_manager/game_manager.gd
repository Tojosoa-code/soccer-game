extends Node

#region // enum
enum State {
	IN_PLAY,
	SCORED,
	RESET,
	KICKOFF,
	OVERTIME,
	GAMEOVER,
}
#endregion

#region // constant
const DURATION_GAME_SEC : float = 2 * 60
#endregion

#region // variable standart
var time_left : float
var countries : Array[String] = ["FRANCE", "USA"]
var score : Array[int] = [0, 0]
var current_state : GameState = null
var state_factory := GameStateFactory.new()
#endregion

func _ready() -> void:
	time_left = DURATION_GAME_SEC
	switch_state(State.IN_PLAY)

func switch_state(state : State, data : GameStateData = GameStateData.new()) -> void :
	if current_state != null :
		current_state.queue_free()
	current_state = state_factory.get_fresh_state(state)
	current_state.setup(self, data)
	current_state.state_transition_requested.connect(switch_state.bind())
	current_state.name = "GameStateMachine : " + str(state)
	call_deferred("add_child", current_state)
