extends Area2D
## Lanza del Molblin: proyectil pixel-art estable, sin rotación por frame.
@export var speed: float = 24.0
@export var damage: int = 1
@export var max_distance: float = 240.0
var direction: Vector2 = Vector2.RIGHT
var start_position: Vector2
var already_hit: bool = false
var visual_direction: Vector2 = Vector2.INF

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	start_position = global_position
	z_index = 150
	_set_direction_visual()
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta
	_set_direction_visual()
	if global_position.distance_to(start_position) >= max_distance:
		queue_free()

func _set_direction_visual() -> void:
	# Molblin usa direcciones cardinales. No rotamos el sprite en tiempo real:
	# cada dirección tiene su propia imagen pixel-art para evitar shimmering/titileo.
	var d := direction.normalized()
	var cardinal := Vector2.ZERO
	if abs(d.x) > abs(d.y):
		cardinal = Vector2(sign(d.x), 0.0)
	else:
		cardinal = Vector2(0.0, sign(d.y))
	if cardinal == visual_direction:
		return
	visual_direction = cardinal

	if abs(d.x) > abs(d.y):
		if d.x < 0.0:
			sprite.texture = preload("res://AssetsEX/01_Items/Molblin_Spear_Left.png")
		else:
			sprite.texture = preload("res://AssetsEX/01_Items/Molblin_Spear_Right.png")
	else:
		if d.y < 0.0:
			sprite.texture = preload("res://AssetsEX/01_Items/Molblin_Spear_Up.png")
		else:
			sprite.texture = preload("res://AssetsEX/01_Items/Molblin_Spear_Down.png")
	sprite.rotation = 0.0

func _on_body_entered(body: Node2D) -> void:
	if already_hit:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		already_hit = true
		body.take_damage(damage, direction.normalized())
		queue_free()
	elif not body.is_in_group("enemies"):
		queue_free()
