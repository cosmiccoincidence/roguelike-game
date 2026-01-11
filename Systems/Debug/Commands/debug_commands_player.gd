# debug_commands_player.gd
# Player-specific commands
extends Node

var console: Control = null
var debug_manager: Node:
	get:
		return get_node_or_null("/root/DebugManager")

func cmd_teleport(args: Array, output: Control):
	"""Teleport player to coordinates"""
	if args.size() < 2:
		output.print_line("[color=#FFFF4D]Usage: tp <x> <z>[/color]")
		output.print_line("[color=#CCCCCC]Teleports to grid coordinates on the current map[/color]")
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		output.print_error("[color=#FF4D4D]Error: No player found[/color]")
		return
	
	# Parse coordinates
	var x = int(args[0])
	var z = int(args[1])
	
	# Look for PrimaryGridMap in the scene tree (recursive search from root)
	var primary_grid = get_tree().root.find_child("PrimaryGridMap", true, false)
	
	if not primary_grid:
		output.print_error("[color=#FF4D4D]Error: Could not find PrimaryGridMap in scene[/color]")
		output.print_line("[color=#FFFF4D]Make sure a map scene is loaded[/color]")
		return
	
	# Check if position is walkable
	if not primary_grid.has_method("is_position_walkable"):
		output.print_error("[color=#FF4D4D]Error: PrimaryGridMap has no is_position_walkable() method[/color]")
		output.print_line("[color=#FFFF4D]Script may not extend CoreMapGen properly[/color]")
		return
	
	if not primary_grid.is_position_walkable(x, z):
		output.print_error("[color=#FF4D4D]Error: Position (%d, %d) is not walkable[/color]" % [x, z])
		return
	
	# Convert grid to world position using map_to_local
	var world_pos = primary_grid.map_to_local(Vector3i(x, 0, z))
	world_pos.y = 0.5  # Set Y to player height
	
	# Teleport player
	player.global_position = world_pos
	output.print_line("[color=#7FFF7F]Teleported to grid: (%d, %d) → world: (%.1f, %.1f, %.1f)[/color]" % [x, z, world_pos.x, world_pos.y, world_pos.z])

func cmd_stat(args: Array, output: Control):
	"""Set player stat"""
	if args.size() < 2:
		output.print_line("[color=#FFFF4D]Usage: stat <n> <value>[/color]")
		output.print_line("[color=#CCCCCC]Stats: strength, dexterity, vitality, fortitude, agility, arcane[/color]")
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		output.print_line("[color=#FF4D4D]Error: No player found[/color]")
		return
	
	var stat_name = args[0].to_lower()
	var value = int(args[1])
	
	var stats = player.get_node_or_null("PlayerStats")
	if not stats:
		output.print_line("[color=#FF4D4D]Error: PlayerStats not found[/color]")
		return
	
	# Set the stat
	if stat_name in stats:
		# For the 6 core stats, we need to set the class base, not the calculated value
		var core_stats = ["strength", "dexterity", "fortitude", "vitality", "agility", "arcane"]
		
		if stat_name in core_stats:
			var class_stat_name = "class_" + stat_name
			stats.set(class_stat_name, value)
		else:
			stats.set(stat_name, value)
		
		# Force recalculate all stats
		if stats.has_method("recalculate_all_stats"):
			stats.recalculate_all_stats()
		
		# Emit stat changed signal if it exists
		if stats.has_signal("stats_updated"):
			stats.stats_updated.emit()
		elif stats.has_signal("stat_changed"):
			stats.stat_changed.emit(stat_name, value)
		elif stats.has_signal("stats_changed"):
			stats.stats_changed.emit()
		
		# Try to find and manually refresh the stats panel
		var stats_panel = get_tree().root.find_child("StatsPanel", true, false)
		if stats_panel and stats_panel.has_method("_update_stats_display"):
			stats_panel._update_stats_display()
		
		output.print_line("[color=#7FFF7F]Set %s to %d[/color]" % [stat_name, value])
	else:
		output.print_line("[color=#FF4D4D]Unknown stat: %s[/color]" % stat_name)

func cmd_die(output: Control):
	"""Kill the player"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		output.print_line("[color=#FF4D4D]Error: No player found[/color]")
		return
	
	# Get stats
	var stats = player.get_node_or_null("PlayerStats")
	if not stats:
		output.print_line("[color=#FF4D4D]Error: PlayerStats not found[/color]")
		return
	
	# Try to use take_damage with huge number to trigger death properly
	if player.has_method("take_damage"):
		player.take_damage(99999)
	elif stats and "current_health" in stats:
		# Directly set health to 0
		stats.current_health = 0
		
		# Force emit signal if it exists
		if stats.has_signal("health_changed"):
			stats.health_changed.emit(0, stats.max_health if "max_health" in stats else 100)
		
		# Trigger death method if it exists
		if player.has_method("die"):
			player.die()
	
	output.print_line("[color=#FF4D4D]Player killed[/color]")

func cmd_heal(args: Array, output: Control):
	"""Heal the player"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		output.print_line("[color=#FF4D4D]Error: No player found[/color]")
		return
	
	var amount = float(args[0]) if not args.is_empty() else -1.0
	
	# Get stats
	var stats = player.get_node_or_null("PlayerStats")
	if not stats:
		output.print_line("[color=#FF4D4D]Error: PlayerStats not found[/color]")
		return
	
	# Try to use heal method if available
	if player.has_method("heal"):
		if amount > 0:
			player.heal(amount)
		else:
			if "max_health" in stats:
				player.heal(stats.max_health)
	elif stats and "current_health" in stats:
		# Directly modify health
		if amount > 0:
			stats.current_health = min(stats.current_health + amount, stats.max_health if "max_health" in stats else 100)
		else:
			stats.current_health = stats.max_health if "max_health" in stats else 100
		
		# Force emit signal if it exists
		if stats.has_signal("health_changed"):
			stats.health_changed.emit(stats.current_health, stats.max_health if "max_health" in stats else 100)
	
	if amount > 0:
		output.print_line("[color=#7FFF7F]Healed for %d HP[/color]" % int(amount))
	else:
		output.print_line("[color=#7FFF7F]Fully healed[/color]")

func cmd_hurt(args: Array, output: Control):
	"""Damage the player"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		output.print_line("[color=#FF4D4D]Error: No player found[/color]")
		return
	
	var amount = float(args[0]) if not args.is_empty() else 10.0
	
	# Get stats
	var stats = player.get_node_or_null("PlayerStats")
	if not stats:
		output.print_line("[color=#FF4D4D]Error: PlayerStats not found[/color]")
		return
	
	# Try to use take_damage method if available
	if player.has_method("take_damage"):
		player.take_damage(amount)
	elif stats and "current_health" in stats:
		# Directly modify health
		stats.current_health = max(stats.current_health - amount, 0)
		
		# Force emit signal if it exists
		if stats.has_signal("health_changed"):
			stats.health_changed.emit(stats.current_health, stats.max_health if "max_health" in stats else 100)
	
	output.print_line("[color=#FF4D4D]Dealt %d damage to player[/color]" % int(amount))

func cmd_god(output: Control):
	"""Toggle god mode"""
	var debug_player = debug_manager.get_node_or_null("DebugPlayer")
	if debug_player and debug_player.has_method("toggle_god_mode"):
		debug_player.toggle_god_mode()
		output.print_line("[color=#FFFF4D]God mode toggled[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: DebugPlayer subsystem not available[/color]")

func cmd_speed(args: Array, output: Control):
	"""Set movement speed multiplier"""
	if args.is_empty():
		output.print_line("[color=#FFFF4D]Usage: speed <multiplier>[/color]")
		return
	
	var multiplier = float(args[0])
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		output.print_line("[color=#FF4D4D]Error: No player found[/color]")
		return
	
	if "speed" in player:
		var base_speed = player.get("base_speed") if "base_speed" in player else 5.0
		player.speed = base_speed * multiplier
		output.print_line("[color=#7FFF7F]Speed set to x%.1f[/color]" % multiplier)
	else:
		output.print_line("[color=#FF4D4D]Error: Player has no speed property[/color]")
