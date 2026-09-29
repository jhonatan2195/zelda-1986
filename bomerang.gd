extends Area2D
## bomerang.gd — Bumerán lanzado por el Lynel.
## Vuela por el aire en línea recta hacia la posición del jugador (con un poco de
## sobrepaso), puede dañarlo una vez y luego regresa al Lynel que lo lanzó.
## Se dibuja por encima de todo, girando, con una sombra en el suelo para que
## se note que está en el aire.

@export var OUT_SPEED: float = 150.0
@export var RETURN_SPEED: float = 170.0
@export var MAX_DISTANCE: float = 400.0
@export var MIN_DISTANCE: float = 100.0
@export var OVERSHOOT: float = 50.0        ## cuánto pasa más allá del jugador antes de volver
@export var RETURN_DISTANCE: float = 10.0
@export var ROTATION_SPEED: float = 900.0  ## grados/seg
@export var SHADOW_OFFSET: Vector2 = Vector2(0, 6)

var direction: Vector2 = Vector2.RIGHT
var damage: int = 1
var return_target: Node2D = null
var start_position: Vector2
var travel_distance: float = MAX_DISTANCE
var has_hit_player: bool = false
var returning: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = get_node_or_null("Shadow")


func _ready() -> void:
	add_to_group("enemy_projectiles")
	monitoring = true
	monitorable = true
	start_position = global_position
	if shadow:
		shadow.texture = sprite.texture


## Lanza el bumerán desde `from` hacia `target_pos`. Debe llamarse DESPUÉS de add_child().
func launch(from: Vector2, target_pos: Vector2, owner_node: Node2D, dmg: int) -> void:
	global_position = from
	start_position = from
	return_target = owner_node
	damage = dmg
	var to_target := target_pos - from
	direction = to_target.normalized() if to_target.length() > 0.001 else Vector2.DOWN
	travel_distance = clampf(to_target.length() + OVERSHOOT, MIN_DISTANCE, MAX_DISTANCE)
	returning = false
	has_hit_player = false


func _physics_process(delta: float) -> void:
	if not returning:
		global_position += direction * OUT_SPEED * delta
		if global_position.distance_to(start_position) >= travel_distance:
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
		if shadow:
			shadow.rotation = sprite.rotation


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
