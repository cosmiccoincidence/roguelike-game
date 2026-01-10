# debug_console.gd
# Interactive command line for debug commands
extends PanelContainer

# ===== CONFIGURATION =====
var max_history: int = 100
var max_output_lines: int = 20

# ===== STATE =====
var command_history: Array[String] = []
var history_index: int = -1
var is_visible: bool = false

# Static reference for checking from anywhere (like player movement)
static var instance: Control = null

# ===== NODE REFERENCES =====
var output_label: RichTextLabel
var input_field: LineEdit
var command_processor: Node  # Reference to DebugCommands

# ===== SIGNALS =====
signal command_entered(command: String)

func _ready():
	# Set static reference
	instance = self
	
	# Setup panel style
	_setup_panel_style()
	
	# Create UI
	_create_ui()
	
	# Position at bottom of screen with fixed size
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_right = 0
	offset_top = -250  # 250 pixels tall
	offset_bottom = 0
	
	# Make sure console processes input even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Set high z-index to be on top
	z_index = 1000
	
	# Start hidden
	visible = false

func _setup_panel_style():
	"""Setup semi-transparent dark background"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	style.border_color = Color(0.3, 0.7, 1.0, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style)

func _create_ui():
	"""Create the console UI elements"""
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "═══ DEBUG CONSOLE ═══"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	
	# Output area (scrollable)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 140)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)
	
	output_label = RichTextLabel.new()
	output_label.bbcode_enabled = true
	output_label.fit_content = true
	output_label.scroll_active = false
	output_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output_label.add_theme_font_size_override("normal_font_size", 12)
	output_label.add_theme_color_override("default_color", Color(0.9, 0.9, 0.9))
	scroll.add_child(output_label)
	
	# Input area
	var input_container = HBoxContainer.new()
	input_container.add_theme_constant_override("separation", 5)
	vbox.add_child(input_container)
	
	var prompt = Label.new()
	prompt.text = ">"
	prompt.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	prompt.add_theme_font_size_override("font_size", 14)
	input_container.add_child(prompt)
	
	input_field = LineEdit.new()
	input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_field.placeholder_text = "Enter command... (type 'help' for commands)"
	input_field.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure it captures mouse
	input_field.focus_mode = Control.FOCUS_ALL  # Ensure it can receive focus
	input_field.clear_button_enabled = false  # Don't show clear button
	input_field.context_menu_enabled = false  # Disable right-click menu
	# Don't connect to text_submitted - we'll handle ENTER manually
	input_container.add_child(input_field)
	
	# Initial help message
	print_line("[color=#4DAAFF]Debug Console Ready. Type 'help' for available commands.[/color]")

func _input(event):
	"""Handle console-specific input"""
	if not visible:
		return
	
	# Allow mouse clicks to reach the input field
	if event is InputEventMouseButton:
		return
	
	# Allow text input to reach the LineEdit
	# Only handle specific navigation/control keys
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER, KEY_KP_ENTER:
				# Handle ENTER manually to keep focus
				_submit_command()
				get_viewport().set_input_as_handled()
			KEY_F1:
				# Allow F1 to toggle debug mode (will also close console)
				# Don't handle this event so it reaches debug_inputs
				pass
			KEY_UP:
				_history_up()
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				_history_down()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE, KEY_F4:  # ESC or F4 to close
				toggle_console()
				get_viewport().set_input_as_handled()
			KEY_TAB, KEY_CAPSLOCK, KEY_SHIFT, KEY_CTRL, KEY_ALT:
				# Block modifier keys from game
				get_viewport().set_input_as_handled()
			_:
				# Let all other keys (letters, numbers, etc.) reach the input field
				# Don't call set_input_as_handled() for typing keys
				pass

func _submit_command():
	"""Submit command from input field (called manually on ENTER)"""
	var command = input_field.text
	
	if command.is_empty():
		return
	
	# Clear input but DON'T lose focus
	input_field.text = ""
	
	# Add to history
	_add_to_history(command)
	
	# Echo command
	print_line("[color=#FFFF4D]> %s[/color]" % command)
	
	# Process command
	if command_processor:
		command_processor.process_command(command, self)
	else:
		print_line("[color=#FF4D4D]Error: Command processor not initialized[/color]")
	
	# Emit signal
	command_entered.emit(command)
	
	# Scroll to bottom (don't await - just do it sync)
	if output_label.get_parent() is ScrollContainer:
		var scroll = output_label.get_parent() as ScrollContainer
		call_deferred("_scroll_to_bottom", scroll)

func _scroll_to_bottom(scroll: ScrollContainer):
	"""Deferred scroll to bottom"""
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func toggle_console():
	"""Toggle console visibility"""
	is_visible = !is_visible
	visible = is_visible
	
	if is_visible:
		# Wait a frame then grab focus to ensure UI is ready
		await get_tree().process_frame
		input_field.grab_focus()
		input_field.select_all()  # Select any existing text
	else:
		input_field.release_focus()

func show_console():
	"""Show the console"""
	is_visible = true
	visible = true
	input_field.grab_focus()

func hide_console():
	"""Hide the console"""
	is_visible = false
	visible = false
	input_field.release_focus()

func print_line(text: String):
	"""Print a line to the console output"""
	var current_text = output_label.text
	
	# Add new line
	if not current_text.is_empty():
		current_text += "\n"
	current_text += text
	
	# Limit output lines
	var lines = current_text.split("\n")
	if lines.size() > max_output_lines:
		lines = lines.slice(lines.size() - max_output_lines, lines.size())
		current_text = "\n".join(lines)
	
	output_label.text = current_text

func clear_output():
	"""Clear the console output"""
	output_label.text = ""

func _add_to_history(command: String):
	"""Add command to history"""
	# Don't add duplicates
	if command_history.size() > 0 and command_history[-1] == command:
		return
	
	command_history.append(command)
	
	# Limit history size
	if command_history.size() > max_history:
		command_history.pop_front()
	
	history_index = command_history.size()

func _history_up():
	"""Navigate up in command history"""
	if command_history.is_empty():
		return
	
	history_index = max(0, history_index - 1)
	input_field.text = command_history[history_index]
	input_field.caret_column = input_field.text.length()

func _history_down():
	"""Navigate down in command history"""
	if command_history.is_empty():
		return
	
	history_index = min(command_history.size(), history_index + 1)
	
	if history_index >= command_history.size():
		input_field.text = ""
	else:
		input_field.text = command_history[history_index]
	
	input_field.caret_column = input_field.text.length()

func set_command_processor(processor: Node):
	"""Set the command processor reference"""
	command_processor = processor

static func is_console_open() -> bool:
	"""Static helper to check if console is currently open"""
	return instance != null and instance.is_visible
