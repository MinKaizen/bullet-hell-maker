class_name PlayerUtils
extends Node

static func input_dir() -> float:
	var d := 0.0
	if Input.is_action_pressed("move_left"): d -= 1.0
	if Input.is_action_pressed("move_right"): d += 1.0
	return d
