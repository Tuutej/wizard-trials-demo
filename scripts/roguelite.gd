extends Node2D

@export var melee_enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var ranged_enemy_scene: PackedScene = preload("res://scenes/enemy_ranged.tscn")
var game_over_scene = preload("res://scenes/game_over_screen.tscn")
var mob_spawning_enabled: bool = true
var player_alive: bool = true
var player_level: int = 1
var xp_bar: ProgressBar
var level_text: Label

func _ready():
	var boss = get_tree().get_first_node_in_group("boss")
	if boss and boss.has_signal("boss_died"):
		boss.connect("boss_died", _on_boss_died)

	await get_tree().process_frame

	# Connect to player signals for XP system
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.connect("player_level_up", _on_player_level_up)
		player.connect("xp_gained", _on_player_xp_gained)
		player.connect("player_died", _on_player_died)

	# Setup XP UI if it exists
	setup_xp_ui()


func _on_boss_died():
	print("Boss defeated - showing victory screen!")
	show_victory_screen()


func show_victory_screen():
	var victory_screen = preload("res://scenes/victory_screen.tscn").instantiate()
	add_child(victory_screen)
	get_tree().paused = true


func setup_xp_ui():
	# Try to find XP UI elements
	if has_node("UI/XPBar"):
		xp_bar = $UI/XPBar
	if has_node("UI/LevelText"):
		level_text = $UI/LevelText


func _on_player_level_up(level: int, choices: Array):
	player_level = level
	print("Player reached level ", level)
	if level_text:
		level_text.text = "Level " + str(level)


func _on_player_xp_gained(current_xp: int, xp_needed: int):
	# Update XP bar if available
	if xp_bar:
		xp_bar.max_value = xp_needed
		xp_bar.value = current_xp
	print("XP: ", current_xp, "/", xp_needed)


func _on_player_died():
	game_over()


func game_over():
	print("game over")
	player_alive = false

	# Stop all timers
	if has_node("Timer") and is_instance_valid($Timer):
		$Timer.stop()

	var game_over_instance = game_over_scene.instantiate()
	add_child(game_over_instance)
	game_over_instance.visible = true


func _on_timer_timeout() -> void:
	if mob_spawning_enabled and player_alive:
		spawn_mob()


func spawn_mob():
	# Check if player still exists
	if not has_node("player") or not is_instance_valid($player):
		return

	var path_follow: PathFollow2D = $player/Path2D/PathFollow2D
	if not is_instance_valid(path_follow):
		return

	path_follow.progress_ratio = randf()
	var spawn_pos: Vector2 = path_follow.global_position

	# --- choose which type to spawn ---
	var scene_to_spawn: PackedScene = melee_enemy_scene
	if player_level >= 3:
		var ranged_chance: float = clamp(0.1 + (player_level - 3) * 0.05, 0.1, 0.5)
		if randf() < ranged_chance:
			scene_to_spawn = ranged_enemy_scene

	var new_enemy: Node2D = scene_to_spawn.instantiate()
	new_enemy.global_position = spawn_pos
	add_child(new_enemy)

	print("Spawned ", scene_to_spawn.resource_path.get_file(), " at level ", player_level)




# Methods to control mob spawning
func stop_mob_spawning():
	print("Stopping mob spawning")
	mob_spawning_enabled = false

	# Stop the timer
	if has_node("Timer") and is_instance_valid($Timer):
		$Timer.stop()


func resume_mob_spawning():
	if not player_alive:
		return

	print("Resuming mob spawning")
	mob_spawning_enabled = true

	# Start timer if stopped
	if has_node("Timer") and is_instance_valid($Timer):
		if $Timer.is_stopped():
			$Timer.start()
