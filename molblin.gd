extends CharacterBody2D
## Molblin: patrulla, detecta y persigue a Link, y lanza lanzas a distancia.

@export var IS_RED_VARIANT: bool = false
@export var MAX_HEALTH: int = 3
@export var SPEED_PATROL: float = 18.0
@export var SPEED_CHASE: float = 30.0
@export var DETECTION_RANGE: float = 150.0
@export var THROW_RANGE: float = 135.0
@export var THROW_COOLDOWN: float = 1.8
@export var PROJECTILE_SPEED: float = 24.0
@export var PROJECTILE_DAMAGE: int = 1
@export var PROJECTILE_SCENE: PackedScene

var health: int
var player: Node2D = null
var direction: Vector2 = Vector2.DOWN
var patrol_timer: float = 0.0
var throw_timer: float = 0.6
var hurt_timer: float = 0.0
var dead: bool = false
var rng := RandomNumberGenerator.new()

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var state_timer: Timer = $StateTimer
@onready var ray_up: RayCast2D = $RayCast2D_UP
@onready var ray_down: RayCast2D = $RayCast2D_DOWN
@onready var ray_left: RayCast2D = $RayCast2D_LEFT
@onready var ray_right: RayCast2D = $RayCast2D_RIGHT

func _ready() -> void:
	add_to_group("enemies")
	rng.randomize()
	health = MAX_HEALTH
	throw_timer = rng.randf_range(0.4, 1.0)
	_choose_direction()
	sprite.visible = true
	sprite.modulate = Color.WHITE
	_update_animation()

func _physics_process(delta: float) -> void:
	if dead:
		return
	throw_timer = maxf(0.0, throw_timer - delta)
	if hurt_timer > 0.0:
		hurt_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_instance_valid(player):
		player = null
		var candidate := get_tree().get_first_node_in_group("player")
		if candidate is Node2D and global_position.distance_to(candidate.global_position) <= DETECTION_RANGE:
			player = candidate

	if is_instance_valid(player):
		var to_player: Vector2 = player.global_position - global_position
		var distance := to_player.length()
		if distance > DETECTION_RANGE * 1.5:
			player = null
			_patrol(delta)
		elif distance <= THROW_RANGE:
			direction = _cardinal_direction(to_player)
			velocity = Vector2.ZERO
			if throw_timer <= 0.0:
				_throw_spear(direction)
				throw_timer = THROW_COOLDOWN * (0.8 if IS_RED_VARIANT else 1.0)
		else:
			direction = _cardinal_direction(to_player)
			velocity = direction * SPEED_CHASE * (1.2 if IS_RED_VARIANT else 1.0)
	else:
		_patrol(delta)

	move_and_slide()
	_update_animation()

func _patrol(delta: float) -> void:
	patrol_timer -= delta
	if patrol_timer <= 0.0 or _blocked_in_direction():
		_choose_direction()
		patrol_timer = rng.randf_range(0.8, 2.0)
	velocity = direction * SPEED_PATROL

func _blocked_in_direction() -> bool:
	if direction == Vector2.UP: return ray_up.is_colliding()
	if direction == Vector2.DOWN: return ray_down.is_colliding()
	if direction == Vector2.LEFT: return ray_left.is_colliding()
	return ray_right.is_colliding()

func _choose_direction() -> void:
	var options: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	options.shuffle()
	for option in options:
		direction = option
		if not _blocked_in_direction():
			return
	# Fallback: intenta moverse y vuelve a elegir al detectar colisión.
	direction = options[0]

func _throw_spear(throw_direction: Vector2) -> void:
	if PROJECTILE_SCENE == null:
		push_warning("Molblin: falta asignar PROJECTILE_SCENE.")
		return
	var spear := PROJECTILE_SCENE.instantiate()
	get_parent().add_child(spear)
	spear.global_position = global_position + throw_direction * 18.0
	spear.direction = throw_direction
	spear.speed = PROJECTILE_SPEED * (1.12 if IS_RED_VARIANT else 1.0)
	spear.damage = PROJECTILE_DAMAGE + (1 if IS_RED_VARIANT else 0)
	spear.max_distance = THROW_RANGE + 105.0

func _update_animation() -> void:
	if sprite == null:
		return
	var animation_name := "walk_%s_%s" % ["red" if IS_RED_VARIANT else "blue", _direction_suffix(direction)]
	if sprite.animation != StringName(animation_name):
		sprite.play(animation_name)
	elif not sprite.is_playing():
		sprite.play(animation_name)

func _cardinal_direction(dir: Vector2) -> Vector2:
	if absf(dir.x) > absf(dir.y):
		return Vector2.RIGHT if dir.x >= 0.0 else Vector2.LEFT
	return Vector2.DOWN if dir.y >= 0.0 else Vector2.UP

func _direction_suffix(dir: Vector2) -> String:
	if absf(dir.x) > absf(dir.y):
		return "right" if dir.x >= 0.0 else "left"
	return "down" if dir.y >= 0.0 else "up"

func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	if health <= 0:
		dead = true
		velocity = Vector2.ZERO
		set_physics_process(false)
		queue_free()
		return
	# Sin destello de daño: el Molblin permanece visible y estable al recibir golpes.
	hurt_timer = 0.22
	modulate = Color.WHITE

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player and global_position.distance_to(body.global_position) > DETECTION_RANGE * 1.5:
		player = null
