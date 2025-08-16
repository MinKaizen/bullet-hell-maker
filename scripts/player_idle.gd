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
	# gravity if falling through floor
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
	player.move_and_slide()
	# transitions
	if not player.is_on_floor():
		finished.emit(PATH_FALLING)
		return
	elif Input.is_action_pressed("jump"):
		finished.emit(PATH_JUMPING)
		return
	elif Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		finished.emit(PATH_RUNNING)
		return
