extends CharacterBody2D

signal boss_died

@export var speed: float = 35.0
@export var max_health: int = 250
@export var contact_damage: int = 20

# General attack timings
@export var attack_interval: float = 2.0      # time between choosing attacks
@export var attack_range: float = 220.0       # must be within this to start attacks

# Beam attack
@export var beam_damage: int = 20
@export var beam_windup: float = 0.7
@export var beam_duration: float = 0.25

# Close-range AoE attack
@export var aoe_damage: int = 25
@export var aoe_windup: float = 0.8
@export var aoe_duration: float = 0.2

# Summon adds
@export var summon_scene: PackedScene         # assign enemy here in inspector
@export var summon_count_min: int = 2
@export var summon_count_max: int = 3
@export var summon_radius: float = 140.0

var health: int
var player: Node2D
var player_is_alive: bool = true

var original_speed: float
var is_slowed: bool = false
var slow_timer: Timer

var is_attacking: bool = false
var alive: bool = true

var beam_active: bool = false
var aoe_active: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var beam_area: Area2D = $beam_area
@onready var aoe_area: Area2D = $aoe_area
@onready var beam_telegraph: CanvasItem = null
@onready var aoe_telegraph: CanvasItem = null

func _ready():
	original_speed = speed
	health = max_health

	# grab telegraph sprites if they exist
	if beam_area.has_node("telegraph"):
		beam_telegraph = beam_area.get_node("telegraph") as CanvasItem
	if aoe_area.has_node("telegraph"):
		aoe_telegraph = aoe_area.get_node("telegraph") as CanvasItem

	anim.play("idle")
	create_health_bar()

	player = get_tree().get_first_node_in_group("Player")
	if player and player.has_signal("player_died"):
		player.connect("player_died", _on_player_died)

	# make sure areas start disabled
	beam_area.monitoring = false
	aoe_area.monitoring = false

	# connect area signals
	beam_area.body_entered.connect(_on_beam_body_entered)
	aoe_area.body_entered.connect(_on_aoe_body_entered)
	
	if beam_telegraph: beam_telegraph.visible = false
	if aoe_telegraph: aoe_telegraph.visible = false

	_ai_loop()

	print("Boss initialized with health: ", health)

func create_health_bar():
	if has_node("HealthBar"):
		$HealthBar.queue_free()

	var health_bar := ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.size = Vector2(100, 10)
	health_bar.position = Vector2(-50, -60)
	add_child(health_bar)

func _physics_process(delta: float) -> void:
	if not alive:
		velocity = Vector2.ZERO
		return

	if player_is_alive and player and is_instance_valid(player):
		if not is_attacking:
			var dir := (player.global_position - global_position).normalized()
			velocity = dir * speed
			move_and_slide()

			if velocity.length() > 0.0:
				if anim.animation != "move":
					anim.play("move")
				anim.flip_h = dir.x < 0.0
			else:
				if anim.animation != "idle":
					anim.play("idle")
	else:
		velocity = Vector2.ZERO
		if anim.animation != "idle":
			anim.play("idle")

func _on_beam_body_entered(body: Node) -> void:
	if not beam_active:
		return
	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage(beam_damage)

func _on_aoe_body_entered(body: Node) -> void:
	if not aoe_active:
		return
	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage(aoe_damage)

func _ai_loop() -> void:
	await get_tree().process_frame
	while alive and player_is_alive and player and is_instance_valid(player):
		await get_tree().create_timer(attack_interval).timeout
		if not alive or not player_is_alive or not player or not is_instance_valid(player):
			break

		var dist := global_position.distance_to(player.global_position)
		if dist > attack_range:
			continue

		var roll := randi() % 100
		if roll < 40:
			await _beam_attack()
		elif roll < 75:
			await _aoe_attack()
		else:
			await _summon_attack()

func _beam_attack() -> void:
	if not player or not is_instance_valid(player):
		return

	is_attacking = true
	velocity = Vector2.ZERO
	anim.play("idle")

	# aim at player
	var dir := (player.global_position - global_position).normalized()
	beam_area.rotation = dir.angle()

	# telegraph
	if beam_telegraph:
		beam_telegraph.visible = true
		beam_telegraph.modulate = Color(1.0, 1.0, 0.3, 0.7)

	# wind-up
	await get_tree().create_timer(beam_windup).timeout

	# FIRE: enable area and mark active
	beam_active = true
	beam_area.monitoring = true

	# if player is already in beam when it turns on, damage immediately
	for body in beam_area.get_overlapping_bodies():
		if body.is_in_group("Player") and body.has_method("take_damage"):
			body.take_damage(beam_damage)

	if beam_telegraph:
		beam_telegraph.modulate = Color(1.2, 0.4, 0.2, 0.9)

	await get_tree().create_timer(beam_duration).timeout

	beam_area.monitoring = false
	beam_active = false

	if beam_telegraph:
		beam_telegraph.visible = false

	is_attacking = false


func _aoe_attack() -> void:
	if not player or not is_instance_valid(player):
		return

	is_attacking = true
	velocity = Vector2.ZERO
	anim.play("idle")

	if aoe_telegraph:
		aoe_telegraph.visible = true
		aoe_telegraph.modulate = Color(1.0, 1.0, 0.3, 0.7)

	# wind-up circle
	await get_tree().create_timer(aoe_windup).timeout

	# FIRE: enable AoE and mark active
	aoe_active = true
	aoe_area.monitoring = true

	for body in aoe_area.get_overlapping_bodies():
		if body.is_in_group("Player") and body.has_method("take_damage"):
			body.take_damage(aoe_damage)

	if aoe_telegraph:
		aoe_telegraph.modulate = Color(1.2, 0.4, 0.2, 0.9)

	await get_tree().create_timer(aoe_duration).timeout

	aoe_area.monitoring = false
	aoe_active = false

	if aoe_telegraph:
		aoe_telegraph.visible = false

	is_attacking = false


func _summon_attack() -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	anim.play("idle")

	if summon_scene:
		var count := randi_range(summon_count_min, summon_count_max)
		for i in range(count):
			var angle := randf() * TAU
			var offset := Vector2.RIGHT.rotated(angle) * summon_radius
			var minion := summon_scene.instantiate()
			minion.global_position = global_position + offset
			get_parent().add_child(minion)

	await get_tree().create_timer(0.8).timeout
	is_attacking = false

func _damage_bodies_in_area(area: Area2D, damage: int) -> void:
	for body in area.get_overlapping_bodies():
		if body and body.is_in_group("Player") and body.has_method("take_damage"):
			body.take_damage(damage)

func attack(): # kept for compatibility if something still calls it
	if player and is_instance_valid(player) and player.has_method("take_damage"):
		player.take_damage(contact_damage)

func take_damage(damage: int):
	if not alive:
		return

	print("Boss taking damage: ", damage)
	health -= damage

	if has_node("HealthBar"):
		$HealthBar.value = health

	anim.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	anim.modulate = Color.WHITE

	if health <= 0:
		die()

func apply_slow_effect(slow_factor: float, duration: float):
	if not is_slowed:
		speed *= slow_factor
		is_slowed = true

		var tween := create_tween()
		tween.tween_property(anim, "modulate", Color(0.5, 0.8, 1.0, 0.8), 0.2)
		tween.tween_property(anim, "modulate", Color(0.5, 0.8, 1.0, 1.0), 0.2)
		tween.set_loops()

		slow_timer = Timer.new()
		slow_timer.wait_time = duration
		slow_timer.one_shot = true
		add_child(slow_timer)
		slow_timer.start()
		slow_timer.timeout.connect(_on_slow_end)

		print("Boss slowed! Speed: ", speed)

func _on_slow_end():
	speed = original_speed
	is_slowed = false
	anim.modulate = Color.WHITE
	slow_timer.queue_free()
	print("Boss slow effect ended. Speed: ", speed)

func _on_hitbox_area_entered(area: Area2D):
	print("Hitbox area entered: ", area.name)

	if area.has_method("get_damage"):
		var damage: int = area.get_damage()         
		take_damage(damage)

		# check if it's a slowing projectile
		if area.has_method("get_slow_factor") and area.has_method("get_slow_duration"):
			var slow_factor: float = area.get_slow_factor() 
			var slow_duration: float = area.get_slow_duration() 
			apply_slow_effect(slow_factor, slow_duration)

		area.queue_free()

func _on_detection_area_body_entered(body):
	if body.is_in_group("Player"):
		player = body

func _on_detection_area_body_exited(body):
	if body == player:
		player = null

func die():
	if not alive:
		return
	alive = false

	emit_signal("boss_died")
	print("Boss defeated!")
	show_victory_screen()
	queue_free()

func show_victory_screen():
	var victory_screen = preload("res://scenes/victory_screen.tscn").instantiate()
	get_tree().current_scene.add_child(victory_screen)

func _on_player_died():
	player_is_alive = false
	player = null
