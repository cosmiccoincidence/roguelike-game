# debug_player.gd
# Debug functions for player manipulation
extends Node

var debug_manager: Node = null
var debug_ui: Control = null

func _ready():
	debug_manager = get_parent()
	if debug_manager:
		debug_ui = debug_manager.debug_ui

func toggle_god_mode():
	"""Toggle god mode for the player"""
	if not debug_manager or not debug_manager.debug_enabled:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("❌ No player found in scene!")
		return
	
	if not "god_mode" in player:
		print("❌ Player doesn't have god_mode variable!")
		return
	
	# Toggle god mode
	player.god_mode = !player.god_mode
	
	# Get stats component (new structure) or use player directly (old structure)
	var stats_component = player.get_node_or_null("PlayerStats")
	
	# Recalculate player stats
	if stats_component and stats_component.has_method("_update_combat_stats"):
		stats_component._update_combat_stats()
	elif player.has_method("_update_combat_stats"):
		player._update_combat_stats()
	
	# Update UI display
	if debug_ui:
		if player.god_mode:
			debug_ui.show_god_mode(player)
		else:
			debug_ui.hide_god_mode()
	
	# Print to console
	if player.god_mode:
		var god_speed_mult = player.get("GOD_SPEED_MULT")
		var god_crit_chance = 1.0
		var god_crit_mult = 2.0
		
		# Try to get from stats component
		if stats_component:
			god_crit_chance = stats_component.get("GOD_CRIT_CHANCE") if "GOD_CRIT_CHANCE" in stats_component else 1.0
			god_crit_mult = stats_component.get("GOD_CRIT_MULT") if "GOD_CRIT_MULT" in stats_component else 2.0
		elif "GOD_CRIT_CHANCE" in player:
			god_crit_chance = player.GOD_CRIT_CHANCE
			god_crit_mult = player.GOD_CRIT_MULT
		
		print("\n" + "=".repeat(50))
		print("⚡ GOD MODE ENABLED")
		print("=".repeat(50))
		print("  Speed: x%.1f" % god_speed_mult)
		print("  Crit Chance: %.0f%%" % (god_crit_chance * 100))
		print("  Crit Multiplier: x%.1f" % god_crit_mult)
		print("  Max Zoom: %.0f" % player.get("god_zoom_max"))
		print("  Encumbered penalties: DISABLED")
		print("  Stamina cost: DISABLED")
		print("  Damage taken: BLOCKED")
		print("=".repeat(50) + "\n")
	else:
		print("\n⚡ GOD MODE DISABLED\n")
		
		# Clamp zoom if it exceeds normal max
		if player.get("zoom_target") > player.get("zoom_max"):
			player.zoom_target = player.zoom_max
	
	# Refresh encumbered status UI
	var is_encumbered = false
	if stats_component and "is_encumbered" in stats_component:
		is_encumbered = stats_component.is_encumbered
	elif "is_encumbered" in player:
		is_encumbered = player.is_encumbered
	
	if stats_component and stats_component.has_method("_on_encumbered_status_changed"):
		stats_component._on_encumbered_status_changed(is_encumbered)
	elif player.has_method("_on_encumbered_status_changed"):
		player._on_encumbered_status_changed(is_encumbered)
