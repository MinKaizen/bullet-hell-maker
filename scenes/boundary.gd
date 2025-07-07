extends Area2D

func _ready() -> void:
	self.body_exited.connect(func(body: Node2D):
		body.queue_free()
	)
