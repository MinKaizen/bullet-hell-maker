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

func enter(_prev: String, _data := {}) -> void:
	player.coyote_timer = player.coyote_time

func physics_update(delta: float) -> void:
	player.bounce_timer = max(0, player.bounce_timer - delta)
	var dir := Input.get_axis("move_left", "move_right")
	var speed = abs(player.velocity.x)
	if dir != 0.0:
		speed = min(speed + player.acceleration * delta, player.move_speed)
	else:
		speed = max(speed - player.deceleration * delta, 0)
	player.velocity.x = dir * speed
	player.move_and_slide()

	if not player.is_on_floor():
		finished.emit(PATH_FALLING)
		return
	if Input.is_action_just_pressed("jump"):
		finished.emit(PATH_JUMPING)
		return
	if is_equal_approx(dir, 0.0):
		finished.emit(PATH_IDLE)
		return
