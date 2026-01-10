# debug_manager.gd
# Core debug system manager - handles debug state and delegates to subsystems
extends Node

# Debug state
var debug_enabled: bool = false
var keybind_panel_visible: bool = false

# References
var debug_ui: Control = null

signal debug_toggled(enabled: bool)
signal keybind_panel_toggled(visible: bool)

func _ready():
	print("[DEBUG MANAGER] Ready - Press F1 to enable debug mode")
	
	# Create debug UI
	_setup_debug_ui()
	
	# Auto-create debug subsystems
	_setup_subsystems()

func _setup_subsystems():
	"""Automatically create debug subsystem nodes"""
	# Create DebugInputs (for input handling)
	if not has_node("DebugInputs"):
		var debug_inputs_script = load("res://Systems/Debug/debug_inputs.gd")
		if debug_inputs_script:
			var debug_inputs = Node.new()
			debug_inputs.name = "DebugInputs"
			debug_inputs.set_script(debug_inputs_script)
			add_child(debug_inputs)
		else:
			push_warning("Could not load debug_inputs.gd")
	
	# Create DebugLoot
	if not has_node("DebugLoot"):
		var debug_loot_script = load("res://Systems/Debug/Systems/debug_loot.gd")
		if debug_loot_script:
			var debug_loot = Node.new()
			debug_loot.name = "DebugLoot"
			debug_loot.set_script(debug_loot_script)
			add_child(debug_loot)
		else:
			push_warning("Could not load debug_loot.gd from Debug/Systems folder")
	
	# Create DebugCombat
	if not has_node("DebugCombat"):
		var debug_combat_script = load("res://Systems/Debug/Systems/debug_combat.gd")
		if debug_combat_script:
			var debug_combat = Node.new()
			debug_combat.name = "DebugCombat"
			debug_combat.set_script(debug_combat_script)
			add_child(debug_combat)
		else:
			push_warning("Could not load debug_combat.gd from Debug/Systems folder")
	
	# Create DebugTime
	if not has_node("DebugTime"):
		var debug_time_script = load("res://Systems/Debug/Systems/debug_time.gd")
		if debug_time_script:
			var debug_time = Node.new()
			debug_time.name = "DebugTime"
			debug_time.set_script(debug_time_script)
			add_child(debug_time)
		else:
			push_warning("Could not load debug_time.gd from Debug/Systems folder")
	
	# Create DebugFOV
	if not has_node("DebugFOV"):
		var debug_fov_script = load("res://Systems/Debug/Systems/debug_fov.gd")
		if debug_fov_script:
			var debug_fov = Node.new()
			debug_fov.name = "DebugFOV"
			debug_fov.set_script(debug_fov_script)
			add_child(debug_fov)
		else:
			push_warning("Could not load debug_fov.gd from Debug/Systems folder")
	
	# Create DebugPlayer
	if not has_node("DebugPlayer"):
		var debug_player_script = load("res://Systems/Debug/Systems/debug_player.gd")
		if debug_player_script:
			var debug_player = Node.new()
			debug_player.name = "DebugPlayer"
			debug_player.set_script(debug_player_script)
			add_child(debug_player)
		else:
			push_warning("Could not load debug_player.gd from Debug/Systems folder")
	
	# Create DebugMaps
	if not has_node("DebugMaps"):
		var debug_maps_script = load("res://Systems/Debug/Systems/debug_maps.gd")
		if debug_maps_script:
			var debug_maps = Node.new()
			debug_maps.name = "DebugMaps"
			debug_maps.set_script(debug_maps_script)
			add_child(debug_maps)
		else:
			push_warning("Could not load debug_maps.gd from Debug/Systems folder")
	
	# Create DebugPerformance
	if not has_node("DebugPerformance"):
		var debug_performance_script = load("res://Systems/Debug/Systems/debug_performance.gd")
		if debug_performance_script:
			var debug_performance = Node.new()
			debug_performance.name = "DebugPerformance"
			debug_performance.set_script(debug_performance_script)
			add_child(debug_performance)
		else:
			push_warning("Could not load debug_performance.gd from Debug/Systems folder")

func toggle_debug_system():
	"""Toggle the entire debug system on/off"""
	debug_enabled = !debug_enabled
	
	if debug_enabled:
		print("🔧 DEBUG MODE ENABLED")
		
		# Show enabled indicator
		if debug_ui:
			debug_ui.show_debug_enabled()
	else:
		print("🔧 DEBUG MODE DISABLED")
		
		# Disable god mode if active (delegate to debug_player)
		var debug_player = get_node_or_null("DebugPlayer")
		var player = get_tree().get_first_node_in_group("player")
		if player and player.get("god_mode") and player.god_mode:
			if debug_player and debug_player.has_method("toggle_god_mode"):
				debug_player.toggle_god_mode()
			else:
				# Fallback if debug_player not available
				player.god_mode = false
				var stats_component = player.get_node_or_null("PlayerStats")
				if stats_component and stats_component.has_method("_update_combat_stats"):
					stats_component._update_combat_stats()
				elif player.has_method("_update_combat_stats"):
					player._update_combat_stats()
				print("⚡ God mode disabled")
		
		# Hide performance stats
		var debug_performance = get_node_or_null("DebugPerformance")
		if debug_performance and debug_performance.has_method("hide_performance_stats"):
			debug_performance.hide_performance_stats()
		
		# Hide all debug UI
		keybind_panel_visible = false
		if debug_ui:
			debug_ui.hide_all()
	
	debug_toggled.emit(debug_enabled)

func toggle_keybind_panel():
	"""Toggle the keybind reference panel"""
	if not debug_enabled:
		return
	
	keybind_panel_visible = !keybind_panel_visible
	
	if debug_ui:
		if keybind_panel_visible:
			debug_ui.show_keybind_panel()
		else:
			debug_ui.hide_keybind_panel()
	
	keybind_panel_toggled.emit(keybind_panel_visible)

func _setup_debug_ui():
	"""Create the debug UI node"""
	var ui_scene_path = "res://Systems/UserInterface/Debug/debug_ui.tscn"
	
	if ResourceLoader.exists(ui_scene_path):
		var ui_scene = load(ui_scene_path)
		debug_ui = ui_scene.instantiate()
		add_child(debug_ui)
	else:
		push_error("❌ Debug UI scene not found at: %s" % ui_scene_path)
