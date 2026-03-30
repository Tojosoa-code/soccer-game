class_name ActorsContainer
extends Node2D

@export var ball : Ball
@export var goal_home : Goal
@export var goal_away : Goal

const DURATION_WEIGHT_CACHE := 200
const PLAYER_PREFAB := preload("res://scenes/characters/player.tscn")

@onready var spawns: Node2D = %Spawns

var squad_home : Array[Player] = []
var squad_away : Array[Player] = []
var time_since_last_cache_refresh := Time.get_ticks_msec()


func _ready() -> void:
	squad_home = spawn_players(GameManager.countries[0], goal_home)
	spawns.scale.x = -1
	goal_home.initialize(GameManager.countries[0])
	squad_away = spawn_players(GameManager.countries[1], goal_away)
	goal_away.initialize(GameManager.countries[1])
	# Contrôle initial : joueur le plus proche du ballon pour squad_away
	assign_control_to_closest(squad_away, Player.ControlScheme.P1)
	ball.carrier_changed.connect(on_ball_carrier_changed)


func _process(_delta: float) -> void:
	if Time.get_ticks_msec() - time_since_last_cache_refresh > DURATION_WEIGHT_CACHE:
		time_since_last_cache_refresh = Time.get_ticks_msec()
		set_on_duty_weights()


# ✅ FIX : Gestion du changement de porteur par signal (évite les race conditions)
func on_ball_carrier_changed(_old_carrier: Player, new_carrier: Player) -> void:
	if new_carrier == null:
		return
	
	# Trouver l'équipe du nouveau porteur
	var is_squad_home := new_carrier in squad_home
	var is_squad_away := new_carrier in squad_away
	
	if not (is_squad_home or is_squad_away):
		return
	
	# Trouver quel control_scheme est utilisé par cette équipe
	var squad := squad_home if is_squad_home else squad_away
	var team_control_scheme : Player.ControlScheme = Player.ControlScheme.CPU
	
	# Chercher si un joueur de cette équipe est contrôlé par un humain
	for p in squad:
		if p.control_scheme in [Player.ControlScheme.P1, Player.ControlScheme.P2]:
			team_control_scheme = p.control_scheme
			break
	
	# Si l'équipe est contrôlée par un humain, switcher vers le nouveau porteur
	if team_control_scheme != Player.ControlScheme.CPU:
		set_controlled_player(new_carrier, team_control_scheme)


func spawn_players(country : String, own_goal : Goal) -> Array[Player]:
	var player_nodes : Array[Player] = []
	var players := DataLoader.get_squad(country)
	var target_goal := goal_home if own_goal == goal_away else goal_away
	
	for i in players.size():
		var player_position := spawns.get_child(i).global_position as Vector2
		var player_data := players[i] as PlayerResource
		var player := spawn_player(player_position, own_goal, target_goal, player_data, country)
		player_nodes.append(player)
		add_child(player)
	return player_nodes


func spawn_player(player_position : Vector2, own_goal : Goal, target_goal : Goal, player_data : PlayerResource, country : String) -> Player:
	var player : Player = PLAYER_PREFAB.instantiate()
	player.initialize(player_position, ball, own_goal, target_goal, player_data, country)
	
	# Connexion au signal de swap (sans paramètre)
	player.swap_requested.connect(on_player_swap_request.bind(player))
	
	return player


# ====================== GESTION DU CONTRÔLE ======================
func set_controlled_player(target_player : Player, scheme : Player.ControlScheme) -> void:
	var squad := squad_home if target_player.country == squad_home[0].country else squad_away
	
	# Tout le monde passe en CPU
	for p in squad:
		if p.control_scheme != Player.ControlScheme.CPU:
			p.control_scheme = Player.ControlScheme.CPU
			p.set_control_texture()
	
	# Le nouveau joueur prend le contrôle
	target_player.control_scheme = scheme
	target_player.set_control_texture()


func assign_control_to_closest(squad: Array[Player], scheme: Player.ControlScheme) -> void:
	var closest_player: Player = null
	var min_dist := INF
	for p in squad:
		if p.role == Player.Role.GOALIE: continue
		var dist := p.position.distance_squared_to(ball.position)
		if dist < min_dist:
			min_dist = dist
			closest_player = p
	if closest_player != null:
		set_controlled_player(closest_player, scheme)

func on_player_swap_request(requester: Player) -> void:
	if requester == null: 
		return
	
	var squad := squad_home if requester.country == squad_home[0].country else squad_away
	var best_player: Player = null
	var best_score := -INF
	
	# Position cible : si adversaire a le ballon, on switch vers lui (pressing intelligent)
	var target_position := ball.position
	if ball.carrier != null and ball.carrier.country != requester.country:
		target_position = ball.carrier.position  # on presse le porteur adverse !
	
	for p in squad:
		if p == requester or p.control_scheme != Player.ControlScheme.CPU or p.role == Player.Role.GOALIE:
			continue
		
		# Calcul du score (plus le score est haut, mieux c'est)
		var dist_to_target := p.position.distance_squared_to(target_position)
		var dist_to_opponent_goal := p.position.distance_squared_to(requester.target_goal.position)
		
		# Score = proximité au ballon/porteur + bonus position offensive
		var score := 10000.0 / (dist_to_target + 1.0) + 3000.0 / (dist_to_opponent_goal + 1.0)
		
		if score > best_score:
			best_score = score
			best_player = p
	
	if best_player != null:
		set_controlled_player(best_player, requester.control_scheme)

func set_on_duty_weights() -> void:
	for squad in [squad_away, squad_home]:
		var cpu_players : Array[Player] = squad.filter(
			func (p : Player):
				return p.control_scheme == Player.ControlScheme.CPU and p.role != Player.Role.GOALIE
		)
		# Tri par distance au ballon
		cpu_players.sort_custom(
			func (p1 : Player, p2 : Player):
				return p1.position.distance_squared_to(ball.position) < p2.position.distance_squared_to(ball.position)
		)
		for i in range(cpu_players.size()):
			cpu_players[i].weight_on_duty_steering = 1 - ease(float(i) / 10.0, 0.1)
