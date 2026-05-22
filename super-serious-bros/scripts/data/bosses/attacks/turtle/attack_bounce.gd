extends Boss_Attack_Template
class_name Boss_Turtle_Attack_Bounce

@export var CHARGE_SPEED = 60
@export var BOUNCES_LIMIT = 8
@export var GRAVITY: float = 260.0

func _ready() -> void:
	pass


func perform_attack(player: Node2D, this:BossCharacterBody2D) -> void:
	var attack_dir := -1
	var bounces := 0
	# attack towards player
	if player.global_position.x > this.global_position.x:
		attack_dir = 1
	var velocity := Vector2.ZERO
	velocity.x = CHARGE_SPEED
	velocity.y = -300

	# limit bounces
	while bounces < BOUNCES_LIMIT:
		var delta := this.get_physics_process_delta_time()
		var touched_floor = false
		var touched_wall = false

		velocity.y += GRAVITY * delta
		var collision := this.move_and_collide(velocity * delta)
		
		if collision:
			var normal := collision.get_normal()
			# hit floor
			if normal.y < -0.3:
				touched_floor = true
			
			# hit wall
			if abs(normal.x) > 0.3:
				touched_wall = true
		
		if (touched_floor):
			velocity.y *= -1
			bounces += 1
			if (abs(velocity.y) < 25):
				velocity.y = 0
		
		if (touched_wall):
			bounces += 1
			attack_dir *= -1
			velocity.x *= -1
		
		if (velocity.y < -200):
			velocity.y = -200
		
		this.toggle_flip_horizontal(sign(velocity.x))
		
		await this.get_tree().physics_frame
	this.vulnerable = true
	await this.fall_to_ground(velocity.y)
