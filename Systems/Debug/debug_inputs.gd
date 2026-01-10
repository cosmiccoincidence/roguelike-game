# debug_inputs.gd
# Handles all debug input events and delegates to appropriate subsystems
extends Node

var debug_manager: Node = null

func _ready():
	debug_manager = get_parent()

func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	
	if not debug_manager:
		return
	
	match event.keycode:
		KEY_F1:
			debug_manager.toggle_debug_system()
		KEY_F2:
			if debug_manager.debug_enabled:
				debug_manager.toggle_keybind_panel()
		KEY_F3:
			if debug_manager.debug_enabled:
				_delegate_to_subsystem("DebugPerformance", "toggle_performance_stats")
		KEY_INSERT:
			if debug_manager.debug_enabled:
				_delegate_to_subsystem("DebugPlayer", "toggle_god_mode")
		KEY_END:
			if debug_manager.debug_enabled:
				_delegate_to_subsystem("DebugMaps", "skip_level")
		KEY_BACKSLASH:
			if debug_manager.debug_enabled:
				_delegate_to_subsystem("DebugLoot", "spawn_test_loot")
		KEY_BRACKETLEFT:
			if debug_manager.debug_enabled:
				_delegate_to_subsystem("DebugCombat", "heal_player")
		KEY_BRACKETRIGHT:
			if debug_manager.debug_enabled:
				_delegate_to_subsystem("DebugCombat", "damage_player")
		KEY_COMMA:
			if debug_manager.debug_enabled:
				_delegate_to_subsystem("DebugTime", "advance_time")
		KEY_PERIOD:
			if debug_manager.debug_enabled:
				_delegate_to_subsystem("DebugTime", "freeze_time")
		KEY_M:
			if debug_manager.debug_enabled:
				_delegate_to_subsystem("DebugFOV", "toggle_fov_system")
		KEY_N:
			if debug_manager.debug_enabled:
				_delegate_to_subsystem("DebugFOV", "reset_explored_map")
		KEY_B:
			if debug_manager.debug_enabled:
				_delegate_to_subsystem("DebugFOV", "reveal_entire_map")

func _delegate_to_subsystem(subsystem_name: String, method_name: String):
	"""Helper to delegate to a subsystem method"""
	var subsystem = debug_manager.get_node_or_null(subsystem_name)
	if subsystem and subsystem.has_method(method_name):
		subsystem.call(method_name)
	else:
		print("⚠️  %s subsystem not found or missing method: %s" % [subsystem_name, method_name])
