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
	# Try to find level manager or map manager
	var level_manager = get_node_or_null("/root/LevelManager")
	if not level_manager:
		level_manager = get_tree().root.find_child("LevelManager", true, false)
	
	if level_manager and level_manager.has_method("next_level"):
		level_manager.next_level()
		output.print_line("[color=#7FFF7F]Skipped to next level[/color]")
	elif level_manager and level_manager.has_method("skip_level"):
		level_manager.skip_level()
		output.print_line("[color=#7FFF7F]Skipped to next level[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: Level manager not found or no skip method[/color]")

func cmd_fov(output: Control):
	"""Toggle FOV system"""
	# Try to find FOV manager
	var fov_manager = get_node_or_null("/root/FOVManager")
	if not fov_manager:
		fov_manager = get_tree().root.find_child("FOVManager", true, false)
	
	if fov_manager and fov_manager.has_method("toggle_fov_system"):
		fov_manager.toggle_fov_system()
		output.print_line("[color=#FFFF4D]FOV system toggled[/color]")
	elif "enabled" in fov_manager:
		fov_manager.enabled = !fov_manager.enabled
		output.print_line("[color=#FFFF4D]FOV system: %s[/color]" % ("ON" if fov_manager.enabled else "OFF"))
	else:
		output.print_line("[color=#FF4D4D]Error: FOV manager not found[/color]")

func cmd_explore(output: Control):
	"""Reveal entire fog of war"""
	var fov_manager = get_node_or_null("/root/FOVManager")
	if not fov_manager:
		fov_manager = get_tree().root.find_child("FOVManager", true, false)
	
	if fov_manager and fov_manager.has_method("reveal_entire_map"):
		fov_manager.reveal_entire_map()
		output.print_line("[color=#7FFF7F]Entire map revealed[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: FOV manager not found or no reveal method[/color]")

func cmd_unexplore(output: Control):
	"""Reset fog of war"""
	var fov_manager = get_node_or_null("/root/FOVManager")
	if not fov_manager:
		fov_manager = get_tree().root.find_child("FOVManager", true, false)
	
	if fov_manager and fov_manager.has_method("reset_explored_map"):
		fov_manager.reset_explored_map()
		output.print_line("[color=#7FFF7F]Fog of war reset[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: FOV manager not found or no reset method[/color]")
