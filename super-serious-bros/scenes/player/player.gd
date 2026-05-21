extends CharacterBody2D

@export var move_speed: float = 130.0
@export var gravity: float = 900.0
@onready var sprite: AnimatedSprite2D = $Visuals


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")

	velocity.x = input_dir * move_speed

	if not is_on_floor():
		velocity.y += gravity * delta #positive y is down the screen so increasing velocity.y moves us downwards faster
	move_and_slide()

	update_animation(input_dir)


func update_animation(input_dir: float) -> void:
	if input_dir > 0.0:
		sprite.flip_h = false
		play_anim("run")
	elif input_dir < 0.0:
		sprite.flip_h = true
		play_anim("run")
	else:
		play_anim("idle")


func play_anim(anim_name: StringName) -> void:
	if sprite.animation == anim_name:
		return

	sprite.play(anim_name)
