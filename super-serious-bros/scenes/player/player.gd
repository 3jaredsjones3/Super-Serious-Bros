extends CharacterBody2D

@export var move_speed: float = 130.0
@export var gravity: float = 900.0
@onready var sprite: AnimatedSprite2D = $Visuals

@export var fast_fall_multiplier: float = 1.8
@export var jump_velocity: float = -300.0
@export var double_jump_velocity: float = -280.0 #Jump slightly slower on the second upwards jump

var can_double_jump: bool = false

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")

	velocity.x = input_dir * move_speed

	if input_dir > 0.0:
		sprite.flip_h = false
	elif input_dir < 0.0:
		sprite.flip_h = true

	apply_gravity(delta)
	handle_jump()
	move_and_slide()

	update_after_move()
	update_animation()


func apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
		return

	var gravity_multiplier := 1.0

	if Input.is_action_pressed("move_down") and velocity.y > 0.0:
		gravity_multiplier = fast_fall_multiplier

	velocity.y += gravity * gravity_multiplier * delta


func handle_jump() -> void:
	if not Input.is_action_just_pressed("jump"):
		return

	if is_on_floor():
		do_ground_jump()
	elif can_double_jump:
		do_double_jump()


func do_ground_jump() -> void:
	velocity.y = jump_velocity
	can_double_jump = true

		
func do_double_jump() -> void:
	velocity.y = double_jump_velocity
	can_double_jump = false
	play_anim("double_jump")

func update_after_move() -> void:
	if is_on_floor():
		can_double_jump = true

func update_animation() -> void:
	if sprite.animation == "double_jump" and sprite.is_playing():
		return
	
	if not is_on_floor():
		if velocity.y < 0.0:
			play_anim("jump")
		else:
			play_anim("fall")
	elif absf(velocity.x) > 5.0:
		play_anim("run")
	else:
		play_anim("idle")


func play_anim(anim_name: StringName) -> void:
	if sprite.animation == anim_name:
		return

	sprite.play(anim_name)
