extends CanvasLayer

var upgrade_choices: Array = []
var player: Node

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# connect buttons
	$Panel/BoxContainer/UpgradeButton1.pressed.connect(_on_upgrade1_selected)
	$Panel/BoxContainer/UpgradeButton2.pressed.connect(_on_upgrade2_selected)
	$Panel/BoxContainer/UpgradeButton3.pressed.connect(_on_upgrade3_selected)
	
	# connect mouse enter signals for hover descriptions
	$Panel/BoxContainer/UpgradeButton1.mouse_entered.connect(_on_upgrade1_hover)
	$Panel/BoxContainer/UpgradeButton2.mouse_entered.connect(_on_upgrade2_hover)
	$Panel/BoxContainer/UpgradeButton3.mouse_entered.connect(_on_upgrade3_hover)

func show_upgrades(choices: Array, player_node: Node):
	upgrade_choices = choices
	player = player_node
	visible = true
	
	# pause the game
	get_tree().paused = true
	
	# update button texts and visibility
	for i in range(3):
		var button = get_node("Panel/BoxContainer/UpgradeButton" + str(i + 1))
		if i < choices.size():
			button.text = choices[i]["name"]
			button.disabled = false
			button.visible = true
		else:
			button.visible = false
	
	# show first upgrade description by default
	if choices.size() > 0:
		$Panel/Description.text = choices[0].get("description", "")
		$Panel/BoxContainer/UpgradeButton1.grab_focus()

func _on_upgrade1_selected():
	apply_upgrade(0)

func _on_upgrade2_selected():
	apply_upgrade(1)

func _on_upgrade3_selected():
	apply_upgrade(2)

# hover functions for descriptions
func _on_upgrade1_hover():
	if upgrade_choices.size() > 0:
		$Panel/Description.text = upgrade_choices[0].get("description", "")

func _on_upgrade2_hover():
	if upgrade_choices.size() > 1:
		$Panel/Description.text = upgrade_choices[1].get("description", "")

func _on_upgrade3_hover():
	if upgrade_choices.size() > 2:
		$Panel/Description.text = upgrade_choices[2].get("description", "")

func apply_upgrade(choice_index: int):
	print("Applying upgrade choice: ", choice_index)
	
	if choice_index < upgrade_choices.size() and player and player.has_method("apply_upgrade"):
		print("Calling player.apply_upgrade with: ", upgrade_choices[choice_index])
		player.apply_upgrade(upgrade_choices[choice_index])
	else:
		print("Cannot apply upgrade - conditions not met")
		print("Choice index: ", choice_index, " Choices size: ", upgrade_choices.size())
		print("Player valid: ", player != null)
		if player: print("Has apply_upgrade method: ", player.has_method("apply_upgrade"))
	
	# unpause game and close menu
	get_tree().paused = false
	visible = false
	queue_free()
