class_name BulletMovement extends Resource

## Speed
@export var speed: int = 100

## Acceleration. Negative values will cause a boomerang effect, not a damping effect
@export var acceleration: float = 0

## The amplitude of the wave motion. If this or `wave_freq` are 0, no wave motion will be applied
@export_range(0.0, 100.0) var wave_amp: float = 0.0

## The frequency (number of cycles per second) of the wave motion. If this or `wave_amp` are 0, no wave motion will be applied
@export_range(0.0, 5.0) var wave_freq: float = 0.0

## Radial Velocity in Degrees per second
@export_range(-360.0, 360.0, 1.0) var radial_velocity: float = 0.0

## Radial Acceleration in Degrees per second per second
@export_range(-360.0, 360.0, 1.0) var radial_acc: float = 0.0
