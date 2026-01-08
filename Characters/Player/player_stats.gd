# player_stats.gd
# Handles all player stats, health, stamina, and stat calculations
extends Node

# Reference to main player
var player: CharacterBody3D

# ===== CORE STATS =====
@export_group("Core Stats")
@export var strength := 5
@export var dexterity := 5
@export var luck: float = 0.0  # Affects item quality rolls

# ===== HEALTH & STAMINA =====
@export_group("Health & Stamina")
@export var max_health := 50
@export var health_regen: float = 1.0  # HP per interval
@export var health_regen_interval: float = 10.0  # Seconds between regen

@export var max_stamina := 50
@export var stamina_regen: float = 1.0  # Stamina per interval
@export var stamina_regen_interval: float = 0.5  # Seconds between regen

@export var heat_resistence := 10
@export var cold_resistence := 10
@export var static_resistence := 10
@export var poison_resistence := 10

# ===== COMBAT STATS =====
@export_group("Combat Base Stats")
@export var base_armor := 5
@export var base_damage := 5
@export var base_attack_range := 1.5
@export var base_attack_speed := 1.0
@export var base_crit_chance := 0.1
@export var base_crit_multiplier: float = 1.0
@export var base_block_rating := 1.0
@export var base_parry_window := 1.0

# Calculated combat stats (modified by gear/buffs/god mode)
var armor: int = 5
var damage: int = 5
var attack_range: float = 1.5
var attack_speed: float = 1.0
var crit_chance: float = 0.1
var crit_multiplier: float = 1.0
var block_rating: float = 1.0
var parry_window: float = 1.0

# ===== STATE VARIABLES =====
var current_health: int
var current_stamina: float

# Regen timers
var stamina_regen_delay: float = 1.0  # Delay after sprint stops
var time_since_sprint_stopped: float = 0.0
var time_since_last_stamina_regen: float = 0.0
var time_since_last_health_regen: float = 0.0

# Status
var is_encumbered: bool = false
var is_invincible: bool = false  # Invincibility frames (i-frames)

# God Mode constants
const GOD_CRIT_CHANCE := 1.0  # 100% crit
const GOD_CRIT_MULT := 2.0  # 2x damage multiplier

# Signals
signal health_changed(current, max_value)
signal stamina_changed(current, max_value)
signal stats_updated
signal encumbered_changed(is_encumbered: bool, effects_active: bool)

func _ready():
	current_health = max_health
	current_stamina = max_stamina
	
	# Connect to Equipment changes
	Equipment.equipment_changed.connect(_on_equipment_changed)
	
	# Connect to Inventory encumbered status
	Inventory.encumbered_status_changed.connect(_on_encumbered_status_changed)

func initialize(player_node: CharacterBody3D):
	"""Called by main player script to set reference"""
	player = player_node
	
	# NOW we can update stats (player reference is set)
	_update_combat_stats()

func _process(delta):
	if player.is_dying:
		return
	
	_process_health_regen(delta)
	_process_stamina_regen(delta)

# ===== HEALTH & STAMINA =====

func _process_health_regen(delta: float):
	"""Handle health regeneration"""
	if current_health < max_health:
		time_since_last_health_regen += delta
		if time_since_last_health_regen >= health_regen_interval:
			current_health = min(max_health, current_health + int(health_regen))
			time_since_last_health_regen = 0.0
			health_changed.emit(current_health, max_health)

func _process_stamina_regen(delta: float):
	"""Handle stamina regeneration"""
	if not player.is_sprinting and time_since_sprint_stopped >= stamina_regen_delay:
		if current_stamina < max_stamina:
			time_since_last_stamina_regen += delta
			if time_since_last_stamina_regen >= stamina_regen_interval:
				current_stamina = min(max_stamina, current_stamina + stamina_regen)
				time_since_last_stamina_regen = 0.0
				stamina_changed.emit(current_stamina, max_stamina)
	else:
		time_since_last_stamina_regen = 0.0

func update_sprint_state(is_sprinting: bool, delta: float):
	"""Called by player to update sprint-related timers (stamina consumption is in player_movement)"""
	if is_sprinting:
		time_since_sprint_stopped = 0.0
	else:
		time_since_sprint_stopped += delta

func take_damage(amount: int):
	"""Apply damage to player"""
	if player.god_mode:
		print("God Mode: Damage blocked")
		return
	
	# Check invincibility frames
	if is_invincible:
		print("I-frames: Damage blocked")
		return
	
	# Apply armor reduction
	var damage_taken = max(1, amount - armor)
	current_health = max(0, current_health - damage_taken)
	
	print("Player took %d damage (%d reduced by %d armor)" % [damage_taken, amount, armor])
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		player.die()

func use_stamina(amount: float):
	"""Consume stamina"""
	if player.god_mode:
		return
	
	current_stamina = max(0, current_stamina - amount)
	stamina_changed.emit(current_stamina, max_stamina)

# ===== STAT CALCULATIONS =====

func _update_combat_stats():
	"""Recalculate combat stats based on base stats, equipment, buffs, and god mode"""
	var equip_stats = Equipment.get_equipment_stats()
	
	if player.god_mode:
		# God mode bonuses
		crit_chance = GOD_CRIT_CHANCE
		crit_multiplier = base_crit_multiplier * GOD_CRIT_MULT
		
		# Equipment still applies
		damage = base_damage + equip_stats.weapon_damage
		armor = base_armor + equip_stats.base_armor_rating
		
		# Use weapon stats if equipped
		if equip_stats.has_weapon:
			attack_range = equip_stats.weapon_range
			attack_speed = equip_stats.weapon_speed
			block_rating = equip_stats.weapon_block_rating
			parry_window = equip_stats.weapon_parry_window
		else:
			attack_range = base_attack_range
			attack_speed = base_attack_speed
			block_rating = base_block_rating
			parry_window = base_parry_window
	else:
		# Normal mode
		damage = base_damage + equip_stats.weapon_damage
		armor = base_armor + equip_stats.base_armor_rating
		
		if equip_stats.has_weapon:
			attack_range = equip_stats.weapon_range
			attack_speed = equip_stats.weapon_speed
			block_rating = equip_stats.weapon_block_rating
			parry_window = equip_stats.weapon_parry_window
			crit_chance = equip_stats.weapon_crit_chance
			crit_multiplier = equip_stats.weapon_crit_multiplier
		else:
			attack_range = base_attack_range
			attack_speed = base_attack_speed
			block_rating = base_block_rating
			parry_window = base_parry_window
			crit_chance = base_crit_chance
			crit_multiplier = base_crit_multiplier
	
	stats_updated.emit()

func get_total_luck() -> float:
	"""Get total luck including equipment and buffs"""
	var total = luck
	# TODO: Add luck from equipment
	# TODO: Add luck from buffs/debuffs
	return total

func _on_equipment_changed():
	"""Called when equipment changes"""
	_update_combat_stats()

func _on_encumbered_status_changed(encumbered: bool):
	"""Called when inventory mass changes encumbered state"""
	is_encumbered = encumbered
	var effects_active = is_encumbered and not player.god_mode
	encumbered_changed.emit(is_encumbered, effects_active)

func set_invincible(invincible: bool):
	"""Set invincibility state (for i-frames, dodge roll, etc.)"""
	is_invincible = invincible
