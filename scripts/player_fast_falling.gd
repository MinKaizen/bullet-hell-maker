extends State

const PATH_IDLE := "Idle"
const PATH_RUNNING := "Running"
const PATH_JUMPING := "Jumping"
const PATH_FALLING := "Falling"
const PATH_FAST_FALLING := "FastFalling"
const PATH_DASH := "Dash"

var player: Node

func _ready() -> void:
	await owner.ready
	player = owner as Node
	assert(player != null)

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

	if Input.is_action_just_pressed("dash") and player.dash_timer == 0.0 and player.dash_air_tokens > 0:
		player.dash_air_tokens -= 1
		var dash_dir := int(sign(Input.get_axis("move_left", "move_right")))
		finished.emit(PATH_DASH, {"dir": dash_dir})
		return
	# horizontal
	var dir := Input.get_axis("move_left", "move_right")
	if player.dash_preserve_speed_active:
		player.velocity.x = dir * player.dash_preserved_speed
	else:
		player.velocity.x = dir * player.move_speed

	# gravity
	_ramp = min(1.0, _ramp + delta / player.fast_fall_ramp_time)
	var gravity: float = player.gravity * player.fast_fall_multiplier * _ramp
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
