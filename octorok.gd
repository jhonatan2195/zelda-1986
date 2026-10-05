extends CharacterBody2D
## Octorok: patrulla, detecta a Link y escupe una roca en línea recta.
@export var IS_RED_VARIANT: bool = false
@export var MAX_HEALTH: int = 2
@export var SPEED_PATROL: float = 16.0
@export var SPEED_CHASE: float = 22.0
@export var DETECTION_RANGE: float = 125.0
@export var THROW_RANGE: float = 105.0
@export var THROW_COOLDOWN: float = 2.0
@export var PROJECTILE_SPEED: float = 85.0
@export var PROJECTILE_DAMAGE: int = 1
@export var PROJECTILE_SCENE: PackedScene

var health: int = 2
var player: Node2D = null
var direction: Vector2 = Vector2.DOWN
var patrol_timer: float = 0.0
var throw_timer: float = 0.8
var hurt_timer: float = 0.0
var dead: bool = false
var rng := RandomNumberGenerator.new()

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_up: RayCast2D = $RayCast2D_UP
@onready var ray_down: RayCast2D = $RayCast2D_DOWN
@onready var ray_left: RayCast2D = $RayCast2D_LEFT
@onready var ray_right: RayCast2D = $RayCast2D_RIGHT

func _ready() -> void:
    add_to_group("enemies")
    rng.randomize()
    health = MAX_HEALTH
    throw_timer = rng.randf_range(0.5, 1.2)
    _choose_direction()
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
        if distance > DETECTION_RANGE * 1.6:
            player = null
            _patrol(delta)
        elif distance <= THROW_RANGE:
            direction = _cardinal_direction(to_player)
            velocity = Vector2.ZERO
            if throw_timer <= 0.0:
                _throw_rock(direction)
                throw_timer = THROW_COOLDOWN * (0.75 if IS_RED_VARIANT else 1.0)
        else:
            direction = _cardinal_direction(to_player)
            velocity = direction * SPEED_CHASE * (1.25 if IS_RED_VARIANT else 1.0)
    else:
        _patrol(delta)

    move_and_slide()
    _update_animation()

func _patrol(delta: float) -> void:
    patrol_timer -= delta
    if patrol_timer <= 0.0 or _blocked_in_direction():
        _choose_direction()
        patrol_timer = rng.randf_range(0.8, 1.8)
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
    direction = Vector2.ZERO

func _cardinal_direction(vector: Vector2) -> Vector2:
    if absf(vector.x) > absf(vector.y):
        return Vector2.RIGHT if vector.x >= 0.0 else Vector2.LEFT
    return Vector2.DOWN if vector.y >= 0.0 else Vector2.UP

func _throw_rock(throw_direction: Vector2) -> void:
    if PROJECTILE_SCENE == null:
        push_warning("Octorok: no hay una escena de roca asignada.")
        return
    var projectile := PROJECTILE_SCENE.instantiate()
    projectile.direction = throw_direction
    projectile.speed = PROJECTILE_SPEED * (1.25 if IS_RED_VARIANT else 1.0)
    projectile.damage = PROJECTILE_DAMAGE * (2 if IS_RED_VARIANT else 1)
    get_tree().current_scene.add_child(projectile)
    projectile.global_position = global_position + throw_direction * 10.0

func _update_animation() -> void:
    var suffix := "down"
    if absf(direction.x) > absf(direction.y):
        suffix = "right" if direction.x > 0.0 else "left"
    elif direction.y < 0.0:
        suffix = "up"
    var variant := "red" if IS_RED_VARIANT else "blue"
    var animation_name := "walk_%s_%s" % [variant, suffix]
    if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_name):
        if sprite.animation != StringName(animation_name):
            sprite.play(animation_name)
        elif not sprite.is_playing():
            sprite.play(animation_name)

func take_damage(amount: int) -> void:
    if dead:
        return
    health -= amount
    if health <= 0:
        dead = true
        velocity = Vector2.ZERO
        queue_free()
        return
    modulate = Color(1.0, 0.55, 0.55)
    hurt_timer = 0.15
    get_tree().create_timer(0.15).timeout.connect(func():
        if is_instance_valid(self) and not dead:
            modulate = Color.WHITE
    )
