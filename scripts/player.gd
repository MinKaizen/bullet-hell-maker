extends CharacterBody2D

@export var move_speed: float = 130.0
@export var acceleration: float = 2500.0
@export var deceleration: float = 2000.0

# Jump parameters
@export var max_jump_height: float = 70.0 # pixels
@export var min_jump_height: float = 20.0 # pixels (tap)
@export var time_to_jump_apex: float = 0.4 # seconds to reach apex on full jump
@export var coyote_time: float = 0.2 # seconds after leaving ground where jump allowed
@export var jump_buffer_time: float = 0.2 # seconds to buffer jump before landing

# Fast-fall parameters
@export var fast_fall_multiplier: float = 15.0
@export var fast_fall_ramp_time: float = 0.15

# Bounce parameters (boost next jump after fast-fall landing)
@export var bounce_window_time: float = 0.15
@export var bounce_jump_multiplier: float = 1.3

var gravity: float
var max_jump_velocity: float
var min_jump_velocity: float

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _gravity_scale_current: float = 1.0
var _bounce_timer: float = 0.0
var _was_fast_falling: bool = false

func _ready() -> void:
	# Compute gravity from desired apex time and height using kinematics: v = g * t, h = 0.5 * g * t^2
	# For a smooth projectile, gravity is constant. We derive g such that height at apex equals max_jump_height.
	# h = 0.5 * g * t^2  => g = 2h / t^2
	gravity = 2.0 * max_jump_height / (time_to_jump_apex * time_to_jump_apex)
	print("gravity: %f" % gravity)
	print("time_to_jump_apex: %f" % time_to_jump_apex)
	# Up is negative y in Godot 2D
	max_jump_velocity = -gravity * time_to_jump_apex
	# min jump uses same gravity; compute velocity needed to reach min height: v^2 = 2gh -> v = -sqrt(2*g*h)
	min_jump_velocity = -sqrt(2.0 * gravity * min_jump_height)

func _physics_process(delta: float) -> void:
	_handle_timers(delta)
	var input_dir := _get_input_direction()
	_apply_horizontal(input_dir, delta)
	_update_gravity_scale(delta)
	_apply_gravity(delta)
	# Detect fast-fall while airborne (downward and increased gravity)
	if not is_on_floor() and not _was_fast_falling and Input.is_action_just_pressed("move_down"):
		_was_fast_falling = true
	_handle_jumps()
	move_and_slide()
	_after_move()

func _get_input_direction() -> float:
	var dir := 0.0
	if Input.is_action_pressed("move_left"):
		dir -= 1.0
	if Input.is_action_pressed("move_right"):
		dir += 1.0
	return dir

func _apply_horizontal(dir: float, delta: float) -> void:
	var target_speed := dir * move_speed
	var speed_diff := target_speed - velocity.x
	var accel := acceleration if abs(target_speed) > 0.0 else deceleration
	var max_change := accel * delta
	# Clamp change toward target for smooth accel/decel
	var change: float = clamp(speed_diff, -max_change, max_change)
	velocity.x += change

func _update_gravity_scale(delta: float) -> void:
	if is_on_floor():
		_gravity_scale_current = 1.0
		return
	var target := fast_fall_multiplier if _was_fast_falling else 1.0
	var t: float = 1.0 if fast_fall_ramp_time <= 0.0 else min(1.0, delta / fast_fall_ramp_time)
	_gravity_scale_current = lerp(_gravity_scale_current, target, t)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * _gravity_scale_current * delta
	else:
		# Ensure we don't accumulate tiny residuals on ground
		if velocity.y > 0:
			velocity.y = 0

func _handle_timers(delta: float) -> void:
	# Coyote time refresh when grounded
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = max(0.0, _coyote_timer - delta)
	# Jump buffer timer counts down
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer = max(0.0, _jump_buffer_timer - delta)
	# Bounce timer counts down
	if _bounce_timer > 0.0:
		_bounce_timer = max(0.0, _bounce_timer - delta)
	# Check for jump press to buffer
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time

func _can_jump() -> bool:
	return is_on_floor() or _coyote_timer > 0.0

func _consume_buffered_jump() -> bool:
	return _jump_buffer_timer > 0.0

func _handle_jumps() -> void:
	# Start jump if buffered and can jump
	if _consume_buffered_jump() and _can_jump():
		# Apply bounce boost if within bounce window
		if _bounce_timer > 0.0:
			velocity.y = max_jump_velocity * bounce_jump_multiplier
			_bounce_timer = 0.0
		else:
			velocity.y = max_jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
	# Variable jump height: when jump released, apply cut to reach min height
	if velocity.y < 0.0 and Input.is_action_just_released("jump"):
		# If current upward velocity is stronger than min jump, reduce to min
		if velocity.y < min_jump_velocity:
			velocity.y = min_jump_velocity

func _after_move() -> void:
	# If we hit the ceiling, stop upward velocity
	if is_on_ceiling() and velocity.y < 0.0:
		velocity.y = 0.0
		# Reset gravity scale when hitting ceiling as well
		_gravity_scale_current = 1.0
	# If we landed this frame, start bounce window if fast-falling before
	if is_on_floor():
		if _was_fast_falling:
			_bounce_timer = bounce_window_time
		_was_fast_falling = false
