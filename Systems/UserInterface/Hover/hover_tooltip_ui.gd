extends Control
class_name HoverTooltipUI

## UI that displays hover tooltip information
## Add this as a Control node in your HUD

@onready var tooltip_panel: PanelContainer = $TooltipPanel
@onready var name_label: Label = $TooltipPanel/VBoxContainer/NameLabel
@onready var level_label: Label = $TooltipPanel/VBoxContainer/LevelLabel
@onready var hp_label: Label = $TooltipPanel/VBoxContainer/HPLabel

var tooltip_manager: HoverTooltipManager
var vision_cone: Node3D  # Reference to vision cone system
var manager_connected: bool = false
var current_target: Node3D = null  # Track what we're showing tooltip for
var health_signal_connected: bool = false  # Track if we connected to enemy's signal
var died_signal_connected: bool = false  # Track if we connected to died signal

func _ready():
	# Check if nodes exist
	if not tooltip_panel:
		push_error("HoverTooltipUI: tooltip_panel is null! Expected child node 'TooltipPanel' (PanelContainer)")
		push_error("  Current children: ", get_children())
		return
	
	if not name_label:
		push_error("HoverTooltipUI: name_label is null! Expected 'TooltipPanel/VBoxContainer/NameLabel'")
		return
	
	if not level_label:
		push_error("HoverTooltipUI: level_label is null! Expected 'TooltipPanel/VBoxContainer/LevelLabel'")
		return
	
	if not hp_label:
		push_error("HoverTooltipUI: hp_label is null! Expected 'TooltipPanel/VBoxContainer/HPLabel'")
		return
	
	# Start hidden
	tooltip_panel.visible = false
	
	# Find vision cone system
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Look for WorkingVisionCone as a child of player
		for child in player.get_children():
			if child.has_method("is_position_visible"):
				vision_cone = child
				break
	
	# Try to find manager immediately
	try_connect_to_manager()

func _process(_delta):
	# Keep trying to connect if not connected yet
	if not manager_connected:
		try_connect_to_manager()
	
	# Keep trying to find vision cone if not found
	if not vision_cone:
		# Try 1: Check player's children
		var player = get_tree().get_first_node_in_group("player")
		if player:
			for child in player.get_children():
				if child.has_method("is_position_visible"):
					vision_cone = child
					break
		
		# Try 2: Search entire scene tree for WorkingVisionCone
		if not vision_cone:
			var world = get_tree().get_first_node_in_group("world")
			if world:
				vision_cone = find_vision_cone_recursive(world)

	
	# If showing tooltip but target is invalid (died/deleted), hide immediately
	if tooltip_panel.visible and current_target and not is_instance_valid(current_target):
		_on_tooltip_cleared()
		return
	
	# If showing tooltip but target is not visible in vision cone, hide immediately
	if tooltip_panel.visible and current_target and is_instance_valid(current_target):
		if vision_cone and vision_cone.has_method("is_position_visible"):
			var is_visible = vision_cone.is_position_visible(current_target.global_position)
			if not is_visible:
				# Tell the manager to reset its state too
				if tooltip_manager:
					tooltip_manager.force_clear_tooltip()
				_on_tooltip_cleared()
				return
	
	if tooltip_panel.visible and current_target and is_instance_valid(current_target):
		# Position tooltip above the character's head
		var camera = get_viewport().get_camera_3d()
		if camera:
			# Get the character's world position + offset for above head
			var world_pos = current_target.global_position + Vector3(0, 2.0, 0)
			
			# Project to screen space
			var screen_pos = camera.unproject_position(world_pos)
			
			# Center the tooltip above the character
			var tooltip_size = tooltip_panel.size
			var final_pos = screen_pos - Vector2(tooltip_size.x / 2, tooltip_size.y + 10)
			
			# Keep tooltip on screen
			var viewport_size = get_viewport().get_visible_rect().size
			final_pos.x = clamp(final_pos.x, 0, viewport_size.x - tooltip_size.x)
			final_pos.y = clamp(final_pos.y, 0, viewport_size.y - tooltip_size.y)
			
			tooltip_panel.position = final_pos

func _on_tooltip_requested(target_node: Node3D, tooltip_data: Dictionary):
	# Disconnect from previous target if any
	if current_target and is_instance_valid(current_target):
		if health_signal_connected and current_target.has_signal("health_changed"):
			current_target.health_changed.disconnect(_on_enemy_health_changed)
			health_signal_connected = false
		if died_signal_connected and current_target.has_signal("died"):
			current_target.died.disconnect(_on_enemy_died)
			died_signal_connected = false
	
	# Store the target so we can position above it
	current_target = target_node
	
	# Connect to enemy's health_changed and died signals if it's an enemy
	if tooltip_data.get("type") == "enemy":
		if current_target.has_signal("health_changed"):
			current_target.health_changed.connect(_on_enemy_health_changed)
			health_signal_connected = true
		if current_target.has_signal("died"):
			current_target.died.connect(_on_enemy_died)
			died_signal_connected = true
	
	# Update tooltip content
	if tooltip_data.has("name"):
		name_label.text = tooltip_data["name"]
	else:
		name_label.text = "Unknown"
	
	# Show level for enemies
	if tooltip_data.get("type") == "enemy":
		if tooltip_data.has("level"):
			level_label.text = "Level %d" % tooltip_data["level"]
			level_label.visible = true
		else:
			level_label.visible = false
		
		# Show HP for enemies
		if tooltip_data.has("current_hp") and tooltip_data.has("max_hp"):
			hp_label.text = "HP: %d/%d" % [tooltip_data["current_hp"], tooltip_data["max_hp"]]
			hp_label.visible = true
		else:
			hp_label.visible = false
	else:
		# Hide level and HP for NPCs
		level_label.visible = false
		hp_label.visible = false
	
	# Show tooltip
	tooltip_panel.visible = true

func _on_tooltip_cleared():
	# Disconnect from health signal if connected
	if current_target and is_instance_valid(current_target):
		if health_signal_connected and current_target.has_signal("health_changed"):
			current_target.health_changed.disconnect(_on_enemy_health_changed)
			health_signal_connected = false
		if died_signal_connected and current_target.has_signal("died"):
			current_target.died.disconnect(_on_enemy_died)
			died_signal_connected = false
	
	tooltip_panel.visible = false
	current_target = null

func _on_enemy_health_changed(new_health: int, max_health: int):
	"""Called when enemy's health changes - update the HP display"""
	if hp_label and hp_label.visible:
		hp_label.text = "HP: %d/%d" % [new_health, max_health]

func _on_enemy_died():
	"""Called when enemy dies - hide tooltip immediately"""
	_on_tooltip_cleared()

func try_connect_to_manager():
	"""Try to find and connect to the tooltip manager"""
	if manager_connected:
		return
	
	# Find the tooltip manager (should be on player or in scene)
	tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	
	if not tooltip_manager:
		return
	
	# Connect to tooltip manager signals
	tooltip_manager.tooltip_requested.connect(_on_tooltip_requested)
	tooltip_manager.tooltip_cleared.connect(_on_tooltip_cleared)
	manager_connected = true

func find_vision_cone_recursive(node: Node) -> Node:
	"""Recursively search for a node with is_position_visible method"""
	if node.has_method("is_position_visible"):
		return node
	for child in node.get_children():
		var result = find_vision_cone_recursive(child)
		if result:
			return result
	return null
