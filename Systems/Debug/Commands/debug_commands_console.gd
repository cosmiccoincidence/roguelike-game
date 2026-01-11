# debug_commands_console.gd
# Console-specific commands
extends Node

var console: Control = null

func cmd_help(output: Control, main_commands: Node):
	"""Show help for all commands"""
	output.print_line("[color=#4DAAFF]═══ AVAILABLE COMMANDS ═══[/color]")
	
	# Console commands
	output.print_line("[color=#FFD700]CONSOLE:[/color]")
	output.print_line("[color=#7FFF7F]  help[/color] - Show this help")
	output.print_line("[color=#7FFF7F]  clear[/color] - Clear console output")
	
	# Player commands
	output.print_line("[color=#FFD700]PLAYER:[/color]")
	output.print_line("[color=#7FFF7F]  tp <x> <z>[/color] - Teleport to grid coordinates")
	output.print_line("[color=#7FFF7F]  god[/color] - Toggle god mode")
	output.print_line("[color=#7FFF7F]  heal [amount][/color] - Heal player")
	output.print_line("[color=#7FFF7F]  hurt [amount][/color] - Damage player (default: 10)")
	output.print_line("[color=#7FFF7F]  kill[/color] - Kill player")
	output.print_line("[color=#7FFF7F]  stat <name> <value>[/color] - Set player stat")
	output.print_line("[color=#7FFF7F]  speed <multiplier>[/color] - Set movement speed")
	
	# Inventory commands
	output.print_line("[color=#FFD700]INVENTORY:[/color]")
	output.print_line("[color=#7FFF7F]  give-gold [amount][/color] - Give gold (default: 1000)")
	output.print_line("[color=#7FFF7F]  spawn-item [type] [subtype] [name] [level] [quality] x[qty][/color]")
	output.print_line("    - Spawn item (all fields optional, order-independent)")
	output.print_line("    - Quality: common, uncommon, rare, epic, legendary, mythic")
	output.print_line("    - Ex: spawn-item Sword 10 epic x5")
	
	# World commands
	output.print_line("[color=#FFD700]WORLD:[/color]")
	output.print_line("[color=#7FFF7F]  time <hour>[/color] - Set time of day")

func cmd_clear(output: Control):
	"""Clear console output"""
	output.clear_output()
	output.print_line("[color=#4DAAFF]Console cleared[/color]")
