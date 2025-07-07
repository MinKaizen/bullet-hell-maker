extends CharacterBody2D

@export var speed: int = 100
@export var direction: Vector2 = Vector2.LEFT
@export var acceleration: float = 0
@export var wave_amp: float = 0.0
@export var wave_freq: float = 0.0
@export var radial_velocity = 0.0 # degrees
@export var radial_acc: float = 0.0 # degrees

var t = 0

@onready var wave_omega = wave_freq * 2 * PI
@onready var current_speed = speed

func _ready() -> void:
	velocity = calculate_velocity(0)

func _physics_process(delta: float) -> void:
	t += delta
	direction = direction.rotated(deg_to_rad(radial_velocity * delta))
	radial_velocity += radial_acc * delta
	current_speed += acceleration * delta
	velocity = calculate_velocity(delta)
	move_and_slide()

func calculate_velocity(_delta: float) -> Vector2:
	var new_velocity = direction * current_speed
	if wave_amp > 0.0 and wave_freq > 0.0:
		var perpendicular = direction.normalized().rotated(PI / 2)
		var sine_velocity = perpendicular * wave_amp * sin(t * wave_omega + PI/2)
		new_velocity += sine_velocity
	return new_velocity

