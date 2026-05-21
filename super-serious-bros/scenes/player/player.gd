extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $Visuals

func _physics_process(delta: float) -> void:
	# movement logic here
	update_animation()

func update_animation() -> void:
	if not is_on_floor():
		if velocity.y < 0.0:
			sprite.play("jump")
		else:
			sprite.play("fall")
	elif absf(velocity.x) > 5.0:
		sprite.play("run")
	else:
		sprite.play("idle")
