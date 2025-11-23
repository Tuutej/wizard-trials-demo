extends CharacterBody2D

class_name Player

@onready var health_bar = $UI/HealthBar
@onready var mana_bar = $UI/ManaBar
@onready var mana_regen_timer = $mana_regen_timer
@export var movement_speed : float = 75
@export var max_health : int = 100
@export var max_mana : int = 100
@export var mana_regen_amount : int = 10

# fireball
@export var fireball_damage : int = 10
@export var fireball_mana_cost : int = 1

# iceshard
@export var iceshard_damage : int = 10
@export var iceshard_mana_cost : int = 5

# lightning

@export var lightning_damage : int = 15
@export var lightning_mana_cost : int = 0

# xp progression system
@export var base_xp_to_level_up: int = 10
@export var xp_growth_rate: float = 1.5
@export var starting_spell: String = "fireball" # chosen starting spell

var current_health : int = max_health
var current_mana : int = max_mana
var character_direction : Vector2

var current_xp: int = 0
var current_level: int = 1
var xp_to_level_up: int = base_xp_to_level_up
var available_spells: Array = []
var current_spell: String = ""
var upgrade_choices: Array = []


@onready var fireball_scene = preload("res://scenes/fireball.tscn")
@onready var iceshard_scene = preload("res://scenes/iceshard.tscn")
@onready var lightning_scene = preload("res://scenes/lightning.tscn")

var accept_input:bool = true

signal player_died
signal player_level_up(level, choices)
signal xp_gained(current_xp, xp_to_level_up)

func _ready():
	# load meta file once per boot
	GameData.load()

	# apply meta bonuses to stats before initializing UI
	max_health += GameData.meta_hp_bonus
	max_mana += GameData.meta_mana_bonus
	movement_speed += GameData.meta_speed_bonus
	mana_regen_amount += int(GameData.meta_mana_regen_bonus)
	# health_regen you can implement later if you add actual regen logic

	# initialize current values & UI using buffed stats
	current_health = max_health
	current_mana = max_mana

	health_bar.max_value = max_health
	health_bar.value = current_health

	mana_bar.max_value = max_mana
	mana_bar.value = current_mana

	call_deferred("deferred_spell_selection")
	
func deferred_spell_selection():
	# wait until the next frame to ensure parent is ready
	await get_tree().process_frame
	show_spell_selection_menu()

func show_spell_selection_menu():
	var spell_menu = preload("res://scenes/spell_selection_menu.tscn").instantiate()
	get_parent().call_deferred("add_child", spell_menu)
	spell_menu.spell_selected.connect(_on_spell_selected)
	print("Spell selection menu should be visible now")

func _on_spell_selected(spell_name: String):
	starting_spell = spell_name
	available_spells = [starting_spell]
	current_spell = starting_spell
	print("Selected starting spell: ", starting_spell)

# movement input
func _physics_process(delta):
	character_direction.x = Input.get_axis("move_left", "move_right")
	character_direction.y = Input.get_axis("move_up", "move_down")
	
	# sprite flip based on movement direction
	if character_direction.x > 0: %sprite.flip_h = false
	elif character_direction.x < 0: %sprite.flip_h = true
	
	if character_direction:
		velocity = character_direction * movement_speed
		if %sprite.animation != "move":
			%sprite.animation = "move"
			%sprite.play()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, movement_speed)
		if %sprite.animation != "idle_default":
			%sprite.animation = "idle_default"
			%sprite.play()
		
	move_and_slide()
	
	# we love casting spells
	if Input.is_action_just_pressed("fireball_spell") and available_spells.has("fireball"):
		cast_fireball()
		
	if Input.is_action_just_pressed("iceshard_spell") and available_spells.has("iceshard"):
		cast_iceshard()
		
	if Input.is_action_just_pressed("lightning_spell") and available_spells.has("lightning"):
		cast_lightning()

func gain_xp(amount: int):
	current_xp += amount
	emit_signal("xp_gained", current_xp, xp_to_level_up)
	print("Collected ", amount, " XP! Total: ", current_xp, "/", xp_to_level_up)
	
	if current_xp >= xp_to_level_up:
		handle_level_up()  

func handle_level_up():
	current_level += 1
	current_xp = 0
	xp_to_level_up = int(base_xp_to_level_up * pow(xp_growth_rate, current_level - 1))
	
	generate_upgrade_choices()
	emit_signal("player_level_up", current_level, upgrade_choices)
	
	# show upgrade menu
	show_upgrade_menu()
	
	print("LEVEL UP! Now level: ", current_level)
	
	# visual feedback for level up
	create_level_up_effect()

# floating text popup for XP gain
func create_xp_popup(amount: int):
	var xp_text = Label.new()
	xp_text.text = "+" + str(amount) + " XP"
	xp_text.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	xp_text.position = Vector2(randf_range(-20, 20), -30)
	add_child(xp_text)
	
	var tween = create_tween()
	tween.tween_property(xp_text, "position:y", -60, 0.8)
	tween.parallel().tween_property(xp_text, "modulate:a", 0.0, 0.8)
	tween.tween_callback(xp_text.queue_free)

func create_level_up_effect():
	# Visual effect for level up
	var tween = create_tween()
	tween.tween_property(%sprite, "modulate", Color(1, 1, 0, 1), 0.2)
	tween.tween_property(%sprite, "modulate", Color(1, 1, 1, 1), 0.2)
	tween.set_loops(3)

# generate upgrade choices
func generate_upgrade_choices():
	upgrade_choices.clear()
	var possible_upgrades = []
	
	# spell upgrades for current spells
	for spell in available_spells:
		if spell == "fireball":
			possible_upgrades.append({
				"type": "spell_upgrade", 
				"spell": "fireball", 
				"stat": "damage", 
				"value": 10,
				"name": "Fireball Damage +10",
				"description": "Increases fireball damage by 10"
			})
		elif spell == "iceshard":
			possible_upgrades.append({
				"type": "spell_upgrade", 
				"spell": "iceshard", 
				"stat": "damage", 
				"value": 5,
				"name": "Ice Damage +5",
				"description": "Increases ice shard damage by 5"
			})
		elif spell == "lightning":
			possible_upgrades.append({
				"type": "spell_upgrade",
				"spell": "lightning",
				"stat": "damage",
				"value": 10,
				"name": "Lightning Damage +10",
				"description": "Increases lightning damage by 10"
			})
	
	# choose new spells
	if not available_spells.has("iceshard"):
		possible_upgrades.append({
			"type": "new_spell", 
			"spell": "iceshard",
			"name": "Learn Ice Shard",
			"description": "Unlock the ice shard spell"
		})
	if not available_spells.has("lightning"):
		possible_upgrades.append({
			"type": "new_spell", 
			"spell": "lightning",
			"name": "Learn Lightning",
			"description": "Unlock the lightning spell"
		})
	
	# upgrade player stats
	possible_upgrades.append({
		"type": "stat", 
		"stat": "max_health", 
		"value": 20,
		"name": "Max Health +20",
		"description": "Increases maximum health by 20"
	})
	possible_upgrades.append({
		"type": "stat", 
		"stat": "movement_speed", 
		"value": 10,
		"name": "Speed +10",
		"description": "Increases movement speed by 10"
	})
	possible_upgrades.append({
		"type": "stat", 
		"stat": "mana_regen", 
		"value": 2,
		"name": "Mana Regen +2",
		"description": "Increases mana regeneration by 2"
	})
	
	# Select 3 random upgrades
	while upgrade_choices.size() < 3 and possible_upgrades.size() > 0:
		var random_index = randi() % possible_upgrades.size()
		upgrade_choices.append(possible_upgrades[random_index])
		possible_upgrades.remove_at(random_index)

# show upgrade menu
func show_upgrade_menu():
	var upgrade_menu = preload("res://scenes/upgrade_menu.tscn").instantiate()
	get_parent().add_child(upgrade_menu)
	upgrade_menu.show_upgrades(upgrade_choices, self)

# apply upgrade
func apply_upgrade(upgrade: Dictionary):
	match upgrade["type"]:
		"spell_upgrade":
			if upgrade["stat"] == "damage":
				if upgrade["spell"] == "fireball":
					fireball_damage += upgrade["value"]
					print("Fireball damage increased to: ", fireball_damage)
				elif upgrade["spell"] == "iceshard":
					iceshard_damage += upgrade["value"]
					print("Ice shard damage increased to: ", iceshard_damage)
				elif upgrade["spell"] == "lightning":
					lightning_damage += upgrade["value"]
					print("Lightning damage increased to: ", lightning_damage)
		
		"new_spell":
			available_spells.append(upgrade["spell"])
			current_spell = upgrade["spell"]
			print("Learned new spell: ", upgrade["spell"])
		
		"stat":
			match upgrade["stat"]:
				"max_health":
					max_health += upgrade["value"]
					current_health = max_health
					health_bar.max_value = max_health
					health_bar.value = current_health
					print("Max health increased to: ", max_health)
				"movement_speed":
					movement_speed += upgrade["value"]
					print("Movement speed increased to: ", movement_speed)
				"mana_regen":
					mana_regen_amount += upgrade["value"]
					print("Mana regen increased to: ", mana_regen_amount)
	
	print("Upgrade applied: ", upgrade["name"])


func cast_fireball():
	if current_mana >= fireball_mana_cost:
		current_mana -= fireball_mana_cost
		mana_bar.value = current_mana
		
		var fireball = fireball_scene.instantiate()
		fireball.position = position
		fireball.fireball_direction = (position - get_global_mouse_position()).normalized()
		fireball.fireball_damage = fireball_damage 
		get_parent().add_child(fireball)
		fireball.fireball_hit.connect(_on_fireball_hit)
	else:
		print("Not enough mana!")
		
func _on_fireball_hit(damage_dealt):
	print("Fireball hit for ", damage_dealt, " damage")
	
		
func cast_iceshard():
	if current_mana >= iceshard_mana_cost:
		current_mana -= iceshard_mana_cost
		mana_bar.value = current_mana
		
		var iceshard = iceshard_scene.instantiate()
		iceshard.position = position
		iceshard.iceshard_direction = (position - get_global_mouse_position()).normalized()
		get_parent().add_child(iceshard)
	else:
		print("Not enough mana!")

func cast_lightning():
	if current_mana < lightning_mana_cost:
		print("Not enough mana for lightning!")
		return

	current_mana -= lightning_mana_cost
	mana_bar.value = current_mana

	var lightning = lightning_scene.instantiate()

	# start at player
	lightning.global_position = global_position

	# aim at mouse direction
	var dir: Vector2 = (get_global_mouse_position() - global_position).normalized()
	lightning.rotation = dir.angle()

	# set lightning damage
	lightning.damage = lightning_damage

	get_parent().add_child(lightning)

func _on_mana_regen_timer_timeout():
	if current_mana < max_mana:
		current_mana += mana_regen_amount
		current_mana = min(current_mana, max_mana)  
		mana_bar.value = current_mana
		print("Mana Regenerated: ", mana_regen_amount, " Current Mana: ", current_mana)

func take_damage(damage: int):
	current_health -= damage
	health_bar.value = current_health
	if current_health <= 0:
		die()


func die():
	print("player dead")
	# emit the death signal
	emit_signal("player_died")
	
	var death = get_tree().current_scene  
	if death and death.has_method("game_over"):
		death.game_over()
	queue_free()
