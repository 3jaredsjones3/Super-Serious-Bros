extends CharacterBody2D

@export var move_speed: float = 130.0
@export var gravity: float = 900.0
@onready var sprite: AnimatedSprite2D = $Visuals

@export var fast_fall_multiplier: float = 1.8
@export var jump_velocity: float = -300.0

var external_vel:Vector2

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")

	velocity.x = input_dir * move_speed

	apply_gravity(delta)
	handle_jump()
	apply_velocity_external()
	move_and_slide()

	update_animation(input_dir)

func add_velocity_external(vel:Vector2):
	external_vel += vel

func apply_velocity_external():
	velocity += external_vel
	external_vel = Vector2.ZERO

func apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
		return

	var gravity_multiplier := 1.0

	if Input.is_action_pressed("move_down") and velocity.y > 0.0:
		gravity_multiplier = fast_fall_multiplier

	velocity.y += gravity * gravity_multiplier * delta


func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity


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
