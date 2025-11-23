extends Area2D

@export var damage: int = 15
@export var lifetime: float = 0.15
@onready var lightning_audio: AudioStreamPlayer2D = $lightning_audio

var _hit_bodies := {}  # prevents double-hits

func _ready() -> void:
	$CollisionShape2D.disabled = false
	body_entered.connect(_on_body_entered)

	if lightning_audio == null:
		push_error("lightning_audio node not found on Lightning scene!")
	else:
		play_lightning_sound()

	# despawn after lifetime 
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func play_lightning_sound() -> void:
	var lightning_sounds: Array[AudioStream] = [
		preload("res://assets/sfx/lightning_1.wav"),
		preload("res://assets/sfx/lightning_2.wav"),
		preload("res://assets/sfx/lightning_3.wav"),
		preload("res://assets/sfx/lightning_4.wav"),
		preload("res://assets/sfx/lightning_5.wav"),
		preload("res://assets/sfx/lightning_6.wav")
	]

	if lightning_sounds.is_empty():
		push_warning("No lightning sounds found.")
		return

	var random_index := randi() % lightning_sounds.size()
	var selected_sound: AudioStream = lightning_sounds[random_index]

	lightning_audio.stream = selected_sound
	lightning_audio.pitch_scale = randf_range(0.95, 1.05)
	lightning_audio.volume_db = randf_range(-2.0, 0.0)

	print("Playing lightning sound index: ", random_index)

	# detach audio so it can finish playing even when this node is freed
	var audio_player := lightning_audio
	remove_child(audio_player)
	get_parent().add_child(audio_player)
	audio_player.play()

	# clean up audio when it finishes
	audio_player.finished.connect(func():
		audio_player.queue_free())
	

func _on_body_entered(body: Node) -> void:
	if _hit_bodies.has(body):
		return
	_hit_bodies[body] = true

	if body.has_method("take_damage"):
		body.take_damage(damage)
