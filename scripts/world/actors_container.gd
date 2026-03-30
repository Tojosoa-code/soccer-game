class_name ActorsContainer
extends Node2D

@export var ball : Ball
@export var goal_home : Goal
@export var goal_away : Goal
@export var team_home : String
@export var team_away : String

const DURATION_WEIGHT_CACHE := 200
const PLAYER_PREFAB := preload("res://scenes/characters/player.tscn")

@onready var spawns: Node2D = %Spawns

var squad_home : Array[Player] = []
var squad_away : Array[Player] = []
var time_since_last_cache_refresh := Time.get_ticks_msec()

# Pour le switch automatique après passe
var current_ball_carrier : Player = null


func _ready() -> void:
	squad_home = spawn_players(team_home, goal_home)
	spawns.scale.x = -1
	squad_away = spawn_players(team_away, goal_away)
	
	# Contrôle initial : joueur le plus proche du ballon
	assign_control_to_closest(squad_away, Player.ControlScheme.P1)


func _process(_delta: float) -> void:
	if Time.get_ticks_msec() - time_since_last_cache_refresh > DURATION_WEIGHT_CACHE:
		time_since_last_cache_refresh = Time.get_ticks_msec()
		set_on_duty_weights()
	
	# === SWITCH AUTOMATIQUE SUR LE NOUVEAU PORTEUR (comme FIFA/PES) ===
	if ball.carrier != current_ball_carrier:
		current_ball_carrier = ball.carrier
		if current_ball_carrier != null and current_ball_carrier in squad_away:
			set_controlled_player(current_ball_carrier, Player.ControlScheme.P1)


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
	
	# === CONNEXION CORRIGÉE (signal sans paramètre) ===
	player.swap_requested.connect(on_player_swap_request)
	
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


# Bouton PASS en défense → switch manuel
# Bouton PASS en défense → switch manuel INTELLIGENT
func on_player_swap_request() -> void:
	var requester := get_current_controlled_player()
	if requester == null: return
	
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

# Helper pour trouver le joueur actuellement contrôlé par le joueur humain
func get_current_controlled_player() -> Player:
	for p in squad_away:
		if p.control_scheme == Player.ControlScheme.P1:
			return p
	return null


func set_on_duty_weights() -> void:
	for squad in [squad_away, squad_home]:
		var cpu_players : Array[Player] = squad.filter(
			func (p : Player):
				return p.control_scheme == Player.ControlScheme.CPU and p.role != Player.Role.GOALIE
		)
		# Tri corrigé (on utilise toujours position)
		cpu_players.sort_custom(
			func (p1 : Player, p2 : Player):
				return p1.position.distance_squared_to(ball.position) < p2.position.distance_squared_to(ball.position)
		)
		for i in range(cpu_players.size()):
			cpu_players[i].weight_on_duty_steering = 1 - ease(float(i) / 10.0, 0.1)
