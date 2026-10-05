extends Area2D
## Roca disparada por Octorok; daña a Link una vez y luego desaparece.
@export var speed: float = 85.0
@export var damage: int = 1
@export var max_distance: float = 145.0
var direction: Vector2 = Vector2.RIGHT
var start_position: Vector2
var already_hit := false

func _ready() -> void:
    start_position = global_position
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    global_position += direction.normalized() * speed * delta
    if global_position.distance_to(start_position) >= max_distance:
        queue_free()

func _on_body_entered(body: Node2D) -> void:
    if already_hit:
        return
    if body.is_in_group("player") and body.has_method("take_damage"):
        already_hit = true
        body.take_damage(damage, direction.normalized())
        queue_free()
    elif not body.is_in_group("enemies"):
        queue_free()
