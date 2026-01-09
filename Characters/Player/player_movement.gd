# player_movement.gd
# Handles player movement, rotation, and camera controls
extends Node

var player: CharacterBody3D
var camera: Camera3D
var state_machine: Node  # Reference to state machine

# ===== MOVEMENT =====
@export_group("Movement")
@export var base_movement_speed: float = 5.0  # Base movement speed (can be modified by buffs/items)
@export var rotation_speed: float = 5.0
@export var sprint_multiplier: float = 1.5  # Sprint speed multiplier (spec)
@export var sprint_stamina_cost: float = 0.5  # Stamina per second while sprinting

# Dodge roll
@export var dodge_roll_speed: float = 15.0  # Speed during dodge roll
@export var dodge_roll_duration: float = 0.25  # How long the roll lasts (seconds)
@export var dodge_roll_cooldown: float = 1.0  # Cooldown between rolls (seconds)
@export var dodge_roll_stamina_cost: float = 5.0  # Stamina cost per roll
@export var dodge_roll_iframe_duration: float = 0.15  # Duration of invincibility frames (seconds)

# Dash
@export var dash_speed: float = 30.0  # Speed during dash (faster than roll)
@export var dash_duration: float = 0.15  # How long the dash lasts (seconds, shorter than roll)
@export var dash_cooldown: float = 2.0  # Cooldown between dashes (seconds, shorter than roll)
@export var dash_stamina_cost: float = 10.0  # Stamina cost per dash (cheaper than roll)

# Calculated movement speed (base + modifiers)
var movement_speed: float = 5.0

# Dodge roll state
var is_dodge_rolling: bool = false
var dodge_roll_timer: float = 0.0
var dodge_roll_cooldown_timer: float = 0.0
var dodge_roll_direction: Vector3 = Vector3.ZERO
var dodge_roll_iframe_timer: float = 0.0  # Invincibility frame timer

# Dash state
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO

# Encumbered penalties (only applied when not in god mode)
const ENCUMBERED_SPEED_MULT: float = 0.2  # 20% speed
const ENCUMBERED_ROTATION_MULT: float = 0.75  # 75% rotation speed
const SPRINT_ROTATION_MULT: float = 0.9  # 90% rotation while sprinting (spec - was 0.5)

# ===== CAMERA =====
@export_group("Camera")
@export var zoom_min: int = 75
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
	# state_machine will be set after initialization via set()
	
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	
	# Initialize movement speed
	movement_speed = base_movement_speed
	
	# Store camera's initial global rotation and offset
	cam_fixed_basis = camera.global_transform.basis.orthonormalized()
	cam_offset = camera.global_transform.origin - player.global_transform.origin

func _process(delta: float):
	"""Handle camera zoom smoothing and cooldowns"""
	zoom_current = lerp(zoom_current, zoom_target, 1.0 - exp(-zoom_smooth * delta))
	_update_camera_global()
	
	# Update dodge roll cooldown
	if dodge_roll_cooldown_timer > 0:
		dodge_roll_cooldown_timer -= delta
	
	# Update dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

func handle_physics(delta: float, is_sprinting: bool, is_encumbered: bool, god_mode: bool, stats_component: Node):
	"""Handle all movement physics"""
	# Gravity
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	
	# Handle sprint stamina consumption
	if is_sprinting and not god_mode and stats_component:
		stats_component.use_stamina(sprint_stamina_cost * delta)
	
	# Handle dodge roll timer
	if is_dodge_rolling:
		dodge_roll_timer -= delta
		if dodge_roll_timer <= 0:
			is_dodge_rolling = false
			dodge_roll_direction = Vector3.ZERO
	
	# Handle dash timer
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			dash_direction = Vector3.ZERO
	
	# Handle i-frame timer
	if dodge_roll_iframe_timer > 0:
		dodge_roll_iframe_timer -= delta
		if dodge_roll_iframe_timer <= 0:
			# I-frames ended
			if stats_component:
				stats_component.set_invincible(false)
	
	# Get input
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	# Calculate current speed
	var current_speed = movement_speed
	
	# Override with dash if active (highest priority)
	if is_dashing:
		current_speed = dash_speed
		direction = dash_direction
	# Override with dodge roll if active
	elif is_dodge_rolling:
		current_speed = dodge_roll_speed
		direction = dodge_roll_direction
	else:
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
	
	# Rotate toward mouse cursor (not during dodge roll or dash)
	if not is_dodge_rolling and not is_dashing:
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
	
	# Apply sprint penalty (10% slower rotation while sprinting - spec)
	if is_sprinting:
		effective_rotation_speed *= SPRINT_ROTATION_MULT  # 0.9
	
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

func try_dodge_roll(stats_component: Node, god_mode: bool) -> bool:
	"""
	Attempt to perform a dodge roll.
	Returns true if successful, false if on cooldown or not enough stamina.
	"""
	# Check if we can dodge roll in current state
	if state_machine and not state_machine.can_dodge_roll():
		print("Cannot dodge roll in current state!")
		return false
	
	# Can't dodge while already dodging (fallback if no state machine)
	if is_dodge_rolling:
		return false
	
	# Check cooldown
	if dodge_roll_cooldown_timer > 0:
		return false
	
	# Check stamina (unless god mode)
	if not god_mode:
		if stats_component.current_stamina < dodge_roll_stamina_cost:
			print("Not enough stamina to dodge roll!")
			return false
		# Consume stamina
		stats_component.use_stamina(dodge_roll_stamina_cost)
	
	# Get current movement direction
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	# If not moving, dodge backward (away from mouse)
	if input_dir.length() < 0.1:
		var mouse_pos = player.get_viewport().get_mouse_position()
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * 2000
		var hit_pos = _intersect_ray_with_plane(from, to, player.global_position.y)
		
		if hit_pos != Vector3.ZERO:
			var away_dir = (player.global_position - hit_pos).normalized()
			dodge_roll_direction = Vector3(away_dir.x, 0, away_dir.z)
		else:
			# Fallback: dodge backward relative to camera
			dodge_roll_direction = player.global_transform.basis.z
	else:
		# Dodge in movement direction
		dodge_roll_direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	# Start dodge roll
	is_dodge_rolling = true
	dodge_roll_timer = dodge_roll_duration
	dodge_roll_cooldown_timer = dodge_roll_cooldown
	
	# Activate invincibility frames
	dodge_roll_iframe_timer = dodge_roll_iframe_duration
	if stats_component:
		stats_component.set_invincible(true)
	
	# Update state machine
	if state_machine:
		state_machine.change_state(state_machine.State.DODGE_ROLLING)
	
	print("Dodge roll!")
	return true

func try_dash(stats_component: Node, god_mode: bool) -> bool:
	"""
	Attempt to perform a dash.
	Returns true if successful, false if on cooldown or not enough stamina.
	"""
	# Check if we can dash in current state
	if state_machine and not state_machine.can_dash():
		print("Cannot dash in current state!")
		return false
	
	# Can't dash while already dashing or dodge rolling (fallback if no state machine)
	if is_dashing or is_dodge_rolling:
		return false
	
	# Check cooldown
	if dash_cooldown_timer > 0:
		return false
	
	# Check stamina (unless god mode)
	if not god_mode:
		if stats_component.current_stamina < dash_stamina_cost:
			print("Not enough stamina to dash!")
			return false
		# Consume stamina
		stats_component.use_stamina(dash_stamina_cost)
	
	# Get current movement direction
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	# If not moving, dash toward mouse cursor
	if input_dir.length() < 0.1:
		var mouse_pos = player.get_viewport().get_mouse_position()
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * 2000
		var hit_pos = _intersect_ray_with_plane(from, to, player.global_position.y)
		
		if hit_pos != Vector3.ZERO:
			var toward_dir = (hit_pos - player.global_position).normalized()
			dash_direction = Vector3(toward_dir.x, 0, toward_dir.z)
		else:
			# Fallback: dash forward relative to player rotation
			dash_direction = -player.global_transform.basis.z
	else:
		# Dash in movement direction
		dash_direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	# Start dash
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	# Update state machine
	if state_machine:
		state_machine.change_state(state_machine.State.DASHING)
	
	print("Dash!")
	return true

func is_dash_ready() -> bool:
	"""Check if dash is off cooldown"""
	return dash_cooldown_timer <= 0 and not is_dashing and not is_dodge_rolling

func get_dash_cooldown_percent() -> float:
	"""Get dash cooldown as percentage (0.0 = ready, 1.0 = just used)"""
	if dash_cooldown <= 0:
		return 0.0
	return clamp(dash_cooldown_timer / dash_cooldown, 0.0, 1.0)

func is_dodge_roll_ready() -> bool:
	"""Check if dodge roll is off cooldown"""
	return dodge_roll_cooldown_timer <= 0 and not is_dodge_rolling

func get_dodge_roll_cooldown_percent() -> float:
	"""Get dodge roll cooldown as percentage (0.0 = ready, 1.0 = just used)"""
	if dodge_roll_cooldown <= 0:
		return 0.0
	return clamp(dodge_roll_cooldown_timer / dodge_roll_cooldown, 0.0, 1.0)
