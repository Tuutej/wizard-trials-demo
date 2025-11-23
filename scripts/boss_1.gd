extends CharacterBody2D
class_name boss1

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	move_and_slide()
	
	# Play appropriate animation based on movement
	if velocity.length() > 0:
		# Moving - play run animation
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		# Not moving - play idle animation
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
	
	# Flip sprite based on movement direction
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0
