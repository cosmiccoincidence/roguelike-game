# player_camera.gd
# Handles camera positioning, zoom, and follow behavior
extends Node

var player: CharacterBody3D
var camera: Camera3D

# ===== ZOOM =====
@export_group("Zoom")
@export var zoom_min: int = 25
@export var zoom_max: int = 175
@export var zoom_speed: float = 15.0
@export var zoom_smooth: float = 8.0

var zoom_target: float = 50.0
var zoom_current: float = 50.0

# ===== CAMERA FOLLOW =====
@export_group("Camera Follow")
@export var vertical_offset_multiplier: float = 0.4  # How much the camera rises with zoom

var cam_offset: Vector3
var cam_fixed_basis: Basis

func initialize(player_node: CharacterBody3D):
	"""Called by main player script to set references"""
	player = player_node
	camera = get_parent() as Camera3D  # Get camera from parent node
	
	if not camera:
		push_error("player_camera.gd must be attached to a Camera3D node!")
		return
	
	# Store camera's initial global rotation (basis) and offset from player
	cam_fixed_basis = camera.global_transform.basis.orthonormalized()
	cam_offset = camera.global_transform.origin - player.global_transform.origin
	
	# Initialize zoom to max_zoom for standard starting height
	zoom_target = zoom_max
	zoom_current = zoom_max
	
	# Apply initial position immediately
	update_camera_position()

func _process(delta: float):
	"""Handle camera zoom smoothing and position updates"""
	# Don't update if not initialized
	if not player or not camera:
		return
	
	# Smooth zoom interpolation
	zoom_current = lerp(zoom_current, zoom_target, 1.0 - exp(-zoom_smooth * delta))
	
	# Update camera position to follow player
	update_camera_position()

func handle_camera_zoom(event: InputEventMouseButton):
	"""Handle mouse wheel camera zoom"""
	if not event.pressed:
		return
	
	# Don't zoom if debug console is open
	var debug_console_script = load("res://Systems/Debug/debug_console.gd")
	if debug_console_script and debug_console_script.is_console_open():
		return
	
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_target -= zoom_speed
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_target += zoom_speed
	
	# Clamp zoom
	zoom_target = clamp(zoom_target, zoom_min, zoom_max)

func update_camera_position():
	"""Update camera position to follow player with current zoom"""
	if not player or not camera:
		return
	
	var basis = cam_fixed_basis
	var zoom_dir := cam_offset.normalized()
	var zoomed_pos := zoom_dir * zoom_current
	
	# Add vertical offset based on zoom (camera rises as you zoom out)
	zoomed_pos.y += zoom_current * vertical_offset_multiplier
	
	var desired_origin = player.global_transform.origin + zoomed_pos
	camera.global_transform = Transform3D(basis, desired_origin)

func get_camera_basis() -> Basis:
	"""Get the fixed camera basis for calculations"""
	return cam_fixed_basis

func get_camera() -> Camera3D:
	"""Get the camera node reference"""
	return camera
