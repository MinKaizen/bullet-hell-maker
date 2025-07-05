extends Node2D

const BULLET_SCENE = preload('res://scenes/bullet.tscn')

signal all_bullets_fired
signal finished

@export var duration = 1.0
@export var amount = 10
@export var arc_start = Vector2.LEFT
@export var arc_degrees = 180.0
@export var arc_distance = 0
@export var arc_anti_clockwise = false
@export var bullet_angle_offset = 0
@export var oneshot = false

@onready var interval_timer = %IntervalTimer
@onready var current_direction: Vector2 = arc_start

var bullets_shot = 0
var interval: float

func _ready() -> void:
	if oneshot:
		call_deferred('do_oneshot')
	else:
		interval = duration / amount
		interval_timer.wait_time = interval
		interval_timer.one_shot = false
		interval_timer.connect('timeout', on_interval)
		interval_timer.start()
		print("interval is %f" % interval)
	
	self.connect('all_bullets_fired', on_all_bullets_fired)

func on_interval() -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.direction = current_direction.rotated(deg_to_rad(bullet_angle_offset))
	bullet.global_position = self.global_position + current_direction * arc_distance
	get_parent().add_child(bullet)
	if amount >= 1:
		current_direction = current_direction.rotated(deg_to_rad(arc_degrees / (amount -1)))
	bullets_shot += 1
	if bullets_shot >= amount:
		emit_signal('all_bullets_fired')

func on_all_bullets_fired() -> void:
	interval_timer.stop()
	print("all bullets fired")
	emit_signal('finished')

func do_oneshot() -> void:
	for i in range(0, amount):
		print(rad_to_deg(current_direction.angle()))
		var bullet = BULLET_SCENE.instantiate()
		bullet.direction = current_direction.rotated(deg_to_rad(bullet_angle_offset))
		print(rad_to_deg(bullet.direction.angle()))
		bullet.global_position = self.global_position + current_direction * arc_distance
		get_parent().add_child(bullet)
		current_direction = current_direction.rotated(deg_to_rad(arc_degrees / (amount - 1)))
	emit_signal('all_bullets_fired')







