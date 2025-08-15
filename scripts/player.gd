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

# Dash parameters
@export var dash_speed: float = 580.0
@export var dash_time: float = 0.35
@export var dash_cooldown: float = 0.1
@export var post_dash_boost_speed: float = 200.0
@export var post_dash_boost_decay_zero_time: float = 0.1
@export var post_dash_boost_max_time: float = 0.35

var gravity: float
var max_jump_velocity: float
var min_jump_velocity: float

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _gravity_scale_current: float = 1.0
var _bounce_timer: float = 0.0
var _is_fast_falling: bool = false

# Dash state
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_dir: int = 0 # -1 left, 1 right
var _dash_cooldown_timer: float = 0.0
var _post_dash_boost: bool = false
var _post_dash_timer: float = 0.0
var _zero_input_timer: float = 0.0
var _facing: int = 1 # 1 right, -1 left
var _dash_cancel_impulse: float = 0.0
var _ground_preserved_speed_active: bool = false

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
	if input_dir != 0:
		_facing = 1 if input_dir > 0 else -1
	_handle_dash_input(input_dir)
	_apply_horizontal(input_dir, delta)
	_update_gravity_scale(delta)
	_apply_gravity(delta)
	# Detect fast-fall while airborne (downward and increased gravity)
	if not is_on_floor() and not _is_fast_falling and Input.is_action_just_pressed("move_down"):
		_is_fast_falling = true
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
	if _is_dashing:
		# Lock horizontal velocity to dash speed that eases from dash_speed -> move_speed over dash_time
		var t: float = clamp(1.0 - (_dash_timer / dash_time), 0.0, 1.0)
		var current_dash_speed: float = lerp(dash_speed, move_speed, t)
		velocity.x = float(_dash_dir) * current_dash_speed
		# When in air, remove any vertical motion for perfect horizontal dash
		if not is_on_floor():
			velocity.y = 0.0
		# Cancel dash early if opposite direction pressed or (on floor and jump is pressed)
		var opp_pressed := (_dash_dir == 1 and Input.is_action_pressed("move_left")) or (_dash_dir == -1 and Input.is_action_pressed("move_right"))
		if opp_pressed or (is_on_floor() and Input.is_action_just_pressed("jump")):
			_end_dash(true)
			return
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_end_dash(false)
		return
	# Not dashing: optionally apply post-dash ground boost
	var effective_speed := move_speed
	if _post_dash_boost and is_on_floor():
		effective_speed = max(effective_speed, post_dash_boost_speed)
		_post_dash_timer -= delta
		# Track zero-input duration
		if abs(dir) < 0.001:
			_zero_input_timer += delta
		else:
			_zero_input_timer = 0.0
		if _post_dash_timer <= 0.0 or _zero_input_timer >= post_dash_boost_decay_zero_time:
			_post_dash_boost = false
	var target_speed := dir * effective_speed
	# Apply dash cancel/preserved impulse
	if _dash_cancel_impulse != 0.0:
		# If preserved on ground, keep it constant and ignore horizontal accel
		if _ground_preserved_speed_active and is_on_floor():
			velocity.x = _dash_cancel_impulse
		else:
			# Air or non-preserved: decay quickly
			velocity.x = move_toward(velocity.x, target_speed + _dash_cancel_impulse, acceleration * delta)
			_dash_cancel_impulse = move_toward(_dash_cancel_impulse, 0.0, (dash_speed + move_speed) * 5.0 * delta)
			if abs(_dash_cancel_impulse) < 0.01:
				_dash_cancel_impulse = 0.0
	else:
		var speed_diff := target_speed - velocity.x
		var accel := acceleration if abs(target_speed) > 0.0 else deceleration
		var max_change := accel * delta
		# Clamp change toward target for smooth accel/decel
		var change: float = clamp(speed_diff, -max_change, max_change)
		velocity.x += change

func _update_gravity_scale(delta: float) -> void:
	if _is_dashing and not is_on_floor():
		# No gravity effect while air-dashing
		_gravity_scale_current = 0.0
		return
	# Also suppress vertical gravity influence if we have cancel impulse in air to keep it perfectly horizontal
	if _dash_cancel_impulse != 0.0 and not is_on_floor():
		_gravity_scale_current = 0.0
		return
	# While preserving ground speed on floor, use normal gravity handling (no change needed here)
	if is_on_floor():
		_gravity_scale_current = 1.0
		return
	var target := fast_fall_multiplier if _is_fast_falling else 1.0
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
	# Dash cooldown
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer = max(0.0, _dash_cooldown_timer - delta)

func _can_jump() -> bool:
	return is_on_floor() or _coyote_timer > 0.0

func _consume_buffered_jump() -> bool:
	return _jump_buffer_timer > 0.0

func _handle_jumps() -> void:
	# Start jump if buffered and can jump
	if _consume_buffered_jump() and _can_jump():
		# Cancel dash on ground jump; preserve current dash horizontal speed as impulse, do not affect Y here
		var preserved_dash_x := 0.0
		if _is_dashing and is_on_floor():
			# compute current dash x speed before ending
			var t_dash: float = clamp(1.0 - (_dash_timer / dash_time), 0.0, 1.0)
			preserved_dash_x = float(_dash_dir) * lerp(dash_speed, move_speed, t_dash)
			_end_dash(true)
			# ensure the impulse uses preserved x and does not touch Y
			_dash_cancel_impulse = preserved_dash_x
			_ground_preserved_speed_active = true
		# Apply bounce boost if within bounce window (affects only Y)
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
		if _is_fast_falling:
			_bounce_timer = bounce_window_time
		# Clear preserved ground speed upon landing (so it only lasts until next landing after an air cancel)
		_ground_preserved_speed_active = false
		_is_fast_falling = false

func _handle_dash_input(input_dir: float) -> void:
	if _is_dashing:
		return
	if _dash_cooldown_timer > 0.0:
		return
	if Input.is_action_just_pressed("dash"):
		var d := 0
		if input_dir > 0.0:
			d = 1
		elif input_dir < 0.0:
			d = -1
		else:
			# If no input, dash toward facing direction
			d = _facing
		_start_dash(d)

func _start_dash(dir: int) -> void:
	_is_dashing = true
	_dash_dir = sign(dir)
	_dash_timer = dash_time
	_dash_cooldown_timer = dash_cooldown
	_is_fast_falling = false
	# Preserve current vertical velocity but disable gravity in air via _update_gravity_scale
	# Horizontal velocity set in _apply_horizontal
	# When dashing on ground, set up post-dash window to check for boosted run on jump
	if is_on_floor():
		_post_dash_boost = false
		_post_dash_timer = 0.0
		_zero_input_timer = 0.0

func _end_dash(early: bool) -> void:
	# Apply a cancel impulse that fades out quickly when ending early
	if early:
		var t: float = clamp(1.0 - (_dash_timer / dash_time), 0.0, 1.0)
		var current_dash_speed: float = lerp(dash_speed, move_speed, t)
		_dash_cancel_impulse = float(_dash_dir) * current_dash_speed
	else:
		_dash_cancel_impulse = 0.0
	_is_dashing = false
	_dash_timer = 0.0
	# If dash ended while grounded, enable post-dash speed boost only if jump is pressed/buffered shortly after
	if is_on_floor():
		# If jump is already buffered or just pressed now, grant boost immediately
		if _consume_buffered_jump() or Input.is_action_just_pressed("jump"):
			_post_dash_boost = true
			_post_dash_timer = post_dash_boost_max_time
			_zero_input_timer = 0.0
		else:
			# Start a short window during which a jump press will trigger the boost
			_post_dash_boost = false
			_post_dash_timer = post_dash_boost_max_time
			_zero_input_timer = 0.0
	else:
		_post_dash_boost = false
