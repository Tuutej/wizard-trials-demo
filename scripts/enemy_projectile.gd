extends Area2D

@export var lifetime: float = 6.0
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
	if body.is_in_group("enemy_ranged"):
		return

	# If it's the player, apply damage
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)

	_do_impact_and_die()


func _do_impact_and_die() -> void:
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
