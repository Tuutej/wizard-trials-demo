extends CanvasLayer

func _ready():
	$Background/VBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)
	$Background/VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)
	$Background/VBoxContainer/UpgradesButton.pressed.connect(_on_upgrades_button_pressed)
	
	$Background/VBoxContainer/StartButton.grab_focus()

func _on_start_button_pressed():
	print("Starting game...")
	get_tree().change_scene_to_file("res://scenes/roguelite.tscn")

func _on_quit_button_pressed():
	print("Quitting game...")
	get_tree().quit()

func _on_upgrades_button_pressed():
	var shop_scene := preload("res://scenes/meta_shop.tscn")
	var shop := shop_scene.instantiate()
	add_child(shop)
