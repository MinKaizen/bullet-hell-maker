extends State

const PATH_IDLE := "Idle"
const PATH_RUNNING := "Running"
const PATH_JUMPING := "Jumping"
const PATH_FALLING := "Falling"
const PATH_FAST_FALLING := "FastFalling"

var player: CharacterBody2D
var dir: int = 1
var t: float = 0.0

func _ready() -> void:
	await owner.ready
	player = owner as CharacterBody2D
	assert(player != null)

func enter(_prev: String, data := {}) -> void:
	player.dash_timer = player.dash_cooldown
	dir = int(sign(data.get("dir", player.facing)))
	if dir == 0:
		dir = player.facing if player.facing != 0 else 1
	player.facing = dir
	t = 0.0
	player.velocity.x = player.dash_speed * dir
	player.velocity.y = 0

func physics_update(delta: float) -> void:
	t += delta
	var vx: float = player.velocity.x
	if t < player.dash_min_duration:
		vx = player.dash_speed * dir
	else:
		var u: float = clamp((t - player.dash_min_duration) / max(0.0001, player.dash_decay_duration), 0.0, 1.0)
		var target: float = lerp(player.dash_speed, player.move_speed, u)
		vx = target * dir
		if is_equal_approx(u, 1.0):
			vx = player.move_speed * dir
			player.velocity.x = vx
			_end_to_default()
			return

	var input_axis: float = Input.get_axis("move_left", "move_right")
	if input_axis != 0 and int(sign(input_axis)) == -dir:
		player.velocity.x = player.move_speed * int(sign(input_axis))
		_end_to_default()
		return

	if player.is_on_floor() and Input.is_action_just_pressed("jump"):
		player.dash_preserve_speed_active = true
		player.dash_preserved_speed = abs(vx)
		player.dash_air_tokens -= 1
		finished.emit(PATH_JUMPING)
		return

	player.velocity.x = vx
	player.move_and_slide()

func _end_to_default() -> void:
	if player.is_on_floor():
		if is_equal_approx(Input.get_axis("move_left", "move_right"), 0.0):
			player.velocity.x = 0
			finished.emit(PATH_IDLE)
		else:
			finished.emit(PATH_RUNNING)
	else:
		if Input.is_action_pressed("move_down"):
			finished.emit(PATH_FAST_FALLING)
		else:
			finished.emit(PATH_FALLING)
