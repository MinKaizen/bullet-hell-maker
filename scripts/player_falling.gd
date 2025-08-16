extends State

const PATH_IDLE := "Idle"
const PATH_RUNNING := "Running"
const PATH_JUMPING := "Jumping"
const PATH_FALLING := "Falling"
const PATH_FAST_FALLING := "FastFalling"

var player: Node

func _ready() -> void:
	await owner.ready
	player = owner as Node
	assert(player != null)

var jump_buffer_timer: float 
var should_buffer_jump: bool

func enter(_prev: String, _data := {}) -> void:
	jump_buffer_timer = 0.0
	should_buffer_jump = false

func physics_update(delta: float) -> void:
	# coyote jump
	if Input.is_action_just_pressed("jump") and player.coyote_timer > 0.0:
		finished.emit(PATH_JUMPING)
	
	# jump buffering
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
	player.velocity.y += player.gravity * delta
	player.move_and_slide()
	# transitions
	if Input.is_action_just_pressed("move_down"):
		finished.emit(PATH_FAST_FALLING)
		return
	if player.is_on_floor():
		if jump_buffer_timer > 0.0:
			finished.emit(PATH_JUMPING)
		elif is_equal_approx(dir, 0.0):
			finished.emit(PATH_IDLE)
		else:
			finished.emit(PATH_RUNNING)
		return
