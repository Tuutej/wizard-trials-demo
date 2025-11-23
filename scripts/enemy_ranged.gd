extends CharacterBody2D

@export var speed: float = 40.0
@export var max_health: int = 40
@export var contact_damage: int = 8                 # melee dmg
@export var shoot_damage: int = 6
@export var shoot_cooldown: float = 1.2
@export var shoot_range: float = 280.0
@export var keep_distance: float = 200.0             # kite around this distance
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 260.0
@export var projectile_spread_deg: float = 6.0       # little inaccuracy

var health: int
var player: Node2D = null
var time_since_shot := 0.0

signal health_changed

func _ready() -> void:
	health = max_health
	if $AnimatedSprite2D: $AnimatedSprite2D.play("move")

func _physics_process(delta: float) -> void:
	time_since_shot += delta
	if not player: 
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	var dist := to_player.length()

	# Maintain preferred distance (kite)
	var dir := to_player.normalized()
	if dist < keep_distance * 0.8:
		velocity = -dir * speed
	elif dist > keep_distance * 1.2:
		velocity = dir * speed
	else:
		# strafe a bit
		var perp := Vector2(-dir.y, dir.x)
		velocity = perp * speed * 0.6

	move_and_slide()

	# Face sprite
	if $AnimatedSprite2D:
		$AnimatedSprite2D.flip_h = dir.x < 0.0
		if velocity.length() > 0 and $AnimatedSprite2D.animation != "move":
			$AnimatedSprite2D.play("move")

	# Shoot if in range and off cooldown
	if dist <= shoot_range and time_since_shot >= shoot_cooldown:
		_shoot(dir)
		time_since_shot = 0.0

func _shoot(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var bullet = projectile_scene.instantiate()
	bullet.global_position = global_position
	var spread_rad := deg_to_rad(randf_range(-projectile_spread_deg, projectile_spread_deg))
	var d := dir.rotated(spread_rad).normalized()
	# standard properties expected by EnemyBullet.gd
	bullet.set("velocity", d * projectile_speed)
	bullet.set("damage", shoot_damage)
	get_parent().add_child(bullet)

func take_damage(dmg: int) -> void:
	health -= dmg
	emit_signal("health_changed", health, max_health)
	if $AnimatedSprite2D:
		$AnimatedSprite2D.modulate = Color(2,2,2)
		await get_tree().create_timer(0.07).timeout
		$AnimatedSprite2D.modulate = Color.WHITE
	if health <= 0:
		_die()

func _die() -> void:
	set_physics_process(false)
	if has_node("CollisionShape2D"): $CollisionShape2D.set_deferred("disabled", true)
	if has_node("DetectionArea"): $DetectionArea/CollisionShape2D.set_deferred("disabled", true)

	# spawn XP orb (same as your melee enemy)
	var xp_orb_scene = preload("res://scenes/xpOrb.tscn")
	var xp_orb = xp_orb_scene.instantiate()
	xp_orb.global_position = global_position + Vector2(randf_range(-10,10), randf_range(-10,10))
	xp_orb.set("velocity", Vector2(randf_range(-40,40), -randf_range(60,100)))
	get_parent().add_child(xp_orb)

	if $AnimatedSprite2D: $AnimatedSprite2D.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	queue_free()

func _on_detection_area_body_entered(body):
	if body.is_in_group("Player"): player = body

func _on_detection_area_body_exited(body):
	if body == player: player = null
