extends CharacterBody2D

@export var move_speed: float = 130.0
@export var gravity: float = 900.0
@onready var sprite: AnimatedSprite2D = $Visuals

@onready var wall_check_left: RayCast2D = $WallCheckLeft
@onready var wall_check_right: RayCast2D = $WallCheckRight

@export var fast_fall_multiplier: float = 1.8
@export var jump_velocity: float = -300.0
@export var double_jump_velocity: float = -280.0 #Jump slightly slower on the second upwards jump
@export var jump_cut_multiplier: float = 0.45
@export var wall_slide_speed: float = 55.0

@export var wall_jump_velocity: float = -300.0
@export var wall_jump_push_speed: float = 160.0
@export var wall_jump_control_lock_time: float = 0.12
@export var wall_jumps_to_refresh_double_jump: int = 3

var last_wall_jump_dir: int = 0
var wall_jump_streak: int = 0
var wall_jump_control_timer: float = 0.0

var can_double_jump: bool = false
var is_wall_sliding: bool = false

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")

	if wall_jump_control_timer > 0.0:
		wall_jump_control_timer -= delta
	else:
		velocity.x = input_dir * move_speed

	velocity.x = input_dir * move_speed

	if input_dir > 0.0:
		sprite.flip_h = false
	elif input_dir < 0.0:
		sprite.flip_h = true

	apply_gravity(delta)
	handle_wall_slide(input_dir) #sliding should be handled before jumping so the jump logic can check for it
	handle_jump()
	handle_jump_cut()
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


func handle_jump_cut() -> void:
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


func update_after_move() -> void:
	if is_on_floor():
		can_double_jump = true


func handle_wall_slide(input_dir: float) -> void:
	is_wall_sliding = false #start assuming we're not and make it prove that we are
	
	#If we're on the floor or moving upward, we're not wall sliding
	if is_on_floor() or velocity.y <= 0.0:
		return
	
	var wall_dir: int = get_wall_direction()
	
	#If we're not in contact with a wall, then we're not wall sliding
	if wall_dir == 0:
		return

	#Even if we are in contact with a wall, if we're not pressing against it then we're not wall sliding
	if signf(input_dir) != wall_dir:
		return
	
	#By this point, we're wall sliding and we want to mark that so update_animation() in _physics_process() can see it
	is_wall_sliding = true
	# Let slow falls stay slow, but cap fast falls to wall_slide_speed
	# Note that we already ruled out upwards movement up above
	velocity.y = minf(velocity.y, wall_slide_speed)



func get_wall_direction() -> int:
	if wall_check_left.is_colliding():
		return -1
	if wall_check_right.is_colliding():
		return 1
	
	return 0


func update_animation() -> void:
	if is_wall_sliding:
		play_anim("wall_slide")
		return
	
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
