class_name BulletPattern extends Resource

@export var movement: BulletMovement

## Duration of the pattern in seconds
@export var duration = 1.0

## Number of bullets to emit
@export var amount = 10

## The size of the arc in degrees when staggering bullets. 0 means all bullets will be shot from the same location without. 360 means it will spread out the bullets in a circle. Values higher than 360 may create interesting results. Use negative numbers to turn anti-clockwise.
@export var arc_degrees = 0.0

## The distance from the origin to the place where you want to spawn bullets
@export var arc_distance = 0

## An angle in degrees to rotate the bullet before launching it. By default the direction of the bullet is the same as the direction of the arc
@export var bullet_angle_offset = 0

## Disables staggering and shoots all bullets at once
@export var oneshot = false
