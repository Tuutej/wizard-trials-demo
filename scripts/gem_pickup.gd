extends Area2D

@export var gem_value: int = 1
@onready var gem_sprite = $AnimatedSprite2D

func _ready() -> void:
	monitoring = true
	monitorable = true
	
	if gem_sprite:
		gem_sprite.play("gem")
		
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	print("Gem body entered by: ", body.name)
	if not body.is_in_group("Player"):
		return

	if GameData.has_method("add_gems"):
		GameData.add_gems(gem_value)
	else:
		GameData.gems += gem_value
		if GameData.has_method("save"):
			GameData.save()

	print("Picked up ", gem_value, " gem(s). Total now: ", GameData.gems)

	queue_free()
