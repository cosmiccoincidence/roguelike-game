# debug_commands.gd
# Processes commands from the debug console
extends Node

var debug_manager: Node = null
var console: Control = null

func _ready():
	debug_manager = get_parent()

func set_console(console_ref: Control):
	"""Set the console reference"""
	console = console_ref

func toggle_console():
	"""Toggle the console visibility"""
	if console and console.has_method("toggle_console"):
		console.toggle_console()

func process_command(command: String, output: Control):
	"""Process a debug command"""
	# Parse command and arguments
	var parts = command.split(" ", false)
	if parts.is_empty():
		return
	
	var cmd = parts[0].to_lower()
	var args = parts.slice(1) if parts.size() > 1 else []
	
	# Execute command
	match cmd:
		"help":
			_cmd_help(output)
		"clear":
			_cmd_clear(output)
		"spawn-item":
			_cmd_spawn_item(args, output)
		"tp", "teleport":
			_cmd_teleport(args, output)
		"give-gold":
			_cmd_give_gold(args, output)
		"stat":
			_cmd_stat(args, output)
		"kill":
			_cmd_kill(args, output)
		"heal":
			_cmd_heal(args, output)
		"god":
			_cmd_god(output)
		"speed":
			_cmd_speed(args, output)
		"time":
			_cmd_time(args, output)
		_:
			output.print_error("[color=#FF4D4D]Unknown command: '%s'. Type 'help' for available commands.[/color]" % cmd)

func _cmd_help(output: Control):
	"""Show help for all commands"""
	output.print_line("[color=#4DAAFF]═══ AVAILABLE COMMANDS ═══[/color]")
	output.print_line("[color=#7FFF7F]help[/color] - Show this help")
	output.print_line("[color=#7FFF7F]clear[/color] - Clear console output")
	output.print_line("[color=#7FFF7F]spawn-item [type] [subtype] [name] [level] [quality] x[qty][/color] - Spawn item")
	output.print_line("  - All fields optional, order-independent")
	output.print_line("  - Quality: common, uncommon, rare, epic, legendary, mythic")
	output.print_line("  - Ex: spawn-item Sword 10 epic x5")
	output.print_line("[color=#7FFF7F]give-gold [amount][/color] - Give gold (default: 1000)")
	output.print_line("[color=#7FFF7F]tp <x> <y> <z>[/color] - Teleport player")
	output.print_line("[color=#7FFF7F]stat <name> <value>[/color] - Set player stat")
	output.print_line("[color=#7FFF7F]heal [amount][/color] - Heal player")
	output.print_line("[color=#7FFF7F]kill[/color] - Kill player")
	output.print_line("[color=#7FFF7F]god[/color] - Toggle god mode")
	output.print_line("[color=#7FFF7F]speed <multiplier>[/color] - Set movement speed")
	output.print_line("[color=#7FFF7F]time <hour>[/color] - Set time of day")

func _cmd_clear(output: Control):
	"""Clear console output"""
	output.clear_output()
	output.print_line("[color=#4DAAFF]Console cleared[/color]")

func _cmd_give_gold(args: Array, output: Control):
	"""Give gold to player"""
	var amount = 1000  # Default amount
	
	# Parse amount if provided
	if args.size() > 0 and args[0].is_valid_int():
		amount = int(args[0])
	
	# Get Inventory autoload
	var inventory = get_node_or_null("/root/Inventory")
	if not inventory:
		output.print_error("[color=#FF4D4D]Error: Inventory autoload not found[/color]")
		output.print_line("[color=#FFFF4D]Make sure 'Inventory' is set up as an autoload[/color]")
		return
	
	# Check if it has InventoryGold as a child or property
	var inventory_gold = null
	
	# Try to get InventoryGold child node
	if inventory.has_node("InventoryGold"):
		inventory_gold = inventory.get_node("InventoryGold")
	# Or check if inventory itself has the add_gold method
	elif inventory.has_method("add_gold"):
		inventory_gold = inventory
	# Or check children for the gold script
	else:
		for child in inventory.get_children():
			if child.has_method("add_gold"):
				inventory_gold = child
				break
	
	if not inventory_gold:
		output.print_error("[color=#FF4D4D]Error: Could not find gold system in Inventory autoload[/color]")
		output.print_line("[color=#FFFF4D]Searched for add_gold() method in Inventory and its children[/color]")
		return
	
	# Add gold
	if inventory_gold.has_method("add_gold"):
		var old_gold = inventory_gold.gold if "gold" in inventory_gold else 0
		inventory_gold.add_gold(amount)
		var new_gold = inventory_gold.gold if "gold" in inventory_gold else 0
		output.print_line("[color=#7FFF7F]Gave %d gold to player (Total: %d)[/color]" % [amount, new_gold])
	else:
		output.print_error("[color=#FF4D4D]Error: No add_gold() method found[/color]")

func _cmd_spawn_item(args: Array, output: Control):
	"""Spawn an item with flexible parameters"""
	# Parse arguments: [type] [subtype] [name] [level] [quality] x[quantity]
	var item_type = ""
	var item_subtype = ""
	var item_name = ""
	var level = 1
	var quality = 0
	var quantity = 1
	
	# Valid types and subtypes (lowercase for comparison)
	var valid_types = ["accessory", "armor", "bag", "food", "gemstone", "potion", "trinket", "weapon", "treasure"]
	var valid_subtypes = [
		# Accessory subtypes
		"amulet", "cape", "ring",
		# Armor subtypes
		"belt", "bodyarmor", "gloves", "boots", "helmet", "pants",
		# Bag subtype
		"bag",
		# Food subtype
		"food",
		# Gemstone subtypes
		"charm", "gemstone",
		# Weapon subtypes
		"melee", "ranged", "magic",
		# Treasure subtype
		"coin"
	]
	var valid_qualities = {
		"common": 0,
		"uncommon": 1,
		"rare": 2,
		"epic": 3,
		"legendary": 4,
		"mythic": 5
	}
	
	# Track which args were recognized
	var unrecognized_args = []
	
	output.print_line("[color=#CCCCCC]Parsing: %s[/color]" % str(args))
	
	# Parse each argument
	for arg in args:
		# Strip any quotes from the argument
		arg = arg.strip_edges().replace("'", "").replace('"', "")
		var arg_lower = arg.to_lower()
		var recognized = false
		
		# Check for quantity (starts with 'x')
		if arg.begins_with("x") and arg.length() > 1:
			var qty_str = arg.substr(1)
			if qty_str.is_valid_int():
				quantity = int(qty_str)
				recognized = true
				output.print_line("[color=#CCCCCC]  '%s' → quantity = %d[/color]" % [arg, quantity])
			else:
				output.print_line("[color=#FFFF4D]Ignored: '%s' (invalid quantity)[/color]" % arg)
				continue
		
		# Check for quality (word)
		if not recognized and arg_lower in valid_qualities:
			quality = valid_qualities[arg_lower]
			recognized = true
			output.print_line("[color=#CCCCCC]  '%s' → quality = %d[/color]" % [arg, quality])
		
		# Check for level (number between 1-100)
		if not recognized and arg.is_valid_int():
			var num = int(arg)
			if num >= 1 and num <= 100:
				level = num
				recognized = true
				output.print_line("[color=#CCCCCC]  '%s' → level = %d[/color]" % [arg, level])
			else:
				output.print_line("[color=#FFFF4D]Ignored: '%s' (number out of range)[/color]" % arg)
				continue
		
		# Check for type
		if not recognized and arg_lower in valid_types and item_type == "":
			item_type = arg_lower
			recognized = true
			output.print_line("[color=#CCCCCC]  '%s' → type = %s[/color]" % [arg, item_type])
		
		# Check for subtype
		if not recognized and arg_lower in valid_subtypes and item_subtype == "":
			item_subtype = arg_lower
			recognized = true
			output.print_line("[color=#CCCCCC]  '%s' → subtype = %s[/color]" % [arg, item_subtype])
		
		# If not recognized, it's part of the item name
		if not recognized:
			unrecognized_args.append(arg)
			output.print_line("[color=#CCCCCC]  '%s' → unrecognized (will be item name)[/color]" % arg)
	
	# Join unrecognized args as item name
	if not unrecognized_args.is_empty():
		item_name = " ".join(unrecognized_args)
	
	# If no item name but we have type/subtype, use that for searching
	if item_name == "":
		if item_subtype != "":
			item_name = item_subtype
		elif item_type != "":
			item_name = item_type
	
	output.print_line("[color=#CCCCCC]Final: name='%s', type='%s', subtype='%s', level=%d, quality=%d, qty=%d[/color]" % [item_name, item_type, item_subtype, level, quality, quantity])
	
	# Join unrecognized args as item name
	if not unrecognized_args.is_empty():
		item_name = " ".join(unrecognized_args)
	
	# Build description of what we're spawning
	var desc_parts = []
	if quantity > 1:
		desc_parts.append("x%d" % quantity)
	if item_type != "":
		desc_parts.append(item_type)
	if item_subtype != "":
		desc_parts.append(item_subtype)
	if item_name != "":
		desc_parts.append("'%s'" % item_name)
	if level > 1:
		desc_parts.append("Lv.%d" % level)
	if quality > 0:
		var quality_names = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"]
		desc_parts.append(quality_names[quality])
	
	var description = " ".join(desc_parts) if not desc_parts.is_empty() else "random item"
	
	# Delegate to DebugLoot subsystem
	var debug_loot = debug_manager.get_node_or_null("DebugLoot")
	if not debug_loot:
		output.print_error("[color=#FF4D4D]Error: DebugLoot subsystem not found[/color]")
		output.print_line("[color=#FFFF4D]Make sure DebugLoot node exists under DebugManager[/color]")
		return
	
	# Spawn the items
	for i in range(quantity):
		if debug_loot.has_method("spawn_specific_item"):
			debug_loot.spawn_specific_item(item_name, level, quality, item_type, item_subtype)
		else:
			output.print_error("[color=#FF4D4D]Error: spawn_specific_item() method not found[/color]")
			return
	
	output.print_line("[color=#7FFF7F]Spawned: %s[/color]" % description)


func _cmd_teleport(args: Array, output: Control):
	"""Teleport player to coordinates"""
	if args.size() < 3:
		output.print_line("[color=#FFFF4D]Usage: tp <x> <y> <z>[/color]")
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		output.print_line("[color=#FF4D4D]Error: No player found[/color]")
		return
	
	var pos = Vector3(float(args[0]), float(args[1]), float(args[2]))
	player.global_position = pos
	output.print_line("[color=#7FFF7F]Teleported to: (%.1f, %.1f, %.1f)[/color]" % [pos.x, pos.y, pos.z])

func _cmd_stat(args: Array, output: Control):
	"""Set player stat"""
	if args.size() < 2:
		output.print_line("[color=#FFFF4D]Usage: stat <name> <value>[/color]")
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
		stats.set(stat_name, value)
		if stats.has_method("recalculate_all_stats"):
			stats.recalculate_all_stats()
		output.print_line("[color=#7FFF7F]Set %s to %d[/color]" % [stat_name, value])
	else:
		output.print_line("[color=#FF4D4D]Unknown stat: %s[/color]" % stat_name)

func _cmd_kill(args: Array, output: Control):
	"""Kill the player"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		output.print_line("[color=#FF4D4D]Error: No player found[/color]")
		return
	
	var stats = player.get_node_or_null("PlayerStats")
	if stats and "current_health" in stats:
		stats.current_health = 0
		output.print_line("[color=#FF4D4D]Player killed[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: Could not kill player[/color]")

func _cmd_heal(args: Array, output: Control):
	"""Heal the player"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		output.print_line("[color=#FF4D4D]Error: No player found[/color]")
		return
	
	var amount = float(args[0]) if not args.is_empty() else -1.0
	
	var stats = player.get_node_or_null("PlayerStats")
	if stats:
		if amount > 0:
			stats.current_health = min(stats.current_health + amount, stats.max_health)
			output.print_line("[color=#7FFF7F]Healed for %d HP[/color]" % int(amount))
		else:
			stats.current_health = stats.max_health
			output.print_line("[color=#7FFF7F]Fully healed[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: PlayerStats not found[/color]")

func _cmd_god(output: Control):
	"""Toggle god mode"""
	var debug_player = debug_manager.get_node_or_null("DebugPlayer")
	if debug_player and debug_player.has_method("toggle_god_mode"):
		debug_player.toggle_god_mode()
		output.print_line("[color=#FFFF4D]God mode toggled[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: DebugPlayer subsystem not available[/color]")

func _cmd_speed(args: Array, output: Control):
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

func _cmd_time(args: Array, output: Control):
	"""Set time of day"""
	if args.is_empty():
		output.print_line("[color=#FFFF4D]Usage: time <hour>[/color]")
		output.print_line("[color=#CCCCCC]Hour: 0-23 (0 = midnight, 12 = noon)[/color]")
		return
	
	var hour = int(args[0])
	var debug_time = debug_manager.get_node_or_null("DebugTime")
	if debug_time and debug_time.has_method("set_time"):
		debug_time.set_time(hour)
		output.print_line("[color=#7FFF7F]Time set to %02d:00[/color]" % hour)
	else:
		output.print_line("[color=#FF4D4D]Error: DebugTime subsystem not available[/color]")
