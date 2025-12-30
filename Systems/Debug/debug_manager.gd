# debug_manager.gd
# Core debug system manager - handles debug state and delegates to subsystems
extends Node

# Debug state
var debug_enabled: bool = false
var keybind_panel_visible: bool = false

# References
var debug_ui: Control = null

signal debug_toggled(enabled: bool)
signal keybind_panel_toggled(visible: bool)

func _ready():
	print("[DEBUG MANAGER] Ready - Press F1 to enable debug mode")
	
	# Create debug UI
	_setup_debug_ui()

func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		KEY_F1:
			toggle_debug_system()
		KEY_F2:
			if debug_enabled:
				toggle_keybind_panel()
		KEY_F3:
			if debug_enabled:
				# Delegate to debug_loot subsystem
				var debug_loot = get_node_or_null("DebugLoot")
				if debug_loot and debug_loot.has_method("spawn_test_loot"):
					debug_loot.spawn_test_loot()
				else:
					print("⚠️  DebugLoot subsystem not found")

func toggle_debug_system():
	"""Toggle the entire debug system on/off"""
	debug_enabled = !debug_enabled
	
	if debug_enabled:
		print("\n" + "=".repeat(50))
		print("🔧 DEBUG MODE ENABLED")
		print("=".repeat(50))
		print("F1: Toggle Debug Mode")
		print("F2: Show/Hide Keybind Panel")
		print("=".repeat(50) + "\n")
		
		# Show enabled indicator
		if debug_ui:
			debug_ui.show_debug_enabled()
	else:
		print("\n🔧 DEBUG MODE DISABLED\n")
		
		# Hide all debug UI
		keybind_panel_visible = false
		if debug_ui:
			debug_ui.hide_all()
	
	debug_toggled.emit(debug_enabled)

func toggle_keybind_panel():
	"""Toggle the keybind reference panel"""
	if not debug_enabled:
		return
	
	keybind_panel_visible = !keybind_panel_visible
	
	if debug_ui:
		if keybind_panel_visible:
			debug_ui.show_keybind_panel()
		else:
			debug_ui.hide_keybind_panel()
	
	keybind_panel_toggled.emit(keybind_panel_visible)

func _setup_debug_ui():
	"""Create the debug UI node"""
	var ui_scene_path = "res://Systems/Debug/debug_ui.tscn"
	
	if ResourceLoader.exists(ui_scene_path):
		var ui_scene = load(ui_scene_path)
		debug_ui = ui_scene.instantiate()
		add_child(debug_ui)
	else:
		push_error("❌ Debug UI scene not found at: %s" % ui_scene_path)
		push_error("   Create debug_ui.tscn in res://Systems/Debug/")
