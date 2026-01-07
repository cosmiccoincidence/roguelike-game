# player_movement.gd
# Handles player movement, rotation, and camera controls
extends Node

var player: CharacterBody3D
var camera: Camera3D

# ===== MOVEMENT =====
@export_group("Movement")
@export var base_movement_speed: float = 5.0  # Base movement speed (can be modified by buffs/items)
@export var rotation_speed: float = 5.0
@export var sprint_multiplier: float = 3.0
@export var sprint_stamina_cost: float = 1.5

# Calculated movement speed (base + modifiers)
var movement_speed: float = 5.0

# Encumbered penalties (only applied when not in god mode)
const ENCUMBERED_SPEED_MULT: float = 0.2  # 20% speed
const ENCUMBERED_ROTATION_MULT: float = 0.75  # 75% rotation speed

# ===== CAMERA =====
@export_group("Camera")
@export var zoom_min: int = 10
@export var zoom_max: int = 100
@export var zoom_speed: float = 15.0
@export var zoom_smooth: float = 8.0

var zoom_target: float = 75.0
var zoom_current: float = 75.0
var god_zoom_max: float = 500.0

# Camera follow
var cam_offset: Vector3
var cam_fixed_basis: Basis

# ===== STATE =====
var gravity: float

func initialize(player_node: CharacterBody3D, cam: Camera3D):
	"""Called by main player script to set references"""
	player = player_node
	camera = cam
	
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	
	# Initialize movement speed
	movement_speed = base_movement_speed
	
	# Store camera's initial global rotation and offset
	cam_fixed_basis = camera.global_transform.basis.orthonormalized()
	cam_offset = camera.global_transform.origin - player.global_transform.origin

func _process(delta: float):
	"""Handle camera zoom smoothing"""
	zoom_current = lerp(zoom_current, zoom_target, 1.0 - exp(-zoom_smooth * delta))
	_update_camera_global()

func handle_physics(delta: float, is_sprinting: bool, is_encumbered: bool, god_mode: bool):
	"""Handle all movement physics"""
	# Gravity
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	
	# Get input
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	# Calculate current speed
	var current_speed = movement_speed
	
	# Apply sprint multiplier
	if is_sprinting:
		current_speed *= sprint_multiplier
	
	# Apply speed modifiers (god mode, encumbered)
	current_speed *= _get_effective_speed_mult(is_encumbered, god_mode)
	
	# Apply movement
	if direction:
		player.velocity.x = direction.x * current_speed
		player.velocity.z = direction.z * current_speed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, current_speed)
		player.velocity.z = move_toward(player.velocity.z, 0, current_speed)
	
	# Rotate toward mouse cursor
	var encumbered_effects_active = is_encumbered and not god_mode
	_rotate_toward_mouse(encumbered_effects_active, is_sprinting)
	
	# Move the body
	player.move_and_slide()
	
	# Update camera position
	_update_camera_global()

func handle_camera_zoom(event: InputEventMouseButton):
	"""Handle mouse wheel camera zoom"""
	if not event.pressed:
		return
	
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_target -= zoom_speed
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_target += zoom_speed
	
	var current_max = god_zoom_max if player.god_mode else zoom_max
	zoom_target = clamp(zoom_target, zoom_min, current_max)

func _get_effective_speed_mult(is_encumbered: bool, god_mode: bool) -> float:
	"""Get current speed multiplier based on god mode and encumbered status"""
	var mult = 1.0
	
	if god_mode:
		mult *= player.GOD_SPEED_MULT
	
	# Apply encumbered penalty (only if not in god mode)
	if is_encumbered and not god_mode:
		mult *= ENCUMBERED_SPEED_MULT
	
	return mult

func _rotate_toward_mouse(apply_encumbered_penalty: bool = false, is_sprinting: bool = false):
	"""Rotate player toward mouse cursor"""
	var mouse_pos = player.get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 2000
	
	var hit_pos = _intersect_ray_with_plane(from, to, player.global_position.y)
	
	if hit_pos == Vector3.ZERO:
		return
	
	var look_dir = hit_pos - player.global_transform.origin
	look_dir.y = 0
	if look_dir.length() < 0.001:
		return
	
	var target_angle = atan2(-look_dir.x, -look_dir.z)
	var current_angle = player.rotation.y
	
	# Apply rotation speed with penalties
	var effective_rotation_speed = rotation_speed
	
	# Apply encumbered penalty
	if apply_encumbered_penalty:
		effective_rotation_speed *= ENCUMBERED_ROTATION_MULT
	
	# Apply sprint penalty (50% slower rotation while sprinting)
	if is_sprinting:
		effective_rotation_speed *= 0.5
	
	var new_angle = lerp_angle(current_angle, target_angle, effective_rotation_speed * player.get_physics_process_delta_time())
	player.rotation.y = new_angle

func _intersect_ray_with_plane(ray_origin: Vector3, ray_end: Vector3, plane_y: float) -> Vector3:
	"""Calculate intersection of ray with horizontal plane"""
	var ray_dir = (ray_end - ray_origin).normalized()
	
	if abs(ray_dir.y) < 0.001:
		return Vector3.ZERO
	
	var t = (plane_y - ray_origin.y) / ray_dir.y
	
	if t < 0:
		return Vector3.ZERO
	
	var intersection = ray_origin + ray_dir * t
	return intersection

func _update_camera_global():
	"""Update camera position to follow player"""
	var basis = cam_fixed_basis
	var zoom_dir := cam_offset.normalized()
	var zoomed_pos := zoom_dir * zoom_current
	zoomed_pos.y += zoom_current * 0.4
	var desired_origin = player.global_transform.origin + zoomed_pos
	camera.global_transform = Transform3D(basis, desired_origin)

func update_movement_speed():
	"""Recalculate movement speed from base + modifiers"""
	movement_speed = base_movement_speed
	# TODO: Add buff/debuff modifiers here
	# TODO: Add equipment speed bonuses here
