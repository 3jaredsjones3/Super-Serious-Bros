extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $Visuals


func _physics_process(_delta: float) -> void:
	debug_animation_input()


func debug_animation_input() -> void:
	if Input.is_action_pressed("move_right"):
		play_anim("run")
		sprite.flip_h = false
		print_debug("Playing run, facing right")

	elif Input.is_action_pressed("move_left"):
		play_anim("double_jump")
		sprite.flip_h = true
		print_debug("Playing double_jump, facing left")

	else:
		play_anim("idle")
		print_debug("Playing idle")


func play_anim(anim_name: StringName) -> void:
	if sprite.animation == anim_name:
		return

	sprite.play(anim_name)
