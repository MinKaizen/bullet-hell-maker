extends CharacterBody2D

# Movement parameters
@export var move_speed: float = 130.0
@export var acceleration: float = 2500.0
@export var deceleration: float = 2000.0

# Jump parameters
@export var max_jump_height: float = 70.0 # pixels
@export var time_to_jump_apex: float = 0.4 # seconds to reach apex on full jump
@export var short_jump_multiplier: float = 0.5
@export var coyote_time: float = 0.15 # seconds after leaving ground where jump allowed
@export var jump_buffer_time: float = 0.15 # seconds to buffer jump before landing

# Fast-fall parameters
@export var fast_fall_multiplier: float = 15.0
@export var fast_fall_ramp_time: float = 0.15

# Bounce parameters (boost next jump after fast-fall landing)
@export var bounce_window_time: float = 0.15
@export var bounce_jump_multiplier: float = 1.35

var gravity: float
var max_jump_velocity: float
var coyote_timer: float = 0.0
var bounce_timer: float = 0.0

func _ready() -> void:
	gravity = 2.0 * max_jump_height / (time_to_jump_apex * time_to_jump_apex)
	max_jump_velocity = -gravity * time_to_jump_apex

func _physics_process(_delta: float) -> void:
	pass
