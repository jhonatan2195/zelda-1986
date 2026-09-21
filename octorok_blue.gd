extends CharacterBody2D

#Crear una referencia para las animaciones
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

#Variable para aplicar velocidad al movimiento del personaje
@export var SPEED: float = 40.0

#Referencias a los raycast
@onready var ray_cast_2d_up: RayCast2D = $RayCast2D_UP
@onready var ray_cast_2d_down: RayCast2D = $RayCast2D_DOWN
@onready var ray_cast_2d_left: RayCast2D = $RayCast2D_LEFT
@onready var ray_cast_2d_right: RayCast2D = $RayCast2D_RIGHT

#Crear una variable para veriricar la direccion hacia donde se mueve el enemigo
var direction : Vector2 = Vector2.DOWN

var array_directions : Array = [
	Vector2.UP, 
	Vector2.DOWN, 
	Vector2.LEFT, 
	Vector2.RIGHT
	]
	
#cuando inicie el juego el enemigo elige un direccion
func _ready() -> void:
	direction = array_directions.pick_random()
	
func _physics_process(delta: float) -> void:
	
	#Verificar la direcion hacia donde se mueve
	if direction.x > 0:
		animated_sprite_2d.play("walk_right")
	elif direction.x < 0:
		animated_sprite_2d.play("walk_left")
	elif direction.y < 0:
		animated_sprite_2d.play("walk_up")
	elif direction.y > 0:
		animated_sprite_2d.play("walk_down")
		
	velocity = direction * SPEED
	move_and_slide()
	
#Validar la direccion hacia donde se mueve el enemigo y 
#validar si ha calisionado con un obstaculo o pared

	if direction == Vector2.UP and ray_cast_2d_up.is_colliding():
		change_direction()
	elif direction == Vector2.DOWN and ray_cast_2d_down.is_colliding():
		change_direction() 
	elif direction == Vector2.RIGHT and ray_cast_2d_right.is_colliding():
		change_direction()
	elif direction == Vector2.LEFT and ray_cast_2d_left.is_colliding():
		change_direction()
		
func change_direction()-> void:
	#Necesitamos un arreglo para guardar las rutas disponibles
	var available_directions : Array = []
	
	if not ray_cast_2d_up.is_colliding():
		available_directions.append(Vector2.UP)
	if not ray_cast_2d_down.is_colliding():
		available_directions.append(Vector2.DOWN)
	if not ray_cast_2d_left.is_colliding():
		available_directions.append(Vector2.LEFT)
	if not ray_cast_2d_right.is_colliding():
		available_directions.append(Vector2.RIGHT)
		
		
	#Si llegado el caso el enemigo esta entre 4 apredes entonces que no selecione
	if available_directions.is_empty():
		return

		
	direction = available_directions.pick_random()
	

func _on_timer_timeout() -> void:
	change_direction()
