
extends CharacterBody2D
 
# ===================== FASE 1: valores base =====================
@export var SPEED_PATROL: float = 25.0
@export var SPEED_CHASE: float = 45.0
@export var CHARGE_SPEED: float = 110.0
@export var DETECTION_RANGE: float = 90.0
@export var ATTACK_RANGE: float = 20.0
@export var WINDUP_TIME: float = 0.4
@export var CHARGE_DURATION: float = 0.5
@export var CHARGE_COOLDOWN: float = 1.0
 
# ===================== FASE 2: enfurecido =====================
@export var ENRAGE_HEALTH_RATIO: float = 0.5   # Se enfurece por debajo del 50% de vida
@export var ENRAGE_SPEED_MULTIPLIER: float = 1.6
@export var ENRAGE_WINDUP_TIME: float = 0.15
@export var MAX_HEALTH: int = 6


var health: int
var invulnerable: bool = false

enum State { PATROL, CHASE, WINDUP, CHARGE, COOLDOWN, HURT, DEAD }
var state: State = State.PATROL
var is_enraged: bool = false
 
var player: Node2D = null
var direction: Vector2 = Vector2.DOWN
var array_directions: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
 
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var state_timer: Timer = $StateTimer
@onready var ray_up: RayCast2D = $RayCast2D_UP
@onready var ray_down: RayCast2D = $RayCast2D_DOWN
@onready var ray_left: RayCast2D = $RayCast2D_LEFT
@onready var ray_right: RayCast2D = $RayCast2D_RIGHT
 
 
func _ready() -> void:
	add_to_group("player")
	add_to_group("enemies")
	health = MAX_HEALTH
	direction = array_directions.pick_random()
	attack_shape.disabled = true # El hitbox de embestida solo se activa durante CHARGE
 	
 
func _physics_process(_delta: float) -> void:
	match state:
		State.PATROL:
			_process_patrol()
		State.CHASE:
			_process_chase()
		State.WINDUP, State.COOLDOWN, State.HURT, State.DEAD:
			velocity = Vector2.ZERO
		State.CHARGE:
			velocity = direction * CHARGE_SPEED
 
	move_and_slide()
	_update_animation()
 
 
# ---------- PATRULLA: misma lógica de evasión de obstáculos que octorok.gd ----------
func _process_patrol() -> void:
	velocity = direction * SPEED_PATROL
 
	if direction == Vector2.UP and ray_up.is_colliding():
		_change_wander_direction()
	elif direction == Vector2.DOWN and ray_down.is_colliding():
		_change_wander_direction()
	elif direction == Vector2.LEFT and ray_left.is_colliding():
		_change_wander_direction()
	elif direction == Vector2.RIGHT and ray_right.is_colliding():
		_change_wander_direction()
 
func _change_wander_direction() -> void:
	var available: Array = []
	if not ray_up.is_colliding():
		available.append(Vector2.UP)
	if not ray_down.is_colliding():
		available.append(Vector2.DOWN)
	if not ray_left.is_colliding():
		available.append(Vector2.LEFT)
	if not ray_right.is_colliding():
		available.append(Vector2.RIGHT)
	if available.is_empty():
		return
	direction = available.pick_random()
 
 
# ---------- PERSECUCIÓN: se activa cuando el jugador entra en DetectionArea ----------
func _process_chase() -> void:
	if player == null:
		state = State.PATROL
		return
 
	var to_player: Vector2 = player.global_position - global_position
	direction = to_player.normalized()
 
	var speed = SPEED_CHASE * (ENRAGE_SPEED_MULTIPLIER if is_enraged else 1.0)
	velocity = direction * speed
 
	if to_player.length() <= ATTACK_RANGE:
		_start_windup()
 
 
# ---------- SECUENCIA DE ATAQUE: AVISO (windup) -> EMBISTE (charge) -> ENFRIAMIENTO ----------
func _start_windup() -> void:
	state = State.WINDUP
	animated_sprite_2d.play("charge_%s" % _direction_to_suffix(direction))
	state_timer.wait_time = ENRAGE_WINDUP_TIME if is_enraged else WINDUP_TIME
	state_timer.start()
 
func _on_state_timer_timeout() -> void:
	match state:
		State.WINDUP:
			state = State.CHARGE
			attack_shape.disabled = false
			state_timer.wait_time = CHARGE_DURATION
			state_timer.start()
		State.CHARGE:
			attack_shape.disabled = true
			state = State.COOLDOWN
			state_timer.wait_time = CHARGE_COOLDOWN
			state_timer.start()
		State.COOLDOWN:
			state = State.CHASE if player != null else State.PATROL
		State.HURT:
			state = State.CHASE if player != null else State.PATROL
 
 
func _direction_to_suffix(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	return "down" if dir.y > 0 else "up"
 
func _update_animation() -> void:
	if state in [State.WINDUP, State.CHARGE, State.HURT, State.DEAD]:
		return # Esas animaciones ya se disparan en sus propias funciones
	animated_sprite_2d.play("walk_%s" % _direction_to_suffix(direction))
 
 
# ---------- DETECCIÓN DEL JUGADOR (Area2D DetectionArea) ----------
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and state == State.PATROL:
		player = body
		state = State.CHASE
 
func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		if state == State.CHASE:
			state = State.PATROL
 
 
# ---------- RECIBIR DAÑO (llamado por el SwordHitbox de Link) ----------
func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
 
	health -= amount
	if health <= 0:
		_die()
		return
 
	state = State.HURT
	animated_sprite_2d.play("hurt_%s" % _direction_to_suffix(direction))
	state_timer.wait_time = 0.3
	state_timer.start()
 
	if not is_enraged and float(health) / float(MAX_HEALTH) <= ENRAGE_HEALTH_RATIO:
		_enter_enraged_phase()
 
func _enter_enraged_phase() -> void:
	is_enraged = true
	modulate = Color(1.0, 0.55, 0.55) # Tinte rojo: retroalimentación visual de la fase 2
	print("Lynel enfurecido: fase 2 activada")
 
func _die() -> void:
	state = State.DEAD
	attack_shape.disabled = true
	animated_sprite_2d.play("death")
	await animated_sprite_2d.animation_finished
	queue_free()
 
