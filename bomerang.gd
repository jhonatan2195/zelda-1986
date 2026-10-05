extends Area2D
## bomerang.gd — Bumerán lanzado por el Lynel.
## Sale hacia el jugador, puede dañarlo una vez y después regresa al Lynel.

@export var OUT_SPEED: float = 16.0
@export var RETURN_SPEED: float = 20.0
@export var MAX_DISTANCE: float = 120.0
@export var RETURN_DISTANCE: float = 6.0
@export var ROTATION_SPEED: float = 75.0

var direction: Vector2 = Vector2.RIGHT
var damage: int = 1
var return_target: Node2D = null
var start_position: Vector2
var has_hit_player: bool = false
var returning: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemy_projectiles")
	monitoring = true
	monitorable = true
	start_position = global_position

func _physics_process(delta: float) -> void:
	if not returning:
		global_position += direction * OUT_SPEED * delta
		if global_position.distance_to(start_position) >= MAX_DISTANCE:
			_begin_return()
	else:
		if not is_instance_valid(return_target):
			queue_free()
			return

		var to_owner := return_target.global_position - global_position
		if to_owner.length() <= RETURN_DISTANCE:
			queue_free()
			return

		global_position += to_owner.normalized() * RETURN_SPEED * delta

	if sprite:
		sprite.rotation += deg_to_rad(ROTATION_SPEED) * delta

func _begin_return() -> void:
	returning = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		if not has_hit_player:
			has_hit_player = true
			body.take_damage(damage, direction.normalized())
		_begin_return()
	elif body != return_target:
		_begin_return()
