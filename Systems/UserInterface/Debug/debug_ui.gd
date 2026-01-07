# debug_ui.gd
# Handles all debug UI elements and displays
extends Control

# UI Elements
var enabled_label: Label
var god_mode_label: Label

# Components
var keybinds: Node

# Reference to controls UI
var controls_ui: Control = null

func _ready():
	# Make sure UI is on top
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Try to find controls UI
	await get_tree().process_frame
	controls_ui = get_node_or_null("/root/ControlsUI")
	
	# Create UI components
	_create_god_mode_indicator()
	_create_enabled_indicator()
	_create_keybinds_component()
	
	# Hide everything by default
	hide_all()

func _create_keybinds_component():
	"""Create the keybinds component"""
	var keybinds_script = load("res://Systems/UserInterface/Debug/debug_ui_keybinds.gd")
	if keybinds_script:
		keybinds = Node.new()
		keybinds.name = "Keybinds"
		keybinds.set_script(keybinds_script)
		add_child(keybinds)
		keybinds.initialize(self, controls_ui)
	else:
		push_error("Could not load debug_ui_keybinds.gd")

func _create_god_mode_indicator():
	"""Create the god mode enabled indicator"""
	god_mode_label = Label.new()
	god_mode_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	god_mode_label.add_theme_font_size_override("font_size", 14)
	god_mode_label.visible = false
	
	# Position in top right, BELOW debug enabled indicator
	god_mode_label.anchor_left = 1.0
	god_mode_label.anchor_right = 1.0
	god_mode_label.anchor_top = 0.0
	god_mode_label.anchor_bottom = 0.0
	god_mode_label.offset_left = -290
	god_mode_label.offset_right = -10
	god_mode_label.offset_top = 40  # Below debug enabled (which is at 10)
	god_mode_label.offset_bottom = 190
	god_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	add_child(god_mode_label)

func _create_enabled_indicator():
	"""Create the debug mode enabled indicator"""
	enabled_label = Label.new()
	enabled_label.text = "🔧 DEBUG MODE ENABLED"
	enabled_label.add_theme_color_override("font_color", Color.GREEN)
	enabled_label.add_theme_font_size_override("font_size", 16)
	enabled_label.visible = false
	
	# Position in top right
	enabled_label.anchor_left = 1.0
	enabled_label.anchor_right = 1.0
	enabled_label.anchor_top = 0.0
	enabled_label.anchor_bottom = 0.0
	enabled_label.offset_left = -250
	enabled_label.offset_right = -10
	enabled_label.offset_top = 10
	enabled_label.offset_bottom = 40
	enabled_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	add_child(enabled_label)

func show_debug_enabled():
	"""Show the debug mode enabled indicator"""
	enabled_label.visible = true

func show_god_mode(player: Node):
	"""Show the god mode indicator with player stats"""
	if not player:
		return
	
	# Get god mode constants from player or stats component
	var stats_component = player.get_node_or_null("PlayerStats")
	var god_speed_mult = player.get("GOD_SPEED_MULT") if "GOD_SPEED_MULT" in player else 2.0
	var god_crit_chance = 1.0
	var god_crit_mult = 2.0
	
	# Try to get from stats component
	if stats_component:
		god_crit_chance = stats_component.get("GOD_CRIT_CHANCE") if "GOD_CRIT_CHANCE" in stats_component else 1.0
		god_crit_mult = stats_component.get("GOD_CRIT_MULT") if "GOD_CRIT_MULT" in stats_component else 2.0
	elif "GOD_CRIT_CHANCE" in player:
		god_crit_chance = player.GOD_CRIT_CHANCE
		god_crit_mult = player.GOD_CRIT_MULT
	
	var text = "⚡ GOD MODE ENABLED\n"
	text += "─────────────────\n"
	text += "Speed: x%.1f\n" % god_speed_mult
	text += "Crit: %.0f%% (x%.1f)\n" % [god_crit_chance * 100, god_crit_mult]
	text += "Max Zoom: %.0f\n" % player.get("god_zoom_max")
	text += "Encumbered: OFF\n"
	text += "Stamina Cost: OFF\n"
	text += "Damage: BLOCKED"
	
	god_mode_label.text = text
	god_mode_label.visible = true

func hide_god_mode():
	"""Hide the god mode indicator"""
	god_mode_label.visible = false

func hide_all():
	"""Hide all debug UI elements"""
	enabled_label.visible = false
	god_mode_label.visible = false
	if keybinds:
		keybinds.hide()

func show_keybind_panel():
	"""Show the keybind reference panel"""
	if keybinds:
		keybinds.show()

func hide_keybind_panel():
	"""Hide the keybind reference panel"""
	if keybinds:
		keybinds.hide()

func is_keybind_panel_visible() -> bool:
	"""Check if keybind panel is currently visible"""
	if keybinds:
		return keybinds.is_visible()
	return false
