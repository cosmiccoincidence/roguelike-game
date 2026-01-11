# player_combat.gd
# Handles all combat-related logic
extends Node

# Reference to main player
var player: CharacterBody3D
var stats: Node  # Reference to PlayerStats

# ===== AUDIO =====
var combat_sounds = {
	"attack": preload("res://Assets/Audio/Characters/Attack.wav"),
	"hit": preload("res://Assets/Audio/Characters/Hit.wav")
}

@onready var audio_combat: AudioStreamPlayer3D

# ===== STATE =====
var nearby_enemy = null

func initialize(player_node: CharacterBody3D, stats_node: Node, audio_node: AudioStreamPlayer3D):
	"""Called by main player script to set references"""
	player = player_node
	stats = stats_node
	audio_combat = audio_node

func handle_attack_input():
	"""Handle player attack input"""
	if player.is_dying:
		return
	
	if nearby_enemy:
		# Get attack range from equipped weapon
		var attack_range = _get_attack_range()
		
		# Check if still in range
		var distance = player.global_position.distance_to(nearby_enemy.global_position)
		if distance <= attack_range:
			_perform_attack()
		else:
			print("Enemy out of range (%.1f / %.1f)" % [distance, attack_range])
			play_combat("attack")
	else:
		play_combat("attack")

func _get_attack_range() -> float:
	"""Get current attack range from equipped weapon"""
	# Try to get weapon manager
	var weapon_manager = player.get_node_or_null("WeaponManager")
	if weapon_manager and weapon_manager.has_method("get_attack_range"):
		return weapon_manager.get_attack_range()
	
	# Fallback: check if stats has attack_range
	if stats and "attack_range" in stats:
		return stats.attack_range
	
	# Default melee range
	return 2.0

func _perform_attack():
	"""Execute attack on nearby enemy"""
	# Get damage stats from weapon/stats
	var base_damage = _get_damage()
	var crit_chance = _get_crit_chance()
	var crit_multiplier = _get_crit_multiplier()
	
	var is_crit = randf() < crit_chance
	var final_damage = base_damage
	
	if is_crit:
		final_damage = int(base_damage * crit_multiplier)
		print("Player CRITICAL HIT: %d damage" % final_damage)
	else:
		print("Player hit for %d damage" % final_damage)
	
	if nearby_enemy and nearby_enemy.has_method("take_damage"):
		nearby_enemy.take_damage(final_damage, is_crit)
	
	play_combat("hit")

func _get_damage() -> float:
	"""Get current damage from weapon/stats"""
	var weapon_manager = player.get_node_or_null("WeaponManager")
	if weapon_manager and weapon_manager.has_method("get_damage"):
		return weapon_manager.get_damage()
	
	# Fallback to stats
	if stats and "damage" in stats:
		return stats.damage
	
	# Default damage
	return 10.0

func _get_crit_chance() -> float:
	"""Get current crit chance"""
	# Check stats first (this is usually a derived stat)
	if stats and "crit_chance" in stats:
		return stats.crit_chance
	
	# Default crit chance
	return 0.05

func _get_crit_multiplier() -> float:
	"""Get current crit multiplier"""
	# Check stats first
	if stats and "crit_multiplier" in stats:
		return stats.crit_multiplier
	
	# Default crit multiplier
	return 2.0

func on_area_body_entered(body: Node3D):
	"""Called when body enters player's attack area"""
	if body.is_in_group("enemy"):
		# Get attack range from equipped weapon
		var attack_range = _get_attack_range()
		
		var distance = player.global_position.distance_to(body.global_position)
		if distance <= attack_range:
			nearby_enemy = body

func on_area_body_exited(body: Node3D):
	"""Called when body exits player's attack area"""
	if body == nearby_enemy:
		nearby_enemy = null

func play_combat(sound_name: String):
	"""Play a combat sound"""
	if combat_sounds.has(sound_name) and audio_combat:
		audio_combat.stream = combat_sounds[sound_name]
		audio_combat.play()
