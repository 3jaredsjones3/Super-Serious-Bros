extends CharacterBody2D
class_name BossCharacterBody2D


@export var PLAYER:CharacterBody2D
@onready var SPRITE:AnimatedSprite2D = $Visuals
@export var GRAVITY: float = 260.0


var vulnerable:bool = false
var bossHealth = 10

var attacks = [
	Boss_Turtle_Attack_Charge.new(),
	Boss_Turtle_Attack_Bounce.new()
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	attack_loop()

func random_attack(player):
	var attack = attacks.pick_random()
	await attack.perform_attack(player, self)

func attack_loop() -> void:
	while true:
		
		print("Running attack")
		await random_attack(PLAYER)
		vulnerable = true
		
		var t:= 0.0
		while vulnerable and t < 3:
			await get_tree().process_frame
			t += get_physics_process_delta_time()
		
		vulnerable = false

func ToggleFlipHorizontal(direction:int):
	var lookRight:bool = false if sign(direction) == -1 else true
	SPRITE.flip_h = lookRight
	if (lookRight):
		SPRITE.offset.x = 22
	else:
		SPRITE.offset.x = 0

func FallToGround(momentum_y:float, momentum_x:float = 60):
	var attack_dir := -1
	var bounces := 0
	# attack towards player
	if global_position.x < 0:
		attack_dir = 1
	var fall_velocity := Vector2.ZERO
	fall_velocity.x = momentum_x * attack_dir
	fall_velocity.y = momentum_y

	# limit bounces
	while bounces < 4:
		var delta := get_physics_process_delta_time()
		var touched_floor = false
		var touched_wall = false

		fall_velocity.y += GRAVITY * delta
		var collision := move_and_collide(fall_velocity * delta)
		
		if collision:
			var normal := collision.get_normal()
			# hit floor
			if normal.y < -0.3:
				touched_floor = true
			
			# hit wall
			if abs(normal.x) > 0.3:
				touched_wall = true
		
		if (touched_floor):
			fall_velocity.y *= -0.4
			if (abs(fall_velocity.y) < 15):
				fall_velocity.y = 0
			bounces += 1
		
		if (touched_wall):
			attack_dir *= -1
			fall_velocity.x *= -1
		
		if (fall_velocity.y < -350):
			fall_velocity.y = -350
		
		ToggleFlipHorizontal(sign(fall_velocity.x))
		
		await get_tree().physics_frame

func _physics_process(delta: float) -> void:
	move_and_slide()
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var body := collision.get_collider()
		if (body == PLAYER):
			if vulnerable:
				print("Launched player")
				bossHealth -= 1
				PLAYER.add_velocity_external(Vector2(0, -500))
				vulnerable = false
	if (vulnerable):
		SPRITE.flip_v = true
	else:
		SPRITE.flip_v = false
