# player_movement.gd
# Handles player movement, rotation, and physics
extends Node

var player: CharacterBody3D
var camera_controller: Node  # Reference to player_camera script
var state_machine: Node  # Reference to state machine

# ===== MOVEMENT =====
@export_group("Movement")
@export var base_movement_speed: float = 5.0  # Base movement speed (can be modified by buffs/items)
@export var rotation_speed: float = 5.0

# Dodge roll
@export var dodge_roll_speed: float = 20.0  # Speed during dodge roll
@export var dodge_roll_duration: float = 0.15  # How long the roll lasts (seconds)
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

# ===== STATE =====
var gravity: float

func initialize(player_node: CharacterBody3D, cam_controller: Node):
	"""Called by main player script to set references"""
	player = player_node
	camera_controller = cam_controller
	# state_machine will be set after initialization via set()
	
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	
	# Initialize movement speed
	movement_speed = base_movement_speed

func _process(delta: float):
	"""Handle cooldowns"""
	# Update dodge roll cooldown
	if dodge_roll_cooldown_timer > 0:
		dodge_roll_cooldown_timer -= delta
	
	# Update dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

func handle_physics(delta: float, is_encumbered: bool, god_mode: bool, stats_component: Node):
	"""Handle all movement physics"""
	# Gravity
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	
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
		_rotate_toward_mouse(encumbered_effects_active)
	
	# Move the body
	player.move_and_slide()

func _get_effective_speed_mult(is_encumbered: bool, god_mode: bool) -> float:
	"""Get current speed multiplier based on god mode and encumbered status"""
	var mult = 1.0
	
	if god_mode:
		mult *= player.GOD_SPEED_MULT
	
	# Apply encumbered penalty (only if not in god mode)
	if is_encumbered and not god_mode:
		mult *= ENCUMBERED_SPEED_MULT
	
	return mult

func _rotate_toward_mouse(apply_encumbered_penalty: bool = false):
	"""Rotate player toward mouse cursor"""
	if not camera_controller:
		return
	
	var camera = camera_controller.get_camera()
	if not camera:
		return
	
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
	# Don't dodge if console is open
	var debug_console_script = load("res://Systems/Debug/debug_console.gd")
	if debug_console_script and debug_console_script.is_console_open():
		return false
	
	# Check if we can dodge roll in current state
	if state_machine and not state_machine.can_dodge_roll():
		return false
	
	# Can't dodge while already dodging (fallback if no state machine)
	if is_dodge_rolling:
		return false
	
	# Check cooldown
	if dodge_roll_cooldown_timer > 0:
		return false
	
	# Get current movement direction
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	# Require directional input to dodge roll
	if input_dir.length() < 0.1:
		return false
	
	# Check stamina (unless god mode)
	if not god_mode:
		if stats_component.current_stamina < dodge_roll_stamina_cost:
			return false
		# Consume stamina
		stats_component.use_stamina(dodge_roll_stamina_cost)
	
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
	
	return true

func try_dash(stats_component: Node, god_mode: bool) -> bool:
	"""
	Attempt to perform a dash.
	Returns true if successful, false if on cooldown or not enough stamina.
	"""
	# Don't dash if console is open
	var debug_console_script = load("res://Systems/Debug/debug_console.gd")
	if debug_console_script and debug_console_script.is_console_open():
		return false
	
	# Check if we can dash in current state
	if state_machine and not state_machine.can_dash():
		return false
	
	# Can't dash while already dashing or dodge rolling (fallback if no state machine)
	if is_dashing or is_dodge_rolling:
		return false
	
	# Check cooldown
	if dash_cooldown_timer > 0:
		return false
	
	# Get current movement direction
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	# Require directional input to dash
	if input_dir.length() < 0.1:
		return false
	
	# Check stamina (unless god mode)
	if not god_mode:
		if stats_component.current_stamina < dash_stamina_cost:
			return false
		# Consume stamina
		stats_component.use_stamina(dash_stamina_cost)
	
	# Dash in movement direction
	dash_direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	# Start dash
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	# Update state machine
	if state_machine:
		state_machine.change_state(state_machine.State.DASHING)
	
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
