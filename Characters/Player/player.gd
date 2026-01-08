# player.gd
# Main player controller - delegates to component scripts
extends CharacterBody3D

# ===== CONSTANTS =====
const GOD_SPEED_MULT := 2.0

# ===== NODE REFERENCES =====
@onready var audio_vocal: AudioStreamPlayer3D = $AudioVocal
@onready var audio_combat: AudioStreamPlayer3D = $AudioCombat
@onready var cam: Camera3D = $Camera3D
@onready var hud: CanvasLayer = get_node("/root/World/UI/HUD")

# Component scripts
@onready var stats: Node = $PlayerStats
@onready var combat: Node = $PlayerCombat
@onready var inventory_handler: Node = $PlayerInventory
@onready var movement: Node = $PlayerMovement

# ===== CHARACTER TRAITS =====
@export var hero_name: String = "Hero Name"

# ===== STATE VARIABLES =====
var god_mode := false
var is_dying: bool = false
var is_sprinting: bool = false

# ===== AUDIO =====
var vocal_sounds = {
	"grunt": preload("res://Assets/Audio/Characters/Grunt.wav")
}

# ===== INITIALIZATION =====

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Initialize component scripts
	stats.initialize(self)
	combat.initialize(self, stats, audio_combat)
	inventory_handler.initialize(self, cam)
	movement.initialize(self, cam)
	
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

func _process(delta):
	# Delegate camera zoom to movement component
	if movement:
		movement._process(delta)

func _physics_process(delta):
	# Block everything if dead
	if is_dying:
		return
	
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
	
	# Delegate all movement/rotation/camera to movement component
	if movement:
		movement.handle_physics(delta, is_sprinting, stats.is_encumbered, god_mode, stats)

# ===== COMBAT AREA SIGNALS =====

func _on_area_3d_body_entered(body: Node3D) -> void:
	combat.on_area_body_entered(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	combat.on_area_body_exited(body)

# ===== INPUT HANDLING =====

func _input(event):
	# Camera zoom - delegate to movement component
	if event is InputEventMouseButton and movement:
		movement.handle_camera_zoom(event)
	
	# Block other inputs if dead
	if is_dying:
		return
	
	# Dodge roll
	if event.is_action_pressed("dodge_roll"):
		if movement:
			movement.try_dodge_roll(stats, god_mode)
	
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
