extends Boss_Attack_Template
class_name Boss_Turtle_Attack_Charge

@export var CHARGE_SPEED = 10
@export var BOUNCES_LIMIT = 3
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func perform_attack(player:Node2D, this:CharacterBody2D) -> void:
	var attackDir = -1
	var bounces = 0
	if player.global_position.x > this.global_position.x:
		attackDir = 1
	while bounces < BOUNCES_LIMIT:
		this.velocity.x += CHARGE_SPEED * attackDir
		this.move_and_slide()
		if (this.is_on_wall()):
			bounces += 1
			attackDir *= -1
		await this.get_tree().physics_frame
