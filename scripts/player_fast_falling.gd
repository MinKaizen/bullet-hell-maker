extends PlayerState

var _ramp: float = 0.0
var jump_buffer_timer: float
var should_buffer_jump: bool

func enter(_prev: String, _data := {}) -> void:
	jump_buffer_timer = 0.0
	should_buffer_jump = false
	_ramp = 0.0

func physics_update(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and not should_buffer_jump:
		should_buffer_jump = true
	if should_buffer_jump and Input.is_action_pressed("jump"):
		jump_buffer_timer = player.jump_buffer_time
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

	# horizontal
	var dir := Input.get_axis("move_left", "move_right")
	player.velocity.x = dir * player.move_speed

	# gravity
	_ramp = min(1.0, _ramp + delta / player.fast_fall_ramp_time)
	var gravity := player.gravity * player.fast_fall_multiplier * _ramp
	player.velocity.y += gravity * delta

	player.move_and_slide()

	# transitions
	if player.is_on_floor():
		player.bounce_timer = player.bounce_window_time
		if jump_buffer_timer > 0.0:
			finished.emit(PATH_JUMPING)
		elif is_equal_approx(dir, 0.0):
			finished.emit(PATH_IDLE)
		else:
			finished.emit(PATH_RUNNING)
