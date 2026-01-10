# debug_ui_keybinds.gd
# Handles creation and management of the debug keybind panel
extends Node

var keybind_panel: PanelContainer
var keybind_vbox: VBoxContainer
var controls_ui: Control = null

func initialize(parent_ui: Control, controls_ref: Control):
	"""Initialize the keybind panel"""
	controls_ui = controls_ref
	_create_keybind_panel(parent_ui)

func _create_keybind_panel(parent_ui: Control):
	"""Create the keybind reference panel"""
	keybind_panel = PanelContainer.new()
	keybind_panel.visible = false
	
	# Anchor to BOTTOM right corner and grow upward and leftward
	keybind_panel.anchor_left = 1.0
	keybind_panel.anchor_right = 1.0
	keybind_panel.anchor_top = 1.0
	keybind_panel.anchor_bottom = 1.0
	keybind_panel.offset_left = 0
	keybind_panel.offset_right = -10  # 10px margin from right
	keybind_panel.offset_top = 0
	keybind_panel.offset_bottom = -10  # 10px margin from bottom
	keybind_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN  # Grow upward
	keybind_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN  # Grow leftward
	
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
	
	parent_ui.add_child(keybind_panel)
	
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
	
	# Build the keybind list
	_build_keybind_list()

func _build_keybind_list():
	"""Build the complete keybind list with sections"""
	# Title
	var title = Label.new()
	title.text = "═══ DEBUG CONTROLS ═══"
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keybind_vbox.add_child(title)
	
	_add_spacer(5)
	
	# Core keybinds
	_add_keybind("F1", "Toggle Debug Mode", Color.YELLOW)
	_add_keybind("F2", "Debug Controls", Color.WHITE)
	_add_keybind("F3", "Performance Stats", Color.WHITE)
	
	# Player System keybinds
	_add_section_header("PLAYER", Color(1.0, 0.8, 0.2))
	_add_keybind("INS", "Toggle God Mode", Color(1.0, 0.8, 0.2))
	
	# Map System keybinds
	_add_section_header("MAP", Color(0.8, 0.8, 1.0))
	_add_keybind("END", "Skip Level", Color(0.8, 0.8, 1.0))
	
	# Loot System keybinds
	_add_section_header("LOOT", Color(0.5, 1.0, 0.5))
	_add_keybind("\\", "Spawn Test Loot", Color(0.5, 1.0, 0.5))
	
	# Combat System keybinds
	_add_section_header("COMBAT", Color(1.0, 0.5, 0.5))
	_add_keybind("[", "Heal Self", Color(0.5, 1.0, 0.8))
	_add_keybind("]", "Damage Self", Color(1.0, 0.5, 0.5))
	
	# Time System keybinds
	_add_section_header("TIME", Color(0.7, 0.7, 1.0))
	_add_keybind(",", "Advance Time 3h", Color(0.7, 0.9, 1.0))
	_add_keybind(".", "Freeze/Unfreeze Time", Color(0.9, 0.7, 1.0))
	
	# FOV System keybinds
	_add_section_header("FOG OF WAR", Color(0.6, 0.6, 0.6))
	_add_keybind("M", "Toggle FOV System", Color(0.7, 0.7, 0.7))
	_add_keybind("N", "Reset Explored Map", Color(0.8, 0.6, 0.6))
	_add_keybind("B", "Reveal Entire Map", Color(0.6, 0.8, 0.6))

func _add_section_header(section_name: String, color: Color):
	"""Add a section header to the keybind list"""
	_add_spacer(5)
	
	var header = Label.new()
	header.text = "─── %s ───" % section_name
	header.add_theme_color_override("font_color", color)
	header.add_theme_font_size_override("font_size", 12)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keybind_vbox.add_child(header)

func _add_keybind(key: String, description: String, color: Color):
	"""Add a keybind entry to the list"""
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	keybind_vbox.add_child(hbox)
	
	# Key label
	var key_label = Label.new()
	key_label.text = key
	key_label.add_theme_color_override("font_color", color)
	key_label.add_theme_font_size_override("font_size", 14)
	key_label.custom_minimum_size = Vector2(40, 0)
	hbox.add_child(key_label)
	
	# Description label
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(desc_label)

func _add_spacer(height: int):
	"""Add vertical spacing"""
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	keybind_vbox.add_child(spacer)

func show():
	"""Show the keybind panel"""
	# Close controls panel if it's open
	if controls_ui and controls_ui.has_method("is_controls_panel_visible"):
		if controls_ui.is_controls_panel_visible():
			controls_ui.hide_controls_panel()
	
	keybind_panel.visible = true

func hide():
	"""Hide the keybind panel"""
	keybind_panel.visible = false

func is_visible() -> bool:
	"""Check if keybind panel is currently visible"""
	return keybind_panel.visible
