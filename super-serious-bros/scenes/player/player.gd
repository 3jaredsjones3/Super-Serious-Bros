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
@export var min_wall_jump_horizontal_distance: float = 20.0
@export var jump_buffer_window: float = 0.12


var last_wall_jump_dir: int = 0
var wall_jump_streak: int = 0
var wall_jump_control_timer: float = 0.0
var last_wall_jump_x: float = -999999.0

var can_double_jump: bool = false
var is_wall_sliding: bool = false
var jump_buffer_timer: float = 0.0

func _physics_process(delta: float) -> void:
	update_jump_buffer(delta)
	var input_dir := Input.get_axis("move_left", "move_right")

	if wall_jump_control_timer > 0.0:
		wall_jump_control_timer -= delta
	else:
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

func can_wall_jump(wall_dir: int) -> bool:
	if is_on_floor():
		return false

	if wall_dir == 0:
		return false

	if wall_dir == last_wall_jump_dir: #Can't wall jump off the same wall dir twice in a row
		return false

	if wall_jump_streak > 0:
		var distance_from_last_wall_jump := absf(global_position.x - last_wall_jump_x)
		#This is a guard against wall jumping back and forth in
		# 1) narrow chimneys
		# 2) over the top of a wall against either side (since that would satisfy the wall_dir == last_wall_jump_dir test)
		if distance_from_last_wall_jump < min_wall_jump_horizontal_distance:
			return false

	return true

func handle_jump() -> void:
	
	if jump_buffer_timer <= 0.0:
		return
	
	var wall_dir := get_wall_direction()

	if is_on_floor():
		do_ground_jump()
		jump_buffer_timer = 0.0
		return

	elif can_wall_jump(wall_dir):
		do_wall_jump(wall_dir)
		jump_buffer_timer = 0.0
		return
			
	elif can_double_jump:
		do_double_jump()
		jump_buffer_timer = 0.0
		return


func do_ground_jump() -> void:
	velocity.y = jump_velocity
	can_double_jump = true
	wall_jump_streak = 0
	last_wall_jump_dir = 0

func do_double_jump() -> void:
	velocity.y = double_jump_velocity
	can_double_jump = false
	wall_jump_streak = 0
	play_anim("double_jump")


func do_wall_jump(wall_dir: int) -> void:
	last_wall_jump_x = global_position.x #note down where we are jumping from so can_wall_jump() can check it
	
	velocity.y = wall_jump_velocity
	velocity.x = -wall_dir * wall_jump_push_speed #push away from the wall
	#We'll employ a timer to commit the player to the wall jump direction (no quick dir reversals immediately after wall jump)
	wall_jump_control_timer = wall_jump_control_lock_time 
	
	last_wall_jump_dir = wall_dir
	wall_jump_streak += 1
	
	if wall_jump_streak >= wall_jumps_to_refresh_double_jump:
		can_double_jump = true
	
	is_wall_sliding = false
	play_anim("jump")


func handle_jump_cut() -> void:
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


func update_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_window
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)


func update_after_move() -> void:
	if is_on_floor():
		can_double_jump = true
		wall_jump_streak = 0
		last_wall_jump_dir = 0


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
