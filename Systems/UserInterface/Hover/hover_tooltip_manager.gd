extends Node
class_name HoverTooltipManager

## Manages hover tooltips for items, NPCs, and enemies
## Attach this to the player or a persistent node

signal tooltip_requested(target_node: Node3D, tooltip_data: Dictionary)
signal tooltip_cleared()

@export var camera: Camera3D
@export var raycast_distance: float = 1000.0
@export var tooltip_delay: float = 0.5  # Delay before showing tooltip
@export var tooltip_linger_duration: float = 3.0  # How long tooltip stays after mouse leaves

var current_hover_target: Node3D = null
var hover_timer: float = 0.0
var linger_timer: float = 0.0
var is_hovering: bool = false
var tooltip_visible: bool = false
var current_target_is_enemy: bool = false  # Track if current target is an enemy

func _ready():
	if not camera:
		push_error("HoverTooltipManager: No camera assigned!")
		return

func _process(delta):
	if not camera:
		return
	
	# Raycast from mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * raycast_distance
	
	var space = get_viewport().get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(query)
	
	var hit_target: Node3D = null
	
	if result and result.collider:
		var collider = result.collider
		
		# Check the collider itself first (for CharacterBody3D enemies/NPCs)
		if can_show_tooltip(collider):
			hit_target = collider
		# Then check parent (for StaticBody3D/Area3D with collision children)
		elif collider.get_parent() and can_show_tooltip(collider.get_parent()):
			hit_target = collider.get_parent()
	
	# Handle hover state changes
	if hit_target:
		handle_hover(hit_target, delta)
	else:
		handle_no_hover(delta)

func can_show_tooltip(node: Node) -> bool:
	"""Check if a node should show a tooltip"""
	# Check for enemy group
	if node.is_in_group("enemy"):
		return true
	
	# Check for npc group
	if node.is_in_group("npc"):
		return true
	
	# DON'T handle items - they have their own hover system in BaseItem
	
	# Check for explicit tooltip data
	if node.has_method("get_tooltip_data"):
		return true
	
	return false

func handle_hover(target: Node3D, delta: float):
	# If hovering over a different target, reset
	if target != current_hover_target:
		current_hover_target = target
		current_target_is_enemy = target.is_in_group("enemy")
		hover_timer = 0.0
		linger_timer = 0.0
		tooltip_visible = false
		tooltip_cleared.emit()
	
	is_hovering = true
	linger_timer = 0.0  # Reset linger while hovering
	
	# Increment hover timer
	hover_timer += delta
	
	# Show tooltip after delay
	if hover_timer >= tooltip_delay and not tooltip_visible:
		show_tooltip(target)
		tooltip_visible = true

func handle_no_hover(delta: float):
	is_hovering = false
	
	# If tooltip is visible, handle linger based on target type
	if tooltip_visible:
		# If target is no longer valid (died/deleted), hide immediately
		if current_hover_target and not is_instance_valid(current_hover_target):
			hide_tooltip()
			tooltip_visible = false
			current_hover_target = null
			hover_timer = 0.0
			linger_timer = 0.0
			return
		
		# Only linger for enemies
		if current_target_is_enemy:
			linger_timer += delta
			
			# Hide tooltip after linger duration
			if linger_timer >= tooltip_linger_duration:
				hide_tooltip()
				tooltip_visible = false
				current_hover_target = null
				hover_timer = 0.0
				linger_timer = 0.0
		else:
			# NPCs: hide immediately
			hide_tooltip()
			tooltip_visible = false
			current_hover_target = null
			hover_timer = 0.0
			linger_timer = 0.0
	else:
		# No tooltip visible and not hovering, reset everything
		current_hover_target = null
		hover_timer = 0.0
		linger_timer = 0.0

func show_tooltip(target: Node3D):
	var tooltip_data = get_tooltip_data(target)
	if tooltip_data:
		tooltip_requested.emit(target, tooltip_data)

func hide_tooltip():
	tooltip_cleared.emit()

func force_clear_tooltip():
	"""Force clear tooltip and reset all state - used when vision cone hides enemy"""
	tooltip_cleared.emit()
	tooltip_visible = false
	current_hover_target = null
	hover_timer = 0.0
	linger_timer = 0.0
	current_target_is_enemy = false

func get_tooltip_data(target: Node3D) -> Dictionary:
	"""Extract tooltip data from a target node"""
	var data = {}
	
	# Check for custom tooltip method
	if target.has_method("get_tooltip_data"):
		return target.get_tooltip_data()
	
	# Enemy
	if target.is_in_group("enemy"):
		data["name"] = target.get("display_name") if target.get("display_name") else target.get("item_name") if target.get("item_name") else "Enemy"
		data["type"] = "enemy"
		data["current_hp"] = target.get("current_health")
		data["max_hp"] = target.get("max_health")
		data["level"] = target.get("enemy_level") if target.get("enemy_level") else 1
		return data
	
	# NPC
	if target.is_in_group("npc"):
		data["name"] = target.get("display_name") if target.get("display_name") else target.get("item_name") if target.get("item_name") else "NPC"
		data["type"] = "npc"
		return data
	
	return data
