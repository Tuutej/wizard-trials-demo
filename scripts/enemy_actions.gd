extends CharacterBody2D
	
@export var speed: float = 25
@export var max_health: int = 50
@export var attack_damage: int = 10
@export var attack_range: float = 15   # how close enemy must be to attack
@export var attack_cooldown: float = 1 # seconds between attacks

var health: int = max_health
var player = null  # will hold a reference to the player
var time_since_last_attack: float = 0

# slow effect
var base_speed: float = 25
var is_slowed: bool = false
var slow_timer: Timer

signal health_changed

func _ready():
	$AnimatedSprite2D.play("move") 

func _physics_process(delta):
	if player:
		time_since_last_attack += delta
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player <= attack_range:
			if time_since_last_attack >=attack_cooldown:
				attack()
				time_since_last_attack = 0
		else:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
			
			#print("Timer:", time_since_last_attack)

func attack():
	if player and player.has_method("take_damage"):
		player.take_damage(attack_damage) 
		
func take_damage(damage: int):
	health -= damage
	if health <= 0:
		die()
		
	$AnimatedSprite2D.modulate = Color(2.0, 2.0, 2.0) 
	await get_tree().create_timer(0.1).timeout
	$AnimatedSprite2D.modulate = Color.WHITE
		
func die():
	# mark as dead 
	set_physics_process(false)
	
	# disable collision
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	# disable detection area
	if has_node("DetectionArea"):
		$DetectionArea/CollisionShape2D.set_deferred("disabled", true)
	
	# spawn XP orb
	var xp_orb_scene = preload("res://scenes/xpOrb.tscn")
	var xp_orb = xp_orb_scene.instantiate()
	var spawn_variation = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	xp_orb.global_position = global_position + spawn_variation
	
	var pop_velocity = Vector2(randf_range(-40, 40), -randf_range(60, 100))
	xp_orb.set("velocity", pop_velocity)
	get_parent().add_child(xp_orb)
	
	# play death animation or effect
	$AnimatedSprite2D.modulate = Color.RED
	
	# wait 0.1 and clean up enemy
	await get_tree().create_timer(0.1).timeout
	queue_free()

# method to apply slow effect
func apply_slow_effect(slow_factor: float, duration: float):
	if not is_slowed:
		# store original speed and apply slow
		base_speed = speed
		speed *= slow_factor
		is_slowed = true
		
		# visual feedback for slow effect 
		var tween = create_tween()
		tween.tween_property($AnimatedSprite2D, "modulate", Color(0.3, 0.6, 1.0, 0.9), 0.15)
		tween.tween_property($AnimatedSprite2D, "modulate", Color(0.5, 0.8, 1.0, 1.0), 0.3)
		tween.set_loops()  
		
		# timer to remove slow effect
		slow_timer = Timer.new()
		slow_timer.wait_time = duration
		slow_timer.one_shot = true
		add_child(slow_timer)
		slow_timer.start()
		slow_timer.connect("timeout", _on_slow_end)

func _on_slow_end():
	# restore original speed
	speed = base_speed
	is_slowed = false
	
	
	# remove visual slow effect
	$AnimatedSprite2D.modulate = Color.WHITE
	
	slow_timer.queue_free()

# called when something enters the detection area2d
func _on_detection_area_body_entered(body):
	if body.is_in_group("Player"):  
		player = body

# called when something exits the detection area2d
func _on_detection_area_body_exited(body):
	if body == player:
		player = null
