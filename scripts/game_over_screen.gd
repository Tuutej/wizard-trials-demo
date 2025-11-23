extends CanvasLayer


func _ready():
	$Retry.pressed.connect(_on_restart_pressed)
	$"Give up".pressed.connect(_on_quit_pressed)
	self.visible = false 
	

func _on_restart_pressed():
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
