class_name Player
extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $Visuals

@onready var wall_contact_check_left: RayCast2D = $EnvironmentalSensors/WallContactCheck_Left
@onready var wall_contact_check_right: RayCast2D = $EnvironmentalSensors/WallContactCheck_Right

@onready var wall_jump_check_left: RayCast2D = $EnvironmentalSensors/WallJumpCheck_Left
@onready var wall_jump_check_right: RayCast2D = $EnvironmentalSensors/WallJumpCheck_Right

@onready var ledge_check_left: RayCast2D = $EnvironmentalSensors/LedgeCheck_Left
@onready var ledge_check_right: RayCast2D = $EnvironmentalSensors/LedgeCheck_Right


@export_group("General Movement")

## Horizontal walk speed in pixels per second.
@export var move_speed: float = 130.0

## Horizontal sprint speed in pixels per second while holding sprint.
## Sprint raises the target speed cap; acceleration still controls how quickly we reach it.
@export var sprint_speed: float = 190.0

## How quickly the player reaches target speed while grounded.
@export var ground_acceleration: float = 1200.0

## How quickly the player slows down when no horizontal input is held while grounded.
@export var ground_friction: float = 1600.0

## How quickly the player can steer horizontally while airborne.
@export var air_acceleration: float = 900.0

## How quickly horizontal speed fades with no input while airborne.
@export var air_friction: float = 300.0


@export_group("Falling")

## Downward acceleration applied while airborne.
@export var gravity: float = 900.0

## Multiplies gravity while holding down and falling.
## This stacks on top of the passive fall_gravity_bonus_curve.
@export var fast_fall_multiplier: float = 1.8

## Time in seconds it takes for the fall gravity bonus curve to reach its final value.
@export_range(0.01, 1.0, 0.01, "suffix:s") var fall_gravity_ramp_time: float = 0.35

## Extra gravity multiplier added while falling.
## X is normalized fall time from 0 to 1.
## Y is added on top of the base 1.0 gravity multiplier.
## Example: y = 0.55 means final gravity is 1.55x.
@export var fall_gravity_bonus_curve: Curve

## Maximum normal downward speed.
@export var max_fall_speed: float = 420.0

## Maximum downward speed while actively holding down to fast fall.
@export var max_fast_fall_speed: float = 600.0


@export_group("Jumping")

## Initial upward velocity for a normal ground jump.
@export var jump_velocity: float = -300.0

## Initial upward velocity for the second jump. Usually a bit weaker than ground jump.
@export var double_jump_velocity: float = -280.0

## Multiplier applied to upward velocity when jump is released early. Lower means shorter short-hops.
@export_range(0.0, 1.0, 0.05) var jump_cut_multiplier: float = 0.45

## Time in seconds that a jump input remains valid after being pressed.
@export_range(0.0, 0.3, 0.01, "suffix:s") var jump_buffer_window: float = 0.12


@export_group("Wall Movement")

## Maximum downward speed while sliding on a wall.
@export var wall_slide_speed: float = 55.0

## Initial upward velocity applied by a wall jump.
@export var wall_jump_velocity: float = -300.0

## Horizontal push speed away from the wall during a wall jump.
@export var wall_jump_push_speed: float = 160.0

## Time in seconds before normal horizontal input can override wall-jump push.
@export_range(0.0, 0.5, 0.01, "suffix:s") var wall_jump_control_lock_time: float = 0.12

## Number of consecutive alternating wall jumps required to refresh double jump.
@export_range(1, 10, 1) var wall_jumps_to_refresh_double_jump: int = 3

## Minimum horizontal distance in pixels required between chained wall jumps.
## This helps prevent climbing a single thin wall by bouncing between both sides of it.
@export var min_wall_jump_horizontal_distance: float = 20.0

## Short wall-stick time when the player is neutral or pressing away from the wall.
## This gives a tiny grace pause without making the wall feel sticky.
@export_range(0.0, 0.5, 0.01, "suffix:s") var wall_stick_light_window: float = 0.08

## Longer wall-stick time when the player keeps pressing into the wall.
## This rewards intentional clinging without allowing permanent wall hover.
@export_range(0.0, 0.5, 0.01, "suffix:s") var wall_stick_hold_window: float = 0.18

## Time in seconds after leaving a wall where a wall jump can still be triggered.
@export_range(0.0, 0.3, 0.01, "suffix:s") var wall_coyote_window: float = 0.12


@export_group("Ledge Hang & Climb")

## Time after dropping or jumping from a ledge before the player can grab another ledge.
@export_range(0.0, 0.5, 0.01, "suffix:s") var ledge_regrab_cooldown_window: float = 0.15

## Small downward speed applied when intentionally dropping from a ledge.
@export var ledge_drop_speed: float = 60.0

## Local offset used to place the player on top of the ledge after climbing.
## X moves inward onto the platform. Y moves upward onto the top surface.
@export var ledge_climb_offset: Vector2 = Vector2(14.0, -22.0)

## Time in seconds spent locked in the climb-up state before snapping onto the ledge.
@export_range(0.0, 0.5, 0.01, "suffix:s") var ledge_climb_duration: float = 0.12


var can_double_jump: bool = false
var jump_buffer_timer: float = 0.0

var fall_time: float = 0.0

var wall_jump_streak: int = 0
var wall_jump_control_timer: float = 0.0
var last_wall_jump_x: float = -999999.0

var is_wall_sliding: bool = false
var wall_stick_elapsed: float = 0.0
var last_wall_jump_dir: int = 0

var wall_coyote_timer: float = 0.0
var remembered_wall_dir: int = 0

# Since we only want to start the stick/pause timer when we first touch a wall,
# or when we switch to a different wall side, we remember the last contact direction.
var last_wall_contact_dir: int = 0

var is_ledge_hanging: bool = false
var ledge_hang_dir: int = 0
var ledge_regrab_cooldown_timer: float = 0.0

var is_ledge_climbing: bool = false
var ledge_climb_timer: float = 0.0
var ledge_climb_target_position: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")

	# Ledge climb is a temporary kinematic state.
	# We process it before jump buffering so inputs pressed during the climb lock do not leak out afterward.
	if is_ledge_climbing:
		handle_ledge_climb(delta)
		update_animation(input_dir)
		return

	update_jump_buffer(delta)

	ledge_regrab_cooldown_timer = maxf(ledge_regrab_cooldown_timer - delta, 0.0)

	if is_ledge_hanging:
		handle_ledge_hang()
		move_and_slide()
		update_animation(input_dir)
		return

	update_wall_memory(delta)

	handle_horizontal_movement(input_dir, delta)
	apply_gravity(delta)

	# Wall slide/stick is handled before jump logic so the jump logic can use fresh wall state.
	handle_wall_slide(input_dir, delta)

	handle_jump(input_dir)
	handle_jump_cut()

	# Ledge hang gets checked after jump handling.
	# This prevents ledge hang from stealing a buffered jump that should become a wall jump/double jump.
	if can_start_ledge_hang(input_dir):
		start_ledge_hang()

	move_and_slide()

	update_after_move()

	# Visual facing and animation are updated after movement/state decisions,
	# so they don't lag a frame behind the current wall-slide/wall-jump state.
	update_animation(input_dir)


func handle_horizontal_movement(input_dir: float, delta: float) -> void:
	if wall_jump_control_timer > 0.0:
		wall_jump_control_timer = maxf(wall_jump_control_timer - delta, 0.0)
		return

	var sprint_held := is_sprint_pressed()
	var target_speed := input_dir * (sprint_speed if sprint_held else move_speed)

	var accel_rate := ground_acceleration

	if is_on_floor():
		if is_zero_approx(input_dir):
			accel_rate = ground_friction
		else:
			accel_rate = ground_acceleration
	else:
		if is_zero_approx(input_dir):
			accel_rate = air_friction
		else:
			accel_rate = air_acceleration

	velocity.x = move_toward(velocity.x, target_speed, accel_rate * delta)


func is_sprint_pressed() -> bool:
	# This guard prevents an InputMap error if the sprint action has not been added yet.
	return InputMap.has_action("sprint") and Input.is_action_pressed("sprint")


func apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
		fall_time = 0.0
		return

	if velocity.y <= 0.0:
		fall_time = 0.0
	else:
		fall_time += delta

	var gravity_multiplier := 1.0

	if velocity.y > 0.0 and fall_gravity_bonus_curve != null:
		var t := clampf(fall_time / fall_gravity_ramp_time, 0.0, 1.0)
		gravity_multiplier += fall_gravity_bonus_curve.sample(t)

	if Input.is_action_pressed("move_down") and velocity.y > 0.0:
		gravity_multiplier *= fast_fall_multiplier

	velocity.y += gravity * gravity_multiplier * delta

	var fall_speed_cap := max_fast_fall_speed if Input.is_action_pressed("move_down") else max_fall_speed
	velocity.y = minf(velocity.y, fall_speed_cap)


func handle_jump(input_dir: float) -> void:
	if jump_buffer_timer <= 0.0:
		return

	if is_on_floor():
		do_ground_jump()
		consume_jump_buffer()
		return

	var contact_wall_dir := get_wall_contact_direction()
	var is_wall_coyote_active := wall_coyote_timer > 0.0

	# HARD WALL INTENT:
	# If the player is actually touching a wall, or just barely left one,
	# treat jump as a wall-interaction attempt.
	#
	# If the wall jump is forbidden by our rules, consume the input so it does not
	# accidentally fall through and spend the double jump.
	if contact_wall_dir != 0 or is_wall_coyote_active:
		var effective_wall_dir := contact_wall_dir

		if effective_wall_dir == 0:
			effective_wall_dir = remembered_wall_dir

		if not is_wall_jump_input_allowed(effective_wall_dir, input_dir):
			# Pressing into the wall means cling/slide/hang intent, not wall-jump intent.
			# We still consume the buffered jump so it does not accidentally become a double jump.
			consume_jump_buffer()
			return

		if can_wall_jump(effective_wall_dir):
			do_wall_jump(effective_wall_dir)

		consume_jump_buffer()
		return

	# SOFT WALL INTENT:
	# The longer wall-jump probe rays are just forgiveness rays.
	# They let the player jump a little early when approaching a wall.
	#
	# If a soft-probe wall jump is blocked, we do NOT consume the input here.
	# That lets the player still use a normal double jump instead of being punished
	# for merely being near wall geometry.
	var probe_wall_dir := get_wall_jump_probe_direction()

	if (
		probe_wall_dir != 0
		and is_wall_jump_input_allowed(probe_wall_dir, input_dir)
		and can_wall_jump(probe_wall_dir)
	):
		do_wall_jump(probe_wall_dir)
		consume_jump_buffer()
		return

	if can_double_jump:
		do_double_jump()
		consume_jump_buffer()
		return


func is_wall_jump_input_allowed(wall_dir: int, input_dir: float) -> bool:
	if wall_dir == 0:
		return false

	var input_sign := int(signf(input_dir))

	# Neutral jump is allowed as a forgiveness option.
	# This lets a player press jump without a perfectly timed away input.
	if input_sign == 0:
		return true

	# wall_dir is the side the wall is on:
	#   -1 = wall is to the left
	#    1 = wall is to the right
	#
	# To wall jump, input should point away from that wall.
	# Pressing into the wall should keep the player sliding/hanging instead.
	return input_sign == -wall_dir


func do_ground_jump() -> void:
	velocity.y = jump_velocity
	can_double_jump = true

	# Touching the ground resets wall-jump history.
	wall_jump_streak = 0
	last_wall_jump_dir = 0


func do_double_jump() -> void:
	velocity.y = double_jump_velocity
	can_double_jump = false

	# A double jump interrupts the wall-jump chain.
	wall_jump_streak = 0

	play_anim("double_jump")


func handle_jump_cut() -> void:
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


func handle_wall_slide(input_dir: float, delta: float) -> void:
	is_wall_sliding = false # Start assuming we're not and make the current frame prove that we are.

	# If we're on the floor or moving upward, we're not wall sliding.
	if is_on_floor() or velocity.y <= 0.0:
		wall_stick_elapsed = 0.0
		last_wall_contact_dir = 0
		return

	var wall_dir: int = get_wall_contact_direction()

	# If we're not in actual contact with a wall, then we're not wall sliding.
	# This uses the short contact rays, not the longer wall-jump forgiveness rays.
	if wall_dir == 0:
		wall_stick_elapsed = 0.0
		last_wall_contact_dir = 0
		return

	# We intentionally do NOT require the player to keep pressing into the wall.
	# Once contact is real, the player can press away to prepare a wall jump
	# without instantly dropping the wall-slide state.
	#
	# This only feels right if WallContactCheck_* rays are short.
	# Long contact rays would make the wall feel magnetic.
	if wall_dir != last_wall_contact_dir:
		wall_stick_elapsed = 0.0
		last_wall_contact_dir = wall_dir

	# By this point, we're wall sliding and we want to mark that so update_animation() can see it.
	is_wall_sliding = true

	var input_sign := int(signf(input_dir))
	var pressing_into_wall := input_sign == wall_dir

	# Pressing into the wall means "cling a bit longer."
	# Neutral or pressing away means "give only a small grace pause, then slide."
	var allowed_stick_time := wall_stick_hold_window if pressing_into_wall else wall_stick_light_window

	if wall_stick_elapsed < allowed_stick_time:
		wall_stick_elapsed += delta
		velocity.y = 0.0
	else:
		# Let slow falls stay slow, but cap fast falls to wall_slide_speed.
		# Note that we already ruled out upward movement above.
		velocity.y = minf(velocity.y, wall_slide_speed)


func can_start_ledge_hang(input_dir: float) -> bool:
	# Ledge hanging is an intentional action, not an automatic sticky-wall state.
	if not is_ledge_grab_pressed():
		return false

	if is_on_floor():
		return false

	if velocity.y < 0.0:
		return false

	if jump_buffer_timer > 0.0:
		return false

	if wall_jump_control_timer > 0.0:
		return false

	if ledge_regrab_cooldown_timer > 0.0:
		return false

	if Input.is_action_pressed("move_down"):
		return false

	var wall_dir := get_wall_contact_direction()

	if wall_dir == 0:
		return false

	# Only grab ledges from real wall interaction, not from vague nearby geometry.
	# This prevents the player from freezing in mid-air just because a ray barely sees a wall.
	if not is_wall_sliding:
		return false

	# To start a ledge grab, require the player to be pressing into the wall.
	# After the grab starts, handle_ledge_hang() can keep them there without input.
	if signf(input_dir) != wall_dir:
		return false

	if not is_ledge_clear(wall_dir):
		return false

	return true


func start_ledge_hang() -> void:
	is_ledge_hanging = true
	ledge_hang_dir = get_wall_contact_direction()

	velocity = Vector2.ZERO
	fall_time = 0.0

	is_wall_sliding = false
	wall_stick_elapsed = 0.0
	last_wall_contact_dir = 0

	# Consume any leftover jump buffer so a stale jump does not immediately fire from the hang.
	consume_jump_buffer()


func handle_ledge_hang() -> void:
	velocity = Vector2.ZERO
	fall_time = 0.0

	if Input.is_action_just_pressed("move_down"):
		stop_ledge_hang()
		velocity.y = ledge_drop_speed
		return

	if is_ledge_grab_pressed():
		try_start_ledge_climb()
		return

	if jump_buffer_timer > 0.0:
		var wall_dir := ledge_hang_dir
		stop_ledge_hang()
		do_wall_jump(wall_dir)
		consume_jump_buffer()
		return


func stop_ledge_hang() -> void:
	is_ledge_hanging = false
	ledge_hang_dir = 0
	ledge_regrab_cooldown_timer = ledge_regrab_cooldown_window


func is_ledge_grab_pressed() -> bool:
	return InputMap.has_action("ledge_grab") and Input.is_action_just_pressed("ledge_grab")


func try_start_ledge_climb() -> void:
	var climb_offset := get_ledge_climb_offset()

	if is_ledge_climb_path_blocked(climb_offset):
		return

	is_ledge_climbing = true
	is_ledge_hanging = false

	ledge_climb_timer = ledge_climb_duration
	ledge_climb_target_position = global_position + climb_offset

	velocity = Vector2.ZERO
	fall_time = 0.0

	# Avoid stale jump/climb inputs leaking into the next state.
	consume_jump_buffer()


func get_ledge_climb_offset() -> Vector2:
	var climb_offset := ledge_climb_offset

	if ledge_hang_dir == -1:
		climb_offset.x = -absf(ledge_climb_offset.x)
	else:
		climb_offset.x = absf(ledge_climb_offset.x)

	return climb_offset


func is_ledge_climb_path_blocked(climb_offset: Vector2) -> bool:
	var vertical_motion := Vector2(0.0, climb_offset.y)
	var horizontal_motion := Vector2(climb_offset.x, 0.0)

	# Test the climb as an L-shaped path instead of a diagonal sweep.
	# A diagonal test can falsely collide with the ledge corner even when the final spot is valid.
	if test_move(global_transform, vertical_motion):
		return true

	var after_vertical_transform := global_transform.translated(vertical_motion)

	if test_move(after_vertical_transform, horizontal_motion):
		return true

	return false


func handle_ledge_climb(delta: float) -> void:
	velocity = Vector2.ZERO
	fall_time = 0.0

	ledge_climb_timer = maxf(ledge_climb_timer - delta, 0.0)

	if ledge_climb_timer > 0.0:
		return

	var climb_offset := ledge_climb_target_position - global_position

	# Re-test right before snapping in case something moved into the target space during the climb lock.
	if is_ledge_climb_path_blocked(climb_offset):
		cancel_ledge_climb_to_hang()
		return

	global_position = ledge_climb_target_position
	is_ledge_climbing = false
	ledge_hang_dir = 0
	ledge_regrab_cooldown_timer = ledge_regrab_cooldown_window
	velocity = Vector2.ZERO
	consume_jump_buffer()


func cancel_ledge_climb_to_hang() -> void:
	is_ledge_climbing = false
	is_ledge_hanging = true
	velocity = Vector2.ZERO
	fall_time = 0.0
	consume_jump_buffer()


func is_ledge_clear(wall_dir: int) -> bool:
	if wall_dir == -1:
		return not ledge_check_left.is_colliding()

	if wall_dir == 1:
		return not ledge_check_right.is_colliding()

	return false


func do_wall_jump(wall_dir: int) -> void:
	last_wall_jump_x = global_position.x # Note down where we are jumping from so can_wall_jump() can check it.

	velocity.y = wall_jump_velocity
	velocity.x = -wall_dir * wall_jump_push_speed # Push away from the wall.

	# Commit the player to the wall-jump direction for a tiny moment.
	# Without this, normal horizontal input can overwrite the wall jump immediately.
	wall_jump_control_timer = wall_jump_control_lock_time

	last_wall_jump_dir = wall_dir
	wall_jump_streak += 1

	if wall_jump_streak >= wall_jumps_to_refresh_double_jump:
		can_double_jump = true

	# Clear wall-memory state after a successful wall jump so stale wall data
	# does not accidentally trigger another wall interaction.
	wall_coyote_timer = 0.0
	remembered_wall_dir = 0
	wall_stick_elapsed = 0.0
	last_wall_contact_dir = 0

	is_wall_sliding = false
	play_anim("jump")


func update_wall_memory(delta: float) -> void:
	var contact_wall_dir := get_wall_contact_direction()

	if is_on_floor():
		wall_coyote_timer = 0.0
		remembered_wall_dir = 0
		return

	if contact_wall_dir != 0:
		remembered_wall_dir = contact_wall_dir
		wall_coyote_timer = wall_coyote_window
	else:
		wall_coyote_timer = maxf(wall_coyote_timer - delta, 0.0)

		if wall_coyote_timer <= 0.0:
			remembered_wall_dir = 0


func can_wall_jump(wall_dir: int) -> bool:
	if is_on_floor():
		return false

	if wall_dir == 0:
		return false

	if wall_dir == last_wall_jump_dir: # Can't wall jump off the same wall direction twice in a row.
		return false

	if wall_jump_streak > 0:
		var distance_from_last_wall_jump := absf(global_position.x - last_wall_jump_x)

		# This is a guard against wall jumping back and forth in:
		# 1) narrow chimneys
		# 2) over the top of a thin wall against either side
		#
		# Direction alone would allow some thin-wall cheese because the player could touch
		# the left side, then quickly touch the right side of the same narrow wall.
		if distance_from_last_wall_jump < min_wall_jump_horizontal_distance:
			return false

	return true


func get_wall_contact_direction() -> int:
	if wall_contact_check_left.is_colliding():
		return -1

	if wall_contact_check_right.is_colliding():
		return 1

	return 0


# The idea is that we probe a bit farther to allow the player to respond to
# anticipated wall jumps in a sequence a bit early.
#
# These are not used for wall sliding. They are only for wall-jump forgiveness.
func get_wall_jump_probe_direction() -> int:
	var left_hit := wall_jump_check_left.is_colliding()
	var right_hit := wall_jump_check_right.is_colliding()

	if left_hit and not right_hit:
		return -1

	if right_hit and not left_hit:
		return 1

	if left_hit and right_hit:
		# In a narrow gap, prefer the wall opposite the last wall jump.
		if last_wall_jump_dir == -1:
			return 1

		if last_wall_jump_dir == 1:
			return -1

	return 0


func update_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_window
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)


func consume_jump_buffer() -> void:
	jump_buffer_timer = 0.0


func update_after_move() -> void:
	if is_on_floor():
		can_double_jump = true
		wall_jump_streak = 0
		last_wall_jump_dir = 0


func update_animation(input_dir: float) -> void:
	# First resolve sprite direction.
	# Wall states override raw input so the character does not visually flicker
	# when the player presses away from a wall to prepare a wall jump.
	if is_ledge_climbing:
		# Face into the wall while climbing a ledge.
		sprite.flip_h = (ledge_hang_dir == -1)

	elif is_ledge_hanging:
		# Face into the wall while hanging from a ledge.
		sprite.flip_h = (ledge_hang_dir == -1)

	elif is_wall_sliding:
		# Face into the wall while sliding.
		# wall_dir -1 means wall is on the left, so flip_h should be true.
		sprite.flip_h = (get_wall_contact_direction() == -1)

	elif wall_jump_control_timer > 0.0:
		# Face away from the wall during the locked wall-jump push.
		# If the wall was on the right, face left. If it was on the left, face right.
		sprite.flip_h = (last_wall_jump_dir == 1)

	else:
		if input_dir > 0.0:
			sprite.flip_h = false
		elif input_dir < 0.0:
			sprite.flip_h = true

	# Then resolve animation playback.
	if is_ledge_climbing:
		play_anim("wall_slide") # Temporary until we have "ledge_climb".
		return

	if is_ledge_hanging:
		play_anim("wall_slide") # Temporary until we have "ledge_hang".
		return

	if is_wall_sliding:
		play_anim("wall_slide")
		return

	# Keep the non-looping double jump animation from being immediately overwritten.
	# Make sure the double_jump animation does not loop, or this will hold too long.
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
