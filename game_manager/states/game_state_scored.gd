class_name GameStateScored
extends GameState

const DURATION_CELEBRATION := 3000

var time_since_celebration := Time.get_ticks_msec()

func _enter_tree() -> void:
	var index_country_scoring := 1 if manager.countries[0] == state_data.country_scored_on else 0
	manager.score[index_country_scoring] += 1
	time_since_celebration = Time.get_ticks_msec()

func _process(_delta: float) -> void:
	if Time.get_ticks_msec() - time_since_celebration > DURATION_CELEBRATION :
		transition_state(GameManager.State.RESET)
