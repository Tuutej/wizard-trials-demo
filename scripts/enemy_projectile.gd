extends Area2D

@export var lifetime: float = 3.0
var velocity: Vector2 = Vector2.ZERO
var damage: int = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if sprite:
		sprite.animation = "default"
		sprite.play()

	collision_shape.disabled = false
	set_physics_process(true)

	# auto-despawn after some time if it never hits anything
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	global_position += velocity * delta

func _on_body_entered(body: Node) -> void:
	if not (body.is_in_group("Player") and body.has_method("take_damage")):
		return

	# deal damage once
	body.take_damage(damage)

	# stop moving & colliding
	collision_shape.set_deferred("disabled", true)
	set_physics_process(false)

	# play impact animation, then free
	if sprite and sprite.has_animation("impact"):
		sprite.animation = "impact"
		sprite.play()
		await sprite.animation_finished
	queue_free()


func get_damage() -> int:
	return damage
