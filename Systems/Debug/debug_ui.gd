# debug_ui.gd
# Handles all debug UI elements and displays
extends Control

# UI Elements
var enabled_label: Label
var keybind_panel: PanelContainer
var keybind_vbox: VBoxContainer

func _ready():
	# Make sure UI is on top
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_create_enabled_indicator()
	_create_keybind_panel()
	
	# Hide everything by default
	hide_all()

func _create_enabled_indicator():
	"""Create the debug mode enabled indicator"""
	enabled_label = Label.new()
	enabled_label.text = "🔧 DEBUG MODE ENABLED"
	enabled_label.position = Vector2(10, 10)
	enabled_label.add_theme_color_override("font_color", Color.GREEN)
	enabled_label.add_theme_font_size_override("font_size", 16)
	enabled_label.visible = false
	add_child(enabled_label)

func _create_keybind_panel():
	"""Create the keybind reference panel"""
	keybind_panel = PanelContainer.new()
	keybind_panel.position = Vector2(10, 50)
	keybind_panel.custom_minimum_size = Vector2(350, 150)
	keybind_panel.visible = false
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	style.border_color = Color(0.2, 0.6, 1.0, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	keybind_panel.add_theme_stylebox_override("panel", style)
	
	add_child(keybind_panel)
	
	# Create content
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	keybind_panel.add_child(margin)
	
	keybind_vbox = VBoxContainer.new()
	keybind_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(keybind_vbox)
	
	# Title
	var title = Label.new()
	title.text = "═══ DEBUG KEYBINDS ═══"
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keybind_vbox.add_child(title)
	
	# Add spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	keybind_vbox.add_child(spacer)
	
	# Keybinds
	var keybinds = [
		["F1", "Toggle Debug Mode", Color.YELLOW],
		["F2", "Show/Hide This Panel", Color.WHITE],
		["F3", "Spawn Test Loot", Color(0.5, 1.0, 0.5)]
	]
	
	for bind in keybinds:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		keybind_vbox.add_child(hbox)
		
		# Key label
		var key_label = Label.new()
		key_label.text = bind[0]
		key_label.add_theme_color_override("font_color", bind[2])
		key_label.add_theme_font_size_override("font_size", 14)
		key_label.custom_minimum_size = Vector2(40, 0)
		hbox.add_child(key_label)
		
		# Description label
		var desc_label = Label.new()
		desc_label.text = bind[1]
		desc_label.add_theme_font_size_override("font_size", 14)
		hbox.add_child(desc_label)

func show_debug_enabled():
	"""Show the debug mode enabled indicator"""
	enabled_label.visible = true

func hide_all():
	"""Hide all debug UI elements"""
	enabled_label.visible = false
	keybind_panel.visible = false

func show_keybind_panel():
	"""Show the keybind reference panel"""
	keybind_panel.visible = true

func hide_keybind_panel():
	"""Hide the keybind reference panel"""
	keybind_panel.visible = false
