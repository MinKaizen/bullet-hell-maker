extends CharacterBody2D

@export var move_speed: int = 100
@export var direction: Vector2 = Vector2.LEFT

func _ready() -> void:
	velocity = calculate_velocity(0)

func _physics_process(delta: float) -> void:
	velocity = calculate_velocity(delta)
	move_and_slide()

func calculate_velocity(delta) -> Vector2:
	return direction.normalized() * move_speed
