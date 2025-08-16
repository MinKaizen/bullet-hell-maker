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

var jump_ended: bool

func enter(_prev: String, _data := {}) -> void:
	player.coyote_timer = 0.0
	jump_ended = false
	# bounce window multiplier support
	if player.bounce_timer > 0.0:
		player.velocity.y = player.max_jump_velocity * player.bounce_jump_multiplier
		player.bounce_timer = 0.0
	else:
		player.velocity.y = player.max_jump_velocity

func physics_update(delta: float) -> void:
	# variable jump height: cut if released
	if not jump_ended and not Input.is_action_pressed("jump"):
		jump_ended = true
		player.velocity.y = player.short_jump_multiplier * player.velocity.y

	# horizontal and gravity
	var dir := Input.get_axis("move_left", "move_right")
	player.velocity.x = dir * player.move_speed
	player.velocity.y += player.gravity * delta
	player.move_and_slide()

	if Input.is_action_just_pressed("move_down"):
		finished.emit(PATH_FAST_FALLING)
		return
	if player.velocity.y >= 0.0:
		finished.emit(PATH_FALLING)
		return
