extends CanvasLayer

func _ready():
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Pause gameplay when this UI appears
	get_tree().paused = true

	$RestartButton.pressed.connect(_on_restart_pressed)
	$MainMenu.pressed.connect(_on_quit_pressed)

	$RestartButton.grab_focus()


func _on_restart_pressed():
	# hide UI, unpause, and reload the full scene
	visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
