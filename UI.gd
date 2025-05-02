extends CanvasLayer

signal attack_mode_enabled(enabled: bool)

@onready var attack_button: Button = $AttackButton

#func _ready():
	#attack_button.pressed.connect(_on_attack_pressed)

func _on_attack_pressed():
	attack_mode_enabled.emit(true)
