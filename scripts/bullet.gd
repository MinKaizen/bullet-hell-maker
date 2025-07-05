extends CharacterBody2D

@export var speed: int = 100
@export var direction: Vector2 = Vector2.LEFT
@export var acceleration: float = 0

func _ready() -> void:
	velocity = calculate_velocity(direction * speed, 0)

func _physics_process(delta: float) -> void:
	velocity = calculate_velocity(velocity, delta)
	move_and_slide()

func calculate_velocity(current: Vector2, delta: float) -> Vector2:
	return current + direction.normalized() * acceleration * delta
