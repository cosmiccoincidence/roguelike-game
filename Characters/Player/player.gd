# player.gd
# Main player controller - delegates to component scripts
extends CharacterBody3D

# ===== CONSTANTS =====
const SPEED = 5.0
const GOD_SPEED_MULT := 2.0
const ENCUMBERED_SPEED_MULT: float = 0.2  # 20% speed
const ENCUMBERED_ROTATION_MULT: float = 0.75  # 75% rotation speed

# ===== NODE REFERENCES =====
@onready var audio_vocal: AudioStreamPlayer3D = $AudioVocal
@onready var audio_combat: AudioStreamPlayer3D = $AudioCombat
@onready var cam: Camera3D = $Camera3D
@onready var hud: CanvasLayer = get_node("/root/World/UI/HUD")

# Component scripts
@onready var stats: Node = $PlayerStats
@onready var combat: Node = $PlayerCombat
@onready var inventory_handler: Node = $PlayerInventory

# ===== CHARACTER TRAITS =====
@export var hero_name: String = "Hero Name"

# ===== MOVEMENT =====
@export_group("Movement")
@export var rotation_speed := 5.0
@export var sprint_multiplier := 3.0
@export var sprint_stamina_cost: float = 1.5

# ===== CAMERA =====
@export_group("Camera")
@export var zoom_min := 10
@export var zoom_max := 100
@export var zoom_speed := 15.0
@export var zoom_smooth := 8.0

# ===== STATE VARIABLES =====
var god_mode := false
var god_zoom_max := 500.0
var is_dying: bool = false
var is_sprinting: bool = false

var zoom_target := 75
var zoom_current := 75

# Camera follow
var cam_offset: Vector3
var cam_fixed_basis: Basis

# ===== AUDIO =====
var vocal_sounds = {
	"grunt": preload("res://Assets/Audio/Characters/Grunt.wav")
}

# ===== OTHER =====
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# ===== INITIALIZATION =====

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Store camera's initial global rotation and offset
	cam_fixed_basis = cam.global_transform.basis.orthonormalized()
	cam_offset = cam.global_transform.origin - global_transform.origin
	
	# Initialize component scripts
	stats.initialize(self)
	combat.initialize(self, stats, audio_combat)
	inventory_handler.initialize(self, cam)
	
	# Connect component signals
	stats.health_changed.connect(_on_health_changed)
	stats.stamina_changed.connect(_on_stamina_changed)
	stats.encumbered_changed.connect(_on_encumbered_changed)
	
	# Update HUD after everything is set up
	if hud:
		await get_tree().process_frame
		hud.update_health(stats.current_health, stats.max_health)
		hud.update_stamina(stats.current_stamina, stats.max_stamina)

# ===== COMPONENT SIGNAL HANDLERS =====

func _on_health_changed(current: int, max_value: int):
	if hud:
		hud.update_health(current, max_value)

func _on_stamina_changed(current: float, max_value: float):
	if hud:
		hud.update_stamina(current, max_value)

func _on_encumbered_changed(is_encumbered: bool, effects_active: bool):
	if hud and hud.has_method("update_encumbered_status"):
		hud.update_encumbered_status(is_encumbered, effects_active)

# ===== DEATH =====

func die():
	if is_dying:
		return
	
	is_dying = true
	print("Player died!")
	
	# Show death message
	if hud:
		hud.show_death_message()
	
	# Play death grunt
	play_vocal("grunt")
	
	# Hide the player mesh but keep the node
	for child in get_children():
		if child is MeshInstance3D:
			child.visible = false
		elif child is CollisionShape3D:
			child.disabled = true

# ===== PHYSICS & MOVEMENT =====

func _physics_process(delta):
	# Always update camera zoom (even when dead)
	zoom_current = lerp(zoom_current, zoom_target, 1.0 - exp(-zoom_smooth * delta))
	_update_camera_global()
	
	# Block everything else if dead
	if is_dying:
		return
	
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Sprint logic
	var wants_to_sprint = Input.is_action_pressed("sprint")
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var is_moving = input_dir.length() > 0
	var encumbered_effects_active = stats.is_encumbered and not god_mode
	
	# Can only sprint if moving, have stamina (or god mode), AND not encumbered (or god mode)
	if wants_to_sprint and is_moving and (stats.current_stamina > 0 or god_mode) and not encumbered_effects_active:
		is_sprinting = true
	else:
		is_sprinting = false
	
	# Update sprint state in stats component
	stats.update_sprint_state(is_sprinting, delta)
	
	# Movement
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	var current_speed := SPEED
	
	# Apply sprint multiplier
	if is_sprinting:
		current_speed *= sprint_multiplier
	
	# Apply speed modifiers (god mode, encumbered)
	current_speed *= _get_effective_speed_mult()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	# Rotate toward mouse cursor
	_rotate_toward_mouse(encumbered_effects_active)
	
	# Move the body
	move_and_slide()
	
	# Update camera position
	_update_camera_global()

func _get_effective_speed_mult() -> float:
	"""Get current speed multiplier based on god mode and encumbered status"""
	var mult = 1.0
	
	if god_mode:
		mult *= GOD_SPEED_MULT
	
	# Apply encumbered penalty (only if not in god mode)
	if stats.is_encumbered and not god_mode:
		mult *= ENCUMBERED_SPEED_MULT
	
	return mult

# ===== ROTATION & CAMERA =====

func _rotate_toward_mouse(apply_encumbered_penalty: bool = false):
	var mouse_pos = get_viewport().get_mouse_position()
	var from = cam.project_ray_origin(mouse_pos)
	var to = from + cam.project_ray_normal(mouse_pos) * 2000
	
	var hit_pos = intersect_ray_with_plane(from, to, global_position.y)
	
	if hit_pos == Vector3.ZERO:
		return
	
	var look_dir = hit_pos - global_transform.origin
	look_dir.y = 0
	if look_dir.length() < 0.001:
		return
	
	var target_angle = atan2(-look_dir.x, -look_dir.z)
	var current_angle = rotation.y
	
	# Apply rotation speed with encumbered penalty
	var effective_rotation_speed = rotation_speed
	if apply_encumbered_penalty:
		effective_rotation_speed *= ENCUMBERED_ROTATION_MULT
	
	var new_angle = lerp_angle(current_angle, target_angle, effective_rotation_speed * get_physics_process_delta_time())
	rotation.y = new_angle

func intersect_ray_with_plane(ray_origin: Vector3, ray_end: Vector3, plane_y: float) -> Vector3:
	var ray_dir = (ray_end - ray_origin).normalized()
	
	if abs(ray_dir.y) < 0.001:
		return Vector3.ZERO
	
	var t = (plane_y - ray_origin.y) / ray_dir.y
	
	if t < 0:
		return Vector3.ZERO
	
	var intersection = ray_origin + ray_dir * t
	return intersection

func _update_camera_global():
	var basis = cam_fixed_basis
	var zoom_dir := cam_offset.normalized()
	var zoomed_pos := zoom_dir * zoom_current
	zoomed_pos.y += zoom_current * 0.4
	var desired_origin = global_transform.origin + zoomed_pos
	cam.global_transform = Transform3D(basis, desired_origin)

# ===== COMBAT AREA SIGNALS =====

func _on_area_3d_body_entered(body: Node3D) -> void:
	combat.on_area_body_entered(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	combat.on_area_body_exited(body)

# ===== INPUT HANDLING =====

func _input(event):
	# Camera zoom (works even when dead)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_target -= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_target += zoom_speed
		
		var current_max = god_zoom_max if god_mode else zoom_max
		zoom_target = clamp(zoom_target, zoom_min, current_max)
	
	# Block other inputs if dead
	if is_dying:
		return
	
	# Attack
	if event.is_action_pressed("attack"):
		combat.handle_attack_input()
	
	# Pickup items
	if event.is_action_pressed("pickup"):
		inventory_handler.handle_pickup_input()

# ===== AUDIO =====

func play_vocal(name: String):
	if vocal_sounds.has(name):
		audio_vocal.stream = vocal_sounds[name]
		audio_vocal.play()
