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
	output.print_line("[color=#7FFF7F]  mana [amount][/color] - Restore mana")
	output.print_line("[color=#7FFF7F]  hurt [amount][/color] - Damage player (default: 10)")
	output.print_line("[color=#7FFF7F]  die[/color] - Kill player")
	output.print_line("[color=#7FFF7F]  stat <name> <value>[/color] - Set player stat")
	output.print_line("[color=#7FFF7F]  speed <value>[/color] - Set movement speed")

	# Enemy commands
	output.print_line("[color=#FFD700]ENEMY:[/color]")
	output.print_line("[color=#7FFF7F]  kill[/color] - Kill closest enemy")
	output.print_line("[color=#7FFF7F]  kill-all[/color] - Kill all enemies")

	
	# Inventory commands
	output.print_line("[color=#FFD700]INVENTORY:[/color]")
	output.print_line("[color=#7FFF7F]  give-gold [amount][/color] - Give gold (default: 1000)")
	output.print_line("[color=#7FFF7F]  spawn-item [type] [subtype] [name] [level] [quality] x[qty][/color]")
	output.print_line("    - Spawn item (all fields optional, order-independent)")
	output.print_line("    - Quality: common, uncommon, rare, epic, legendary, mythic")
	output.print_line("    - Ex: spawn-item Sword 10 epic x5")
	
	# World commands
	output.print_line("[color=#FFD700]WORLD:[/color]")
	output.print_line("[color=#7FFF7F]  time [hour][/color] - Advance time 3hrs or set specific hour (0-23)")
	output.print_line("[color=#7FFF7F]  time-freeze[/color] - Toggle time freeze")
	output.print_line("[color=#7FFF7F]  skip-level[/color] - Skip to next level")
	
	output.print_line("")
	
	# FOV commands
	output.print_line("[color=#FFD700]FOV:[/color]")
	output.print_line("[color=#7FFF7F]  fov[/color] - Toggle FOV system")
	output.print_line("[color=#7FFF7F]  explore[/color] - Reveal entire fog of war")
	output.print_line("[color=#7FFF7F]  unexplore[/color] - Reset fog of war")

func cmd_clear(output: Control):
	"""Clear console output"""
	output.clear_output()
	output.print_line("[color=#4DAAFF]Console cleared[/color]")
