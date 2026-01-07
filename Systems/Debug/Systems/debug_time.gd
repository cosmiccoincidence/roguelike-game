# debug_time.gd
# Debug subsystem for time manipulation
extends Node

# Reference to main debug manager
var debug_manager: Node

func _ready():
	debug_manager = get_node_or_null("/root/DebugManager")
	if debug_manager:
		# Connect to debug signals
		debug_manager.debug_toggled.connect(_on_debug_toggled)
	
	print("[DEBUG TIME] Ready")

func _on_debug_toggled(enabled: bool):
	"""Called when debug mode is toggled"""
	if not enabled:
		# Unfreeze time if frozen
		var time_manager = get_node_or_null("/root/TimeManager")
		if time_manager and time_manager.get("daylight_lock"):
			time_manager.daylight_lock = false

func advance_time():
	"""Advance time by 3 hours"""
	if not debug_manager or not debug_manager.debug_enabled:
		return
	
	var time_manager = get_node_or_null("/root/TimeManager")
	if not time_manager:
		print("❌ TimeManager not found!")
		print("   Add it as autoload: Project → Project Settings → Autoload")
		return
	
	if time_manager.get("daylight_lock") and time_manager.daylight_lock:
		print("⏰ Cannot advance time - Time is frozen")
		return
	
	print("\n" + "=".repeat(50))
	print("⏰ ADVANCING TIME BY 3 HOURS")
	print("=".repeat(50))
	
	var old_time = time_manager.get_time_string() if time_manager.has_method("get_time_string") else "Unknown"
	var old_day = time_manager.current_day
	
	# Call advance_time with NO arguments (TimeManager handles the hours internally)
	if time_manager.has_method("advance_time"):
		time_manager.advance_time()
	else:
		print("❌ TimeManager missing advance_time() method!")
		print("=".repeat(50) + "\n")
		return
	
	var new_time = time_manager.get_time_string() if time_manager.has_method("get_time_string") else "Unknown"
	var new_day = time_manager.current_day
	
	print("Time: %s → %s" % [old_time, new_time])
	if new_day != old_day:
		print("Day: %d → %d (New day!)" % [old_day, new_day])
	print("=".repeat(50) + "\n")

func freeze_time():
	"""Freeze/unfreeze time at current time"""
	if not debug_manager or not debug_manager.debug_enabled:
		return
	
	var time_manager = get_node_or_null("/root/TimeManager")
	if not time_manager:
		print("❌ TimeManager not found!")
		return
	
	if not "daylight_lock" in time_manager:
		print("❌ TimeManager missing daylight_lock variable!")
		return
	
	# Toggle freeze
	time_manager.daylight_lock = !time_manager.daylight_lock
	
	if time_manager.daylight_lock:
		print("\n" + "=".repeat(50))
		print("⏸️  TIME FROZEN")
		print("=".repeat(50))
		print("Current time: %s" % time_manager.get_time_string())
		print("Day: %d" % time_manager.current_day)
		print("Time of day: %s" % time_manager.get_time_of_day())
		print("=".repeat(50) + "\n")
	else:
		print("\n▶️  TIME UNFROZEN - Time will advance normally\n")

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
	
	print("Full Time: %s" % time_manager.get_full_time_string())
	print("Time: %s" % time_manager.get_time_string())
	print("Day: %d" % time_manager.current_day)
	print("Time of Day: %s" % time_manager.get_time_of_day())
	print("Day/Night: %s" % ("Day" if time_manager.is_day_time() else "Night"))
	print("Frozen: %s" % ("YES" if time_manager.get("daylight_lock") else "No"))
	print("Hours per level: %d" % time_manager.hours_per_level)
	
	# Sun/Moon info
	if time_manager.sun_moon_origin:
		print("\nSun/Moon Origin: Found")
		var sun = time_manager.sun_moon_origin.get_node_or_null("Sun")
		var moon = time_manager.sun_moon_origin.get_node_or_null("Moon")
		if sun:
			print("  Sun visible: %s" % sun.visible)
		if moon:
			print("  Moon visible: %s" % moon.visible)
	else:
		print("\nSun/Moon Origin: Not set")
	
	print("=".repeat(50) + "\n")
