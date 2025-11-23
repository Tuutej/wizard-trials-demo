extends Node2D


func spawn_mob():
	var new_mob = preload("res://scenes/enemy.tscn").instantiate()
	var path_follow = get_node("Path2D/PathFollow2D") 
	path_follow.progress_ratio = randf()
	new_mob.global_position = path_follow.global_position
	add_child(new_mob)  


func _on_timer_timeout() -> void:
	spawn_mob()
