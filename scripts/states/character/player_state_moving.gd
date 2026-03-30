class_name PlayerStateMoving
extends PlayerState

func _process(_delta: float) -> void:
	if player.control_scheme == Player.ControlScheme.CPU:
		ai_behavior.process_ai()
	else:
		handle_human_movement()
	
	player.set_movement_animation()
	player.set_heading()


func handle_human_movement() -> void:
	var direction := KeyUtils.get_input_vector(player.control_scheme)
	player.velocity = direction * player.speed
	
	if player.velocity != Vector2.ZERO:
		teammate_detection_area.rotation = player.velocity.angle()
	
	# ====================== CONTROLES CONTEXTUELS FIFA/PES ======================
	if player.has_ball():
		# === ON A LE BALLON (Attaque) ===
		if KeyUtils.is_action_just_pressed(player.control_scheme, KeyUtils.Action.PASS):
			transition_state(Player.State.PASSING)
		elif KeyUtils.is_action_just_pressed(player.control_scheme, KeyUtils.Action.SHOOT):
			transition_state(Player.State.PREPPING_SHOT)
	
	else:
		# === ON N'A PAS LE BALLON (Défense) ===
		if KeyUtils.is_action_just_pressed(player.control_scheme, KeyUtils.Action.PASS):
			# PASS = SWITCH de joueur
			player.swap_requested.emit()
		
		elif KeyUtils.is_action_just_pressed(player.control_scheme, KeyUtils.Action.SHOOT):
			# SHOOT = TACKLE (ou interception aérienne si le ballon est en l'air)
			if ball.can_air_interact():
				if player.velocity == Vector2.ZERO:
					if player.is_facing_target_goal():
						transition_state(Player.State.VOLLEY_KICK)
					else:
						transition_state(Player.State.BICYCLE_KICK)
				else:
					transition_state(Player.State.HEADER)
			elif player.velocity != Vector2.ZERO:
				transition_state(Player.State.TACKLING)


func can_carry_ball() -> bool:
	return player.role != Player.Role.GOALIE


func can_pass() -> bool:
	return true
