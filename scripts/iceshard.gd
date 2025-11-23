extends Area2D

@onready var iceshard_sprite = $iceshard_collision/iceshard_projectile  # Correct path
@onready var iceshard_collision = $iceshard_collision
@onready var iceshard_audio = $iceshard_audio

var speed = 200
var iceshard_direction

@export var slow_factor: float = 0.2 # % slow
@export var slow_duration: float = 3.0 # 3 secs

func _ready():
	iceshard_sprite.play("iceshard_moving")
	rotation = iceshard_direction.angle()
	iceshard_sprite.scale.x = -1
	
	play_iceshard_sound()
	
func play_iceshard_sound():
	var iceshard_sounds = [
		preload("res://assets/sfx/iceshard_1.wav"),
		preload("res://assets/sfx/iceshard_2.wav"),
	]
	
	# Pick random casting sound
	var random_index = randi() % iceshard_sounds.size()
	var selected_sound = iceshard_sounds[random_index]
	
	iceshard_audio.stream = selected_sound
	
	# pitch variation
	iceshard_audio.pitch_scale = randf_range(0.9, 1.1)
	
	# volume variation
	iceshard_audio.volume_db = randf_range(3.0, 8.0)
	
	iceshard_audio.play()

func _process(delta):
	position -= iceshard_direction * speed * delta

func _on_iceshard_lifetime_timer_timeout() -> void:
	queue_free()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(10)
	
	if body.has_method("apply_slow_effect"):
		body.apply_slow_effect(slow_factor, slow_duration)
	
	play_impact_sound()
	
	# disable the iceshard's collision and movement
	iceshard_collision.set_deferred("disabled", true)
	set_process(false)
	
	# switch to the impact animation
	iceshard_sprite.play("iceshard_impact")
	
		# detach audio player so it can continue playing after node is freed
	var audio_player = iceshard_audio
	remove_child(audio_player)
	get_parent().add_child(audio_player)
	
	# wait for the impact animation to finish before freeing the node
	await iceshard_sprite.animation_finished
	queue_free()
	
	# free audio player after it finishes playing
	await audio_player.finished
	audio_player.queue_free()

func play_impact_sound():
	var impact_sounds = [
		preload("res://assets/sfx/iceshard_impact_1.wav"),
		preload("res://assets/sfx/iceshard_impact_2.wav"),
	]
	
	var random_index = randi() % impact_sounds.size()
	var selected_sound = impact_sounds[random_index]
	
	iceshard_audio.stream = selected_sound
	
	# pitch
	iceshard_audio.pitch_scale = randf_range(0.9, 1.1)
	
	# volume
	iceshard_audio.volume_db = randf_range(-3.0, 0.0)
	
	iceshard_audio.play()
