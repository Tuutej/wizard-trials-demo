extends Area2D

@onready var fireball_sprite = $fireball_collision/fireball_projectile
@onready var fireball_collision = $fireball_collision
@onready var fireball_audio = $fireball_audio

var speed = 200
var fireball_direction
var fireball_damage: int = 10 # default dmg just in case

signal fireball_hit(damage_dealt)

func play_fireball_sound():
	var fireball_sound = preload("res://assets/sfx/fireball.ogg") 
	fireball_audio.stream = fireball_sound
	fireball_audio.play()
	
func play_impact_sound():
	var impact_sounds = [
		preload("res://assets/sfx/fireball_impact_1.wav"),
		preload("res://assets/sfx/fireball_impact_5.wav"),
		preload("res://assets/sfx/fireball_impact_3.wav"),
		preload("res://assets/sfx/fireball_impact_4.wav")
	]
	
	var random_index = randi() % impact_sounds.size()
	var selected_sound = impact_sounds[random_index]
	
	fireball_audio.stream = selected_sound
	
	# pitch
	fireball_audio.pitch_scale = randf_range(0.9, 1.1)
	
	# volume
	fireball_audio.volume_db = randf_range(-3.0, 0.0)
	
	fireball_audio.play()

func _ready():
	fireball_sprite.play("fireball_moving")
	rotation = fireball_direction.angle()
	fireball_sprite.scale.x = -1
	
	play_fireball_sound()

func _process(delta):
	position -= fireball_direction * speed * delta

func _on_fireball_lifetime_timer_timeout() -> void:
	queue_free()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			var damage = player.fireball_damage
			body.take_damage(damage)
			fireball_hit.emit(damage)
		else:
			body.take_damage(fireball_damage)
	
	play_impact_sound()
	
	# disable the fireball's collision and movement
	fireball_collision.set_deferred("disabled", true)
	set_process(false)
	
	# switch to the impact animation
	fireball_sprite.play("fireball_impact")
	
	# detach audio player so it can continue playing after node is freed
	var audio_player = fireball_audio
	remove_child(audio_player)
	get_parent().add_child(audio_player)
	
	# wait for the impact animation to finish before freeing the node
	await fireball_sprite.animation_finished
	queue_free()
	
	# free audio player after it finishes playing
	await audio_player.finished
	audio_player.queue_free()
