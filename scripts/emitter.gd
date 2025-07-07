extends Node2D

const BULLET_SCENE = preload('res://scenes/bullet.tscn')

signal all_bullets_fired

@export var initial_direction: Vector2 = Vector2.LEFT
@export var pause_seconds: float = 0.5
@export var pattern: BulletPattern

@onready var interval_timer = %IntervalTimer
@onready var pause_timer = %PauseTimer
@onready var current_direction: Vector2 = initial_direction

var bullets_shot = 0
var interval: float

func _ready() -> void:
	if not pattern.oneshot:
		interval = pattern.duration / pattern.amount
		interval_timer.wait_time = interval
		interval_timer.one_shot = false
		interval_timer.connect('timeout', do_stagger)
	call_deferred('do_pattern')
	pause_timer.timeout.connect(do_pattern)
	self.connect('all_bullets_fired', on_all_bullets_fired)

func do_pattern():
	if pattern.oneshot:
		call_deferred('do_oneshot')
	else:
		interval_timer.start()

func do_oneshot() -> void:
	for i in range(0, pattern.amount):
		fire_bullet(BULLET_SCENE, pattern.movement)
		current_direction = current_direction.rotated(deg_to_rad(pattern.arc_degrees / (pattern.amount - 1)))
	emit_signal('all_bullets_fired')

func do_stagger() -> void:
	fire_bullet(BULLET_SCENE, pattern.movement)
	if pattern.amount >= 1:
		current_direction = current_direction.rotated(deg_to_rad(pattern.arc_degrees / (pattern.amount -1)))
	bullets_shot += 1
	if bullets_shot >= pattern.amount:
		emit_signal('all_bullets_fired')

func on_all_bullets_fired() -> void:
	bullets_shot = 0
	current_direction = initial_direction
	interval_timer.stop()
	pause_timer.start()

func fire_bullet(scene: PackedScene, mv: BulletMovement) -> Node2D:
	var bullet = scene.instantiate()
	bullet.acceleration = mv.acceleration
	bullet.speed = mv.speed
	bullet.global_position = self.global_position + current_direction * pattern.arc_distance
	bullet.direction = current_direction.rotated(deg_to_rad(pattern.bullet_angle_offset))
	bullet.wave_amp = pattern.movement.wave_amp
	bullet.wave_freq = pattern.movement.wave_freq
	bullet.radial_velocity = pattern.movement.radial_velocity
	bullet.radial_acc = pattern.movement.radial_acc
	get_parent().add_child(bullet)
	return bullet
