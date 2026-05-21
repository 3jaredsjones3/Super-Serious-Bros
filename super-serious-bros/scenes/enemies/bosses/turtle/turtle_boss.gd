extends CharacterBody2D

@export var player:CharacterBody2D

var attacks = [
	Boss_Turtle_Attack_Charge.new()
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	attack_loop()

func random_attack(player):
	var attack = attacks.pick_random()
	await attack.perform_attack(player, self)

func attack_loop() -> void:
	while true:
		await random_attack(player)
		#TODO Code to make boss vulnerable here :3

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
