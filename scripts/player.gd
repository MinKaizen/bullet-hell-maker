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

# Dash parameters
@export var dash_speed: float = 600.0
@export var dash_min_duration: float = 0.08
@export var dash_decay_duration: float = 0.18
@export var dash_preserved_min_speed: float = 350
@export var dash_cooldown: float = 0.7
@export var dash_max_air_tokens: int = 1

var gravity: float
var max_jump_velocity: float
var coyote_timer: float = 0.0
var bounce_timer: float = 0.0
var facing: int = 1
var dash_preserve_speed_active: bool = false
var dash_preserved_speed: float = 0.0
var dash_decay_rate = (dash_speed - move_speed) / dash_decay_duration
var dash_timer: float = 0.0
var dash_air_tokens: int = dash_max_air_tokens

func _ready() -> void:
	gravity = 2.0 * max_jump_height / (time_to_jump_apex * time_to_jump_apex)
	max_jump_velocity = -gravity * time_to_jump_apex
	dash_air_tokens = dash_max_air_tokens

func _physics_process(delta: float) -> void:
	# update facing from input
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0:
		facing = int(sign(dir))
	if dash_preserved_speed > 0.0:
		dash_preserved_speed = max(dash_preserved_speed - dash_decay_rate * delta / 2, dash_preserved_min_speed)
	if dash_timer > 0.0:
		dash_timer = max(0, dash_timer - delta)
