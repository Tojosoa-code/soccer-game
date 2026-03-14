class_name Player
extends CharacterBody2D

#region // enum
enum ControlScheme {
	CPU, 
	P1,
	P2
}
#endregion

#region // variable d'exportation
@export var control_scheme : ControlScheme
@export var speed : float
#endregion

#region // variable onready
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var player_sprite: Sprite2D = %PlayerSprite
#endregion

#region // variable standart
var heading : Vector2 = Vector2.RIGHT
#endregion

func _process(_delta: float) -> void:
	if control_scheme == ControlScheme.CPU :
		pass # Mouvement de l'IA
	else :
		handle_human_movement()
	set_movement_animation()
	set_heading()
	flip_sprites()
	move_and_slide()
	
func handle_human_movement() -> void :
	var direction := KeyUtils.get_input_vector(control_scheme)
	velocity = direction * speed
	
func set_movement_animation() -> void :
	if velocity.length() > 0 :
		animation_player.play("run")
	else :
		animation_player.play("idle")
	
func set_heading() -> void :
	if velocity.x > 0 :
		heading = Vector2.RIGHT
	elif  velocity.x < 0 :
		heading = Vector2.LEFT

func flip_sprites() -> void :
	if heading == Vector2.RIGHT :
		player_sprite.flip_h = false
	elif heading == Vector2.LEFT :
		player_sprite.flip_h = true
