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
	fire_normal_bullet()
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
		fire_normal_bullet()
		current_direction = current_direction.rotated(deg_to_rad(arc_degrees / (amount - 1)))
	emit_signal('all_bullets_fired')

func fire_accelerating_bullet(spd: float = 20.0, acc: float = 200.0) -> Node2D:
	var dir = current_direction.rotated(deg_to_rad(bullet_angle_offset))
	var pos = self.global_position + current_direction * arc_distance
	var bullet = fire_bullet(pos, dir, spd, acc)
	return bullet

func fire_normal_bullet() -> Node2D:
	var spd = 100.0
	var acc = 0.0
	var dir = current_direction.rotated(deg_to_rad(bullet_angle_offset))
	var pos = self.global_position + current_direction * arc_distance
	var bullet = fire_bullet(pos, dir, spd, acc)
	return bullet

func fire_wave_bullet() -> Node2D:
	var spd = 0.0
	var acc = 50.0
	var dir = current_direction.rotated(deg_to_rad(bullet_angle_offset))
	var pos = self.global_position + current_direction * arc_distance
	var wave_amp = 100.0
	var wave_freq = 1.0
	var bullet = fire_bullet(pos, dir, spd, acc, wave_amp, wave_freq)
	return bullet

func fire_bullet(
	pos: Vector2,
	dir: Vector2,
	speed: float,
	acc: float,
	wave_amp: float = 0.0,
	wave_freq: float = 0.0) -> Node2D:

	var bullet = BULLET_SCENE.instantiate()
	bullet.acceleration = acc
	bullet.speed = speed
	bullet.global_position = pos
	bullet.direction = dir
	bullet.wave_amp = wave_amp
	bullet.wave_freq = wave_freq
	get_parent().add_child(bullet)
	return bullet
