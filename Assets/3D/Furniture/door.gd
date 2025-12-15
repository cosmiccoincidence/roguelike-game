extends StaticBody3D
class_name Door

@export var interaction_range := 2.0

var collision_shape: CollisionShape3D = null
var is_open := false
var player: CharacterBody3D = null
var can_interact := true

func _ready():
	# Try to get existing collision shape
	collision_shape = get_node_or_null("CollisionShape3D")
	
	# Create a basic collision shape if none exists
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		add_child(collision_shape)
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(1, 2, 0.1)  # Door-sized collision
		collision_shape.shape = box_shape
	
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	if not player or not can_interact:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= interaction_range:
		# Check for interaction input
		if Input.is_action_just_pressed("interact"):
			toggle_door()

func toggle_door():
	if not can_interact:
		return
	
	is_open = !is_open
	
	# Toggle collision
	if collision_shape:
		collision_shape.disabled = is_open
	
	if is_open:
		print("Door opened (collision disabled)")
	else:
		print("Door closed (collision enabled)")
