extends CanvasLayer

@onready var gems_label: Label           = $Panel/VBoxContainer/Gems
@onready var feedback_label: Label       = $Panel/VBoxContainer/Feedback
@onready var hp_button: Button           = $Panel/VBoxContainer/HPButton
@onready var mana_button: Button         = $Panel/VBoxContainer/ManaButton
@onready var speed_button: Button        = $Panel/VBoxContainer/SpeedButton
@onready var mana_regen_button: Button   = $Panel/VBoxContainer/ManaRegenButton
@onready var health_regen_button: Button = $Panel/VBoxContainer/HealthRegenButton
@onready var close_button: Button        = $Panel/VBoxContainer/CloseShop

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true

	_update_gems_label()
	feedback_label.text = ""

	hp_button.pressed.connect(_on_hp_pressed)
	mana_button.pressed.connect(_on_mana_pressed)
	speed_button.pressed.connect(_on_speed_pressed)
	mana_regen_button.pressed.connect(_on_mana_regen_pressed)
	health_regen_button.pressed.connect(_on_health_regen_pressed)
	close_button.pressed.connect(_on_close_pressed)

	hp_button.grab_focus()

func _update_gems_label() -> void:
	gems_label.text = "Gems: " + str(GameData.gems)

func _buy_and_feedback(stat: String, pretty: String) -> void:
	if GameData.buy(stat):
		GameData.save()  
		feedback_label.text = pretty + " upgraded!"
	else:
		feedback_label.text = "Not enough gems!"
	_update_gems_label()

func _on_hp_pressed() -> void:
	_buy_and_feedback("hp", "Max HP")

func _on_mana_pressed() -> void:
	_buy_and_feedback("mana", "Max Mana")

func _on_speed_pressed() -> void:
	_buy_and_feedback("speed", "Speed")

func _on_mana_regen_pressed() -> void:
	_buy_and_feedback("mana_regen", "Mana Regen")

func _on_health_regen_pressed() -> void:
	_buy_and_feedback("health_regen", "Health Regen")

func _on_close_pressed() -> void:
	queue_free()
