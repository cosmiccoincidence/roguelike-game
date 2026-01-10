# performance_stats.gd
# Shows FPS and other performance metrics for debugging
extends PanelContainer

# ===== CONFIGURATION =====
var update_interval: float = 0.5  # Update every 0.5 seconds
var is_visible: bool = false  # Start hidden by default

# ===== STATE =====
var time_since_update: float = 0.0
var frame_count: int = 0
var fps_samples: Array[float] = []
var max_samples: int = 60  # Keep last 60 samples for averaging

# ===== NODE REFERENCES =====
var stats_label: RichTextLabel
var process_info: Dictionary = {}

func _ready():
	# Setup panel style
	_setup_panel_style()
	
	# Create RichTextLabel for BBCode support
	stats_label = RichTextLabel.new()
	stats_label.bbcode_enabled = true
	stats_label.fit_content = true
	stats_label.scroll_active = false
	stats_label.custom_minimum_size = Vector2(280, 0)  # Set minimum width
	stats_label.add_theme_font_size_override("normal_font_size", 12)
	stats_label.add_theme_color_override("default_color", Color.WHITE)
	add_child(stats_label)
	
	# Position in top-left corner
	position = Vector2(10, 10)
	
	# Start hidden
	visible = is_visible
	
	# Initial update
	_update_display()

func _setup_panel_style():
	"""Setup semi-transparent dark background"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	style.border_color = Color(0.3, 0.3, 0.3, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)

func toggle_visibility():
	"""Toggle performance stats visibility (called by debug system)"""
	is_visible = !is_visible
	visible = is_visible
	print("Performance stats: %s" % ("ON" if is_visible else "OFF"))

func hide_stats():
	"""Hide stats (called when debug mode is disabled)"""
	is_visible = false
	visible = false

func _process(delta):
	if not is_visible:
		return
	
	time_since_update += delta
	frame_count += 1
	
	# Update display at intervals
	if time_since_update >= update_interval:
		_update_display()
		frame_count = 0
		time_since_update = 0.0

func _update_display():
	"""Update all performance stats"""
	# Get FPS
	var fps = Engine.get_frames_per_second()
	_add_fps_sample(fps)
	var avg_fps = _get_average_fps()
	var min_fps = _get_min_fps()
	var max_fps = _get_max_fps()
	
	# Get memory usage (Godot 4)
	var static_memory = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0  # MB
	var message_buffer_max = Performance.get_monitor(Performance.MEMORY_MESSAGE_BUFFER_MAX) / 1024.0 / 1024.0  # MB
	
	# Get process time
	var process_time = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0  # ms
	var physics_time = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0  # ms
	
	# Get object counts
	var objects_count = Performance.get_monitor(Performance.OBJECT_COUNT)
	var resources_count = Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
	var nodes_count = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphan_nodes = Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	
	# Get draw calls (Godot 4)
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	
	# Color codes
	var color_header = "#FFD700"  # Gold
	var color_good = "#7FFF7F"    # Light green
	var color_warning = "#FFFF7F"  # Light yellow
	var color_bad = "#FF7F7F"     # Light red
	var color_default = "#CCCCCC" # Light gray
	
	# FPS color based on performance
	var fps_color = color_good if fps >= 60 else (color_warning if fps >= 30 else color_bad)
	
	# Build display text
	var text = ""
	
	# FPS Section (centered header)
	text += "[center][color=%s]═══ PERFORMANCE ═══[/color][/center]\n" % color_header
	text += "[color=%s]FPS:[/color] %d (avg: %d, min: %d, max: %d)\n" % [fps_color, fps, avg_fps, min_fps, max_fps]
	text += "[color=%s]Frame Time:[/color] %.2f ms\n" % [color_default, 1000.0 / max(fps, 1)]
	text += "\n"
	
	# Timing Section
	text += "[center][color=%s]═══ TIMING ═══[/color][/center]\n" % color_header
	text += "[color=%s]Process:[/color] %.2f ms\n" % [color_default, process_time]
	text += "[color=%s]Physics:[/color] %.2f ms\n" % [color_default, physics_time]
	text += "\n"
	
	# Memory Section
	text += "[center][color=%s]═══ MEMORY ═══[/color][/center]\n" % color_header
	text += "[color=%s]Static:[/color] %.1f MB\n" % [color_default, static_memory]
	text += "[color=%s]Message Buffer:[/color] %.1f MB\n" % [color_default, message_buffer_max]
	text += "[color=%s]Total:[/color] %.1f MB\n" % [color_default, static_memory + message_buffer_max]
	text += "\n"
	
	# Objects Section
	text += "[center][color=%s]═══ OBJECTS ═══[/color][/center]\n" % color_header
	text += "[color=%s]Nodes:[/color] %d\n" % [color_default, nodes_count]
	text += "[color=%s]Objects:[/color] %d\n" % [color_default, objects_count]
	text += "[color=%s]Resources:[/color] %d\n" % [color_default, resources_count]
	if orphan_nodes > 0:
		text += "[color=%s]Orphans:[/color] %d\n" % [color_bad, orphan_nodes]
	text += "\n"
	
	# Rendering Section (no trailing newline)
	text += "[center][color=%s]═══ RENDERING ═══[/color][/center]\n" % color_header
	text += "[color=%s]Draw Calls:[/color] %d\n" % [color_default, draw_calls]
	text += "[color=%s]Primitives:[/color] %d" % [color_default, primitives]  # No trailing \n
	
	stats_label.text = text

func _add_fps_sample(fps: float):
	"""Add FPS sample to running average"""
	fps_samples.append(fps)
	if fps_samples.size() > max_samples:
		fps_samples.pop_front()

func _get_average_fps() -> int:
	"""Get average FPS from samples"""
	if fps_samples.is_empty():
		return 0
	
	var sum = 0.0
	for fps in fps_samples:
		sum += fps
	return int(sum / fps_samples.size())

func _get_min_fps() -> int:
	"""Get minimum FPS from samples"""
	if fps_samples.is_empty():
		return 0
	
	var min_val = fps_samples[0]
	for fps in fps_samples:
		if fps < min_val:
			min_val = fps
	return int(min_val)

func _get_max_fps() -> int:
	"""Get maximum FPS from samples"""
	if fps_samples.is_empty():
		return 0
	
	var max_val = fps_samples[0]
	for fps in fps_samples:
		if fps > max_val:
			max_val = fps
	return int(max_val)
