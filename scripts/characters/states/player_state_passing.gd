class_name PlayerStatePassing
extends PlayerState

func _enter_tree() -> void:
	animation_player.play(player.ANIMATIONS.KICK)
	player.velocity = Vector2.ZERO

func on_animation_complete() -> void:
	var pass_target := state_data.pass_target
	if pass_target == null:
		pass_target = find_teammate_in_view()
	
	if pass_target == null:
		ball.pass_to(ball.position + player.heading * player.speed)
	else:
		# CORRECTION : Calculer le temps de trajet
		var distance := ball.position.distance_to(pass_target.position)
		var ball_speed := 300.0  # À ajuster selon ta vitesse de passe réelle
		var travel_time := distance / ball_speed
		
		# Prédire où sera le joueur quand le ballon arrive
		var predicted_position := pass_target.position + pass_target.velocity * travel_time
		ball.pass_to(predicted_position)
	
	transition_state(Player.State.MOVING)

func find_teammate_in_view() -> Player:
	var players_in_view := teammate_detection_area.get_overlapping_bodies()
	var valid_teammates := []
	
	for p in players_in_view:
		if p == player or p.country != player.country:
			continue
		
		# Filtre 1 : Vérifier qu'il est vraiment devant
		var direction_to_teammate := player.position.direction_to(p.position)
		var dot := player.heading.dot(direction_to_teammate)
		if dot < 0.5:  # Au moins 60° devant
			continue
		
		# Filtre 2 : Éviter les passes si un adversaire est trop proche de la ligne
		if is_opponent_blocking_pass(p):
			continue
		
		# Filtre 3 : Privilégier ceux qui courent vers le but
		var score := calculate_pass_quality(p)
		valid_teammates.append({"player": p, "score": score})
	
	if valid_teammates.is_empty():
		return null
	
	# Trier par qualité de passe
	valid_teammates.sort_custom(
		func(a, b): return a.score > b.score
	)
	
	return valid_teammates[0].player

func calculate_pass_quality(teammate: Player) -> float:
	var score := 0.0
	
	# Plus proche = mieux (mais pas le seul critère)
	var distance := player.position.distance_to(teammate.position)
	score += (300.0 - clamp(distance, 0, 300)) / 300.0  # Normalisé 0-1
	
	# Bonus si il court vers le but adverse
	var to_goal := teammate.position.direction_to(player.target_goal.get_center_target_position())
	if teammate.velocity.length() > 10.0:  # S'il bouge
		var alignment := teammate.velocity.normalized().dot(to_goal)
		score += alignment * 0.5
	
	# Bonus si il est plus avancé vers le but adverse
	var my_dist_to_goal := player.position.distance_to(player.target_goal.get_center_target_position())
	var his_dist_to_goal := teammate.position.distance_to(player.target_goal.get_center_target_position())
	if his_dist_to_goal < my_dist_to_goal:
		score += 0.3  # Il est plus proche du but que moi
	
	return score

func is_opponent_blocking_pass(teammate: Player) -> bool:
	# Vérifier s'il y a un adversaire proche de la ligne de passe
	var opponents := get_tree().get_nodes_in_group("players")
	
	for opp in opponents:
		if opp.country == player.country:
			continue
		
		# Calculer la distance de l'adversaire à la ligne de passe
		var closest_point := get_closest_point_on_segment(
			player.position,
			teammate.position,
			opp.position
		)
		
		var dist_to_line = opp.position.distance_to(closest_point)
		
		if dist_to_line < 30.0:  # Adversaire trop proche de la ligne
			return true
	
	return false

# Fonction helper pour calculer le point le plus proche sur un segment
func get_closest_point_on_segment(a: Vector2, b: Vector2, point: Vector2) -> Vector2:
	var ab := b - a
	var ap := point - a
	
	var ab_length_squared := ab.length_squared()
	if ab_length_squared == 0:
		return a
	
	var t = clamp(ap.dot(ab) / ab_length_squared, 0.0, 1.0)
	return a + ab * t
