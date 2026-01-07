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
		# Check if still in range
		var distance = player.global_position.distance_to(nearby_enemy.global_position)
		if distance <= stats.attack_range:
			_perform_attack()
		else:
			print("Enemy out of range (%.1f / %.1f)" % [distance, stats.attack_range])
			play_combat("attack")
	else:
		play_combat("attack")

func _perform_attack():
	"""Execute attack on nearby enemy"""
	var is_crit = randf() < stats.crit_chance
	var final_damage = stats.damage
	
	if is_crit:
		final_damage = int(stats.damage * stats.crit_multiplier)
		print("Player CRITICAL HIT: %d damage" % final_damage)
	else:
		print("Player hit for %d damage" % final_damage)
	
	if nearby_enemy and nearby_enemy.has_method("take_damage"):
		nearby_enemy.take_damage(final_damage, is_crit)
	
	play_combat("hit")

func on_area_body_entered(body: Node3D):
	"""Called when body enters player's attack area"""
	if body.is_in_group("enemy"):
		var distance = player.global_position.distance_to(body.global_position)
		if distance <= stats.attack_range:
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
