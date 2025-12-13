extends Node

# Time settings
var current_hour: int = 7
var current_minute: int = 30
var current_day: int = 1
var hours_per_level: int = 3

# Sun/Moon pivot reference
var sun_moon_origin: Node3D = null
var daylight_lock: bool = false

signal time_changed(hour: int, minute: int, day: int)

func _ready():
	print("Time started at Day ", current_day, " - ", get_time_string())

func _input(event):
	# Debug: Press I to toggle daylight lock
	if event is InputEventKey and event.pressed and event.keycode == KEY_I:
		daylight_lock = !daylight_lock
		if daylight_lock:
			print("=== DAYLIGHT LOCK ENABLED - Time frozen at 10:30 ===")
			current_hour = 10
			current_minute = 30
			update_sun_position()
			time_changed.emit(current_hour, current_minute, current_day)
		else:
			print("=== DAYLIGHT LOCK DISABLED - Time will advance normally ===")
	
	# Debug: Press O to advance time by 3 hours (unless locked)
	if event is InputEventKey and event.pressed and event.keycode == KEY_O:
		if daylight_lock:
			print("Cannot advance time - Daylight lock is enabled")
		else:
			print("=== DEBUG: Advancing time by 3 hours ===")
			advance_time()

func set_sun_moon_origin(origin: Node3D):
	sun_moon_origin = origin
	update_sun_position()

func advance_time():
	if daylight_lock:
		print("Time advance blocked by daylight lock")
		return
	
	current_hour += hours_per_level
	
	# Handle day rollover
	while current_hour >= 24:
		current_hour -= 24
		current_day += 1
		print("New day! Day ", current_day)
	
	print("Time advanced to Day ", current_day, " - ", get_time_string())
	update_sun_position()
	time_changed.emit(current_hour, current_minute, current_day)

func update_sun_position():
	if not sun_moon_origin:
		return
	
	# Custom mapping where 07:30 = 292.5°
	# 07:30 in standard = 112.5° (7.5 × 15)
	# We need 292.5°, so offset = 292.5 - 112.5 = 180°
	var hour_degrees = current_hour * 15.0
	var minute_degrees = (current_minute / 60.0) * 15.0
	var total_degrees = hour_degrees + minute_degrees + 180.0 # Add 180° offset
	
	sun_moon_origin.rotation_degrees.z = total_degrees
	
	# Toggle Sun/Moon lights
	var sun_light = sun_moon_origin.get_node_or_null("Sun")
	var moon_light = sun_moon_origin.get_node_or_null("Moon")
	
	# Sun: 06:00-18:00 (day time)
	if sun_light:
		sun_light.visible = (current_hour >= 6 and current_hour < 18)
	
	# Moon: 18:00-06:00 (night time)
	if moon_light:
		moon_light.visible = not (current_hour >= 6 and current_hour < 18)
	
	print("Sun position updated to: ", total_degrees, " degrees")
	if sun_light:
		print("Sun visible: ", sun_light.visible)
	if moon_light:
		print("Moon visible: ", moon_light.visible)

func get_time_string() -> String:
	return "%02d:%02d" % [current_hour, current_minute]

func get_full_time_string() -> String:
	return "Day %d, %02d:%02d" % [current_day, current_hour, current_minute]

func is_day_time() -> bool:
	return current_hour >= 6 and current_hour < 18  # 6am to 6pm is day

func is_night_time() -> bool:
	return not is_day_time()

func get_time_of_day() -> String:
	if current_hour >= 5 and current_hour < 12:
		return "Morning"
	elif current_hour >= 12 and current_hour < 17:
		return "Afternoon"
	elif current_hour >= 17 and current_hour < 21:
		return "Evening"
	else:
		return "Night"
