extends Area2D

@export var xp_value: int = 5
@export var attraction_speed: float = 80.0
@export var attraction_range: float = 60.0
@export var max_drop_distance: float = 24.0   # how far it can fall down
@export var drop_gravity: float = 180.0

var player: Node2D
var is_attracted: bool = false
var velocity: Vector2 = Vector2.ZERO
var has_stopped: bool = false
var start_y: float = 0.0

func _ready() -> void:
	# connect pick-up
	body_entered.connect(_on_body_entered)

	# find player
	player = get_tree().get_first_node_in_group("Player")

	# remember spawn height so we only fall a little bit
	start_y = global_position.y

func _physics_process(delta: float) -> void:
	# attraction to player
	if player and is_instance_valid(player):
		var distance_to_player := global_position.distance_to(player.global_position)
		if distance_to_player <= attraction_range or is_attracted:
			is_attracted = true
			var direction := (player.global_position - global_position).normalized()
			global_position += direction * attraction_speed * delta
			return  # skip drop logic while magnetized

	# falling / settling while not attracted
	if not has_stopped:
		velocity.y += drop_gravity * delta
		global_position += velocity * delta

		# clamp drop distance
		if global_position.y - start_y >= max_drop_distance:
			global_position.y = start_y + max_drop_distance
			velocity = Vector2.ZERO
			has_stopped = true

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and body.has_method("gain_xp"):
		body.gain_xp(xp_value)
		queue_free()
