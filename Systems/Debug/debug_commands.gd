# debug_commands.gd
# Main command processor - routes commands to specialized handlers
extends Node

# Reference to console for output
var console: Control = null

# Command handlers
var console_commands: Node
var player_commands: Node
var inventory_commands: Node
var world_commands: Node

func _ready():
	# Create command handlers
	print("[DebugCommands] Creating command handlers...")
	_create_handlers()
	print("[DebugCommands] Handlers created: console=%s, player=%s, inventory=%s, world=%s" % [
		console_commands != null,
		player_commands != null,
		inventory_commands != null,
		world_commands != null
	])

func _create_handlers():
	"""Create all command handler nodes"""
	# Console commands
	var console_script = load("res://Systems/Debug/Commands/debug_commands_console.gd")
	if console_script:
		console_commands = Node.new()
		console_commands.name = "ConsoleCommands"
		console_commands.set_script(console_script)
		add_child(console_commands)
	
	# Player commands
	var player_script = load("res://Systems/Debug/Commands/debug_commands_player.gd")
	if player_script:
		player_commands = Node.new()
		player_commands.name = "PlayerCommands"
		player_commands.set_script(player_script)
		add_child(player_commands)
	
	# Inventory commands
	var inventory_script = load("res://Systems/Debug/Commands/debug_commands_inventory.gd")
	if inventory_script:
		inventory_commands = Node.new()
		inventory_commands.name = "InventoryCommands"
		inventory_commands.set_script(inventory_script)
		add_child(inventory_commands)
	
	# World commands
	var world_script = load("res://Systems/Debug/Commands/debug_commands_world.gd")
	if world_script:
		world_commands = Node.new()
		world_commands.name = "WorldCommands"
		world_commands.set_script(world_script)
		add_child(world_commands)

func set_console(console_ref: Control):
	"""Set console reference for all handlers"""
	console = console_ref
	print("[DebugCommands] Console set: %s" % (console != null))
	
	if console_commands:
		console_commands.console = console
	if player_commands:
		player_commands.console = console
	if inventory_commands:
		inventory_commands.console = console
	if world_commands:
		world_commands.console = console

func toggle_console():
	"""Toggle the debug console visibility"""
	print("[DebugCommands] toggle_console called, console=%s" % (console != null))
	if console:
		print("[DebugCommands] Console has toggle_console method: %s" % console.has_method("toggle_console"))
	
	if console and console.has_method("toggle_console"):
		console.toggle_console()
	else:
		push_warning("Console not available or missing toggle_console method")

func process_command(command: String, output: Control):
	"""Process a debug command by routing to appropriate handler"""
	# Parse command and arguments
	var parts = command.split(" ", false)
	if parts.is_empty():
		return
	
	var cmd = parts[0].to_lower()
	var args = parts.slice(1) if parts.size() > 1 else []
	
	# Route to appropriate handler
	match cmd:
		# Console commands
		"help":
			if console_commands:
				console_commands.cmd_help(output, self)
		"clear":
			if console_commands:
				console_commands.cmd_clear(output)
		
		# Player commands
		"god":
			if player_commands:
				player_commands.cmd_god(output)
		"heal":
			if player_commands:
				player_commands.cmd_heal(args, output)
		"hurt":
			if player_commands:
				player_commands.cmd_hurt(args, output)
		"kill":
			if player_commands:
				player_commands.cmd_kill(output)
		"stat":
			if player_commands:
				player_commands.cmd_stat(args, output)
		"speed":
			if player_commands:
				player_commands.cmd_speed(args, output)
		"tp", "teleport":
			if player_commands:
				player_commands.cmd_teleport(args, output)
		
		# Inventory commands
		"give-gold":
			if inventory_commands:
				inventory_commands.cmd_give_gold(args, output)
		"spawn-item":
			if inventory_commands:
				inventory_commands.cmd_spawn_item(args, output)
		
		# World commands
		"time":
			if world_commands:
				world_commands.cmd_time(args, output)
		
		_:
			output.print_error("[color=#FF4D4D]Unknown command: '%s'. Type 'help' for available commands.[/color]" % cmd)
