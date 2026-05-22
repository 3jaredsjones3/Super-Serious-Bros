extends Control

@onready var strawberry_amount: Label = $HBoxContainer/strawberry_amount

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
		strawberry_amount.text = str(GlobalVariables.strawberrys_collected)
