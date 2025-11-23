extends Node2D

@export var ranged_enemy_scene: PackedScene
@export var ranged_enemy_spawn_distance: float = 180.0
@export var ranged_enemy_spawn_level: int = 3

@export var boss_scene: PackedScene
@export var boss_spawn_distance: float = 200.0
@export var boss_spawn_level: int = 1

var player: Node2D
var boss_instance: Node2D = null
var has_spawned_ranged: bool = false
var has_spawned_boss: bool = false
var player_alive: bool = true

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("Player")
	
	if player:
		if player.has_signal("player_died"):
			player.connect("player_died", _on_player_died)
		if player.has_signal("player_level_up"):
			player.connect("player_level_up", _on_player_level_up)
	
	print("Player found:", player != null)

func _on_player_level_up(level: int, choices: Array):
	if not player_alive:
		return
	
	print("Player reached level:", level)

	if level >= ranged_enemy_spawn_level and not has_spawned_ranged:
		spawn_ranged_enemy()
	if level >= boss_spawn_level and not has_spawned_boss:
		spawn_boss()

func spawn_ranged_enemy():
	if ranged_enemy_scene and player and is_instance_valid(player) and not has_spawned_ranged:
		var enemy = ranged_enemy_scene.instantiate()
		var dir = Vector2.RIGHT.rotated(randf() * TAU)
		var pos = player.global_position + dir * ranged_enemy_spawn_distance
		enemy.global_position = pos
		get_parent().add_child(enemy)
		has_spawned_ranged = true
		print("RANGED ENEMY SPAWNED at level", player.current_level)

func spawn_boss():
	if boss_scene and player and is_instance_valid(player) and not has_spawned_boss:
		var boss = boss_scene.instantiate()
		var dir = Vector2.RIGHT.rotated(randf() * TAU)
		var pos = player.global_position + dir * boss_spawn_distance
		boss.global_position = pos
		get_parent().add_child(boss)
		boss_instance = boss
		has_spawned_boss = true

		if boss.has_signal("boss_died"):
			boss.connect("boss_died", _on_boss_died)

		print("BOSS SPAWNED at level", player.current_level)

		# stop future mob spawns
		var level_node = get_parent()
		if level_node and level_node.has_method("stop_mob_spawning"):
			level_node.stop_mob_spawning()

		# KILL ALL EXISTING ENEMIES (except the boss)
		for e in get_tree().get_nodes_in_group("enemy"):
			if e != boss and is_instance_valid(e):
				e.queue_free()
		for e in get_tree().get_nodes_in_group("enemy_ranged"):
			if e != boss and is_instance_valid(e):
				e.queue_free()

func _on_boss_died():
	print("Boss died - resuming mob spawning")
	var level_node = get_parent()
	if level_node and level_node.has_method("resume_mob_spawning"):
		level_node.resume_mob_spawning()
	boss_instance = null

func _on_player_died():
	player_alive = false
	player = null
