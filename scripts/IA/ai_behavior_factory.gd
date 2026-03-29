class_name AIBehaviorFactory

var roles : Dictionary

func _init() -> void:
	roles = {
		Player.Role.GOALIE : AIBehaviorGoalie,
		Player.Role.DEFENSE : AIBehaviorField,
		Player.Role.MIDFIELD : AIBehaviorField,
		Player.Role.OFFENSE : AIBehaviorField,
	}

func get_ai_behavior(role : Player.Role) -> AIBehavior :
	assert(roles.has(role), "Ce rôle n'existe pas!")
	return roles.get(role).new()
