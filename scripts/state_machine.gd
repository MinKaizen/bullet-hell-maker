class_name StateMachine
extends Node

@export var initial_state: State

@onready var state: State = (func _get_initial() -> State:
	return initial_state if initial_state != null else get_child(0)
).call()

func _ready() -> void:
	for s: State in find_children("*", "State"):
		s.finished.connect(_on_state_finished)
	await owner.ready
	state.enter("")

func _unhandled_input(event: InputEvent) -> void:
	if state:
		state.handle_input(event)

func _process(delta: float) -> void:
	if state:
		state.update(delta)

func _physics_process(delta: float) -> void:
	if state:
		state.physics_update(delta)

func _on_state_finished(target_state_path: String, data: Dictionary = {}) -> void:
	if not has_node(target_state_path):
		printerr(owner.name + ": Missing state: " + target_state_path)
		return
	var prev := state.name
	state.exit()
	state = get_node(target_state_path)
	state.enter(prev, data)
