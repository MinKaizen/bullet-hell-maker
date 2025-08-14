extends CharacterBody2D

@export_group("Movement")
@export var speed: float = 300.0
@export var acceleration: float = 2000.0
@export var friction: float = 1000.0

@export_group("Jump")
@export var jump_height: float = 100.0
@export var jump_time_to_peak: float = 0.4
@export var jump_time_to_descent: float = 0.4
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

# Calculated jump variables
var jump_velocity: float
var jump_gravity: float
var fall_gravity: float

# Timers
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false

func _ready():
	# Calculate jump physics based on height and time
	jump_velocity = (2.0 * jump_height) / jump_time_to_peak
	jump_gravity = (2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
	fall_gravity = (2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)

func _physics_process(delta):
	# Update timers
	if was_on_floor and not is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0)
	
	jump_buffer_timer = max(jump_buffer_timer - delta, 0)
	was_on_floor = is_on_floor()
	
	# Handle jump
	if jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0):
		velocity.y = -jump_velocity
		jump_buffer_timer = 0
		coyote_timer = 0
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	
	# Cut jump short when button released
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
	
	# Apply gravity
	var gravity = jump_gravity if velocity.y < 0 else fall_gravity
	velocity.y += gravity * delta
	
	# Handle horizontal movement
	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	move_and_slide()

