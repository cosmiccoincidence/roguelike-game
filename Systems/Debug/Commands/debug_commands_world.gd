# debug_commands_world.gd
# World-specific commands
extends Node

var console: Control = null
var debug_manager: Node:
	get:
		return get_node_or_null("/root/DebugManager")

func cmd_time(args: Array, output: Control):
	"""Set time of day or advance time"""
	# Get TimeManager autoload
	var time_manager = get_node_or_null("/root/TimeManager")
	
	if not time_manager:
		output.print_line("[color=#FF4D4D]Error: TimeManager not found[/color]")
		output.print_line("[color=#CCCCCC]Make sure TimeManager is set up as an autoload[/color]")
		return
	
	# If no args, advance time by 3 hours
	if args.is_empty():
		if time_manager.has_method("advance_time"):
			time_manager.advance_time()
			var time_string = time_manager.get_time_string() if time_manager.has_method("get_time_string") else ""
			var time_of_day = time_manager.get_time_of_day() if time_manager.has_method("get_time_of_day") else ""
			
			if time_string and time_of_day:
				output.print_line("[color=#7FFF7F]Time advanced to %s (%s)[/color]" % [time_string, time_of_day])
			else:
				output.print_line("[color=#7FFF7F]Time advanced[/color]")
		else:
			output.print_line("[color=#FF4D4D]Error: advance_time() method not found[/color]")
		return
	
	var hour = int(args[0])
	
	# Validate hour range
	if hour < 0 or hour > 23:
		output.print_line("[color=#FF4D4D]Invalid hour: %d (must be 0-23)[/color]" % hour)
		return
	
	# Set the hour
	if "current_hour" in time_manager:
		time_manager.current_hour = hour
		
		# Update sun position if method exists
		if time_manager.has_method("update_sun_position"):
			time_manager.update_sun_position()
		
		# Emit time changed signal if it exists
		if time_manager.has_signal("time_changed"):
			time_manager.time_changed.emit(hour, time_manager.current_minute, time_manager.current_day)
		
		var time_string = time_manager.get_time_string() if time_manager.has_method("get_time_string") else "%02d:00" % hour
		var time_of_day = time_manager.get_time_of_day() if time_manager.has_method("get_time_of_day") else ""
		
		if time_of_day:
			output.print_line("[color=#7FFF7F]Time set to %s (%s)[/color]" % [time_string, time_of_day])
		else:
			output.print_line("[color=#7FFF7F]Time set to %s[/color]" % time_string)
	else:
		output.print_line("[color=#FF4D4D]Error: current_hour property not found on TimeManager[/color]")

func cmd_time_freeze(output: Control):
	"""Toggle time freeze"""
	var time_manager = get_node_or_null("/root/TimeManager")
	
	if not time_manager:
		output.print_line("[color=#FF4D4D]Error: TimeManager not found[/color]")
		return
	
	if "daylight_lock" in time_manager:
		time_manager.daylight_lock = !time_manager.daylight_lock
		if time_manager.daylight_lock:
			output.print_line("[color=#FFFF4D]Time FROZEN[/color]")
		else:
			output.print_line("[color=#7FFF7F]Time UNFROZEN[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: daylight_lock property not found[/color]")

func cmd_skip_level(output: Control):
	"""Skip to next level"""
	# Find MapManager - it's a child of World node
	var map_manager = get_tree().root.find_child("MapManager", true, false)
	
	if not map_manager:
		output.print_line("[color=#FF4D4D]Error: MapManager not found[/color]")
		return
	
	# Check if there's a next level
	if "current_level_index" in map_manager and "level_sequence" in map_manager:
		var next_index = map_manager.current_level_index + 1
		if next_index >= map_manager.level_sequence.size():
			output.print_line("[color=#FFAA55]Already at final level[/color]")
			return
		
		# Trigger the exit (which loads next level)
		if map_manager.has_method("_on_player_reached_exit"):
			map_manager._on_player_reached_exit()
			output.print_line("[color=#7FFF7F]Skipping to next level...[/color]")
		else:
			output.print_line("[color=#FF4D4D]Error: MapManager has no level progression method[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: MapManager missing level tracking properties[/color]")

func cmd_fov(output: Control):
	"""Toggle FOV system"""
	# Find FOV components in the scene
	var fog_of_war = get_tree().root.find_child("FogOfWar", true, false)
	var vision_cone = get_tree().root.find_child("VisionCone", true, false)
	
	if not fog_of_war and not vision_cone:
		output.print_line("[color=#FF4D4D]Error: FOV system not found[/color]")
		return
	
	# Toggle both systems
	var toggled = false
	
	if fog_of_war and fog_of_war.has_method("debug_toggle_system"):
		fog_of_war.debug_toggle_system()
		toggled = true
	
	if vision_cone and vision_cone.has_method("debug_toggle_system"):
		vision_cone.debug_toggle_system()
		toggled = true
	
	if toggled:
		# Check the current state from one of them
		var is_disabled = false
		if fog_of_war and "debug_disabled" in fog_of_war:
			is_disabled = fog_of_war.debug_disabled
		elif vision_cone and "debug_disabled" in vision_cone:
			is_disabled = vision_cone.debug_disabled
		
		if is_disabled:
			output.print_line("[color=#FFFF4D]FOV system DISABLED[/color]")
		else:
			output.print_line("[color=#7FFF7F]FOV system ENABLED[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: FOV system has no toggle method[/color]")

func cmd_explore(output: Control):
	"""Reveal entire fog of war"""
	var fog_of_war = get_tree().root.find_child("FogOfWar", true, false)
	
	if not fog_of_war:
		output.print_line("[color=#FF4D4D]Error: FogOfWar not found[/color]")
		return
	
	if fog_of_war.has_method("reveal_all"):
		fog_of_war.reveal_all()
		output.print_line("[color=#7FFF7F]Entire map revealed[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: FogOfWar has no reveal_all() method[/color]")

func cmd_unexplore(output: Control):
	"""Reset fog of war"""
	var fog_of_war = get_tree().root.find_child("FogOfWar", true, false)
	
	if not fog_of_war:
		output.print_line("[color=#FF4D4D]Error: FogOfWar not found[/color]")
		return
	
	if fog_of_war.has_method("debug_reset_fog"):
		fog_of_war.debug_reset_fog()
		output.print_line("[color=#7FFF7F]Fog of war reset[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: FogOfWar has no debug_reset_fog() method[/color]")
