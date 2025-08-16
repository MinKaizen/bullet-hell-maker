class_name PlayerState
extends State

const PATH_IDLE := "Idle"
const PATH_RUNNING := "Running"
const PATH_JUMPING := "Jumping"
const PATH_FALLING := "Falling"
const PATH_FAST_FALLING := "FastFalling"

var player: Player

func _ready() -> void:
	await owner.ready
	player = owner as Player
	assert(player != null)
