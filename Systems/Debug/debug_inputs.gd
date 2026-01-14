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
	
	# Check if console is open - block all input except F1
	const DebugConsole = preload("res://Systems/Debug/debug_console.gd")
	if DebugConsole.is_console_open():
		# Only allow F1 to pass through (to disable debug mode)
		if event.keycode != KEY_F1:
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
		KEY_F4:
			if debug_manager.debug_enabled:
				_delegate_to_subsystem("DebugCommands", "toggle_console")
		KEY_INSERT:
			if debug_manager.debug_enabled:
				_execute_command("god")
		KEY_END:
			if debug_manager.debug_enabled:
				_execute_command("skip-level")
		KEY_BACKSLASH:
			if debug_manager.debug_enabled:
				_execute_command("spawn-item")
		KEY_BRACKETLEFT:
			if debug_manager.debug_enabled:
				_execute_command("heal")
		KEY_BRACKETRIGHT:
			if debug_manager.debug_enabled:
				_execute_command("hurt")
		KEY_COMMA:
			if debug_manager.debug_enabled:
				_execute_command("time")
		KEY_PERIOD:
			if debug_manager.debug_enabled:
				_execute_command("time-freeze")
		KEY_M:
			if debug_manager.debug_enabled:
				_execute_command("fov")
		KEY_N:
			if debug_manager.debug_enabled:
				_execute_command("unexplore")
		KEY_B:
			if debug_manager.debug_enabled:
				_execute_command("explore")

func _execute_command(command: String):
	"""Execute a debug command programmatically"""
	var debug_commands = debug_manager.get_node_or_null("DebugCommands")
	if debug_commands and debug_commands.has_method("process_command"):
		# Create a dummy output that doesn't display anything
		var silent_output = Node.new()
		silent_output.set_script(preload("res://Systems/Debug/debug_console.gd"))
		debug_commands.process_command(command, silent_output)
		silent_output.queue_free()
	else:
		print("⚠️  DebugCommands not found")

func _delegate_to_subsystem(subsystem_name: String, method_name: String):
	"""Helper to delegate to a subsystem method"""
	var subsystem = debug_manager.get_node_or_null(subsystem_name)
	if subsystem and subsystem.has_method(method_name):
		subsystem.call(method_name)
	else:
		print("⚠️  %s subsystem not found or missing method: %s" % [subsystem_name, method_name])
