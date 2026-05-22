extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var heal_amount: int = 1

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		#body.heal(heal_amount)
		animated_sprite.play("collected")
		await animated_sprite.animation_finished
		queue_free()
