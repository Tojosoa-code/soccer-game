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
const DURATION_GAME : float = 2 * 60 * 1000
#endregion

#region // variable standart
var time_left : float
var countries : Array[String] = ["FRANCE", "USA"]
var score : Array[int] = [0, 0]
#endregion

func _ready() -> void:
	time_left = DURATION_GAME
