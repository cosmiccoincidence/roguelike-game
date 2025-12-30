# debug_time.gd
# Debug subsystem for time manipulation
extends Node

# Reference to main debug manager
var debug_manager: Node
var time_frozen: bool = false

func _ready():
	debug_manager = get_node_or_null("/root/DebugManager")
	if debug_manager:
		# Connect to debug signals
		debug_manager.debug_toggled.connect(_on_debug_toggled)
	
	print("[DEBUG TIME] Ready")

func _on_debug_toggled(enabled: bool):
	"""Called when debug mode is toggled"""
	if not enabled:
		# Unfreeze time when debug is disabled
		if time_frozen:
			unfreeze_time()

func advance_time(hours: int = 3):
	"""Advance time by specified hours"""
	if not debug_manager or not debug_manager.debug_enabled:
		return
	
	var time_manager = get_node_or_null("/root/TimeManager")
	if not time_manager:
		print("❌ TimeManager not found!")
		print("   Add it as autoload: Project → Project Settings → Autoload")
		return
	
	if not time_manager.has_method("advance_time"):
		print("❌ TimeManager missing advance_time() method!")
		return
	
	var old_time = time_manager.get_time_string() if time_manager.has_method("get_time_string") else "Unknown"
	
	time_manager.advance_time(hours)
	
	var new_time = time_manager.get_time_string() if time_manager.has_method("get_time_string") else "Unknown"
	
	print("⏰ Time advanced by %d hours: %s → %s" % [hours, old_time, new_time])

func freeze_time():
	"""Freeze time at current time"""
	if not debug_manager or not debug_manager.debug_enabled:
		return
	
	var time_manager = get_node_or_null("/root/TimeManager")
	if not time_manager:
		print("❌ TimeManager not found!")
		return
	
	if not "time_paused" in time_manager:
		print("❌ TimeManager missing time_paused variable!")
		return
	
	if time_frozen:
		# Unfreeze
		unfreeze_time()
	else:
		# Freeze at current time
		time_manager.time_paused = true
		time_frozen = true
		
		var current_time = time_manager.get_time_string() if time_manager.has_method("get_time_string") else "Unknown"
		print("⏸️  Time frozen at %s" % current_time)

func unfreeze_time():
	"""Unfreeze time"""
	var time_manager = get_node_or_null("/root/TimeManager")
	if not time_manager:
		return
	
	if "time_paused" in time_manager:
		time_manager.time_paused = false
	
	time_frozen = false
	print("▶️  Time unfrozen")

func show_time_info():
	"""Display current time information"""
	if not debug_manager or not debug_manager.debug_enabled:
		return
	
	print("\n" + "=".repeat(50))
	print("⏰ TIME INFO")
	print("=".repeat(50))
	
	var time_manager = get_node_or_null("/root/TimeManager")
	if not time_manager:
		print("❌ TimeManager not found!")
		print("=".repeat(50) + "\n")
		return
	
	# Get time info
	var current_time = time_manager.get_time_string() if time_manager.has_method("get_time_string") else "Unknown"
	var is_paused = time_manager.get("time_paused")
	var time_scale = time_manager.get("time_scale") if "time_scale" in time_manager else 1.0
	
	print("Current Time: %s" % current_time)
	print("Status: %s" % ("FROZEN" if is_paused else "Running"))
	print("Time Scale: %.1fx" % time_scale)
	
	if "day" in time_manager:
		print("Day: %d" % time_manager.day)
	
	if "hour" in time_manager and "minute" in time_manager:
		print("Raw: %02d:%02d" % [time_manager.hour, time_manager.minute])
	
	print("=".repeat(50) + "\n")
