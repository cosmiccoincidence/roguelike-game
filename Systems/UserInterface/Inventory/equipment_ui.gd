# equipment_ui.gd
extends Panel

# ===== NODE REFERENCES =====
@onready var equipment_grid: GridContainer = $EquipmentGrid
var slot_tooltip: Control = null  # Will be set by InventoryUI

# ===== CONSTANTS =====
const SLOT_SCENE_PATH = "res://Systems/UserInterface/Inventory/inventory_slot.tscn"

# ===== GRID CONFIGURATION =====
var slot_size: int = 64
var equipment_columns: int = 4
var equipment_rows: int = 5

# Equipment slot gaps (indices to skip in grid)
var equipment_skip_slots: Array = [
	1, 5, 9, 13, 17,  # Entire 2nd column
	10, 11            # Row 3 positions 3 and 4
]

# Equipment slot names (in order of actual slots, not grid positions)
var equipment_slot_names: Array = [
	"Helmet",    # Slot 0
	"Amulet",    # Slot 1
	"Bag",       # Slot 2
	"Armor",     # Slot 3
	"Ring 1",    # Slot 4
	"Ring 2",    # Slot 5
	"Belt",      # Slot 6
	"Gloves",    # Slot 7
	"L Hand 1",  # Slot 8
	"R Hand 1",  # Slot 9
	"Boots",     # Slot 10
	"L Hand 2",  # Slot 11
	"R Hand 2"   # Slot 12
]

# ===== STATE =====
var player_ref: CharacterBody3D = null

# ===== INITIALIZATION =====

func _ready():
	# Make panel transparent
	_setup_transparent_panel()
	
	# Wait for Equipment singleton to be ready
	if not has_node("/root/Equipment"):
		push_warning("Equipment singleton not found - add equipment.gd to AutoLoad as 'Equipment'")
		return
	
	# Load slot scene
	var slot_scene = load(SLOT_SCENE_PATH)
	if not slot_scene:
		push_error("Could not load slot scene from: ", SLOT_SCENE_PATH)
		return
	
	# Setup equipment grid
	_setup_equipment_grid(slot_scene)
	
	# Connect signals
	Equipment.equipment_changed.connect(_update_equipment)
	
	# Get player reference
	player_ref = get_tree().get_first_node_in_group("player")
	
	# Initial update
	_update_equipment()

# ===== SETUP FUNCTIONS =====

func set_tooltip_manager(tooltip: Control):
	"""Called by InventoryUI to pass tooltip reference"""
	slot_tooltip = tooltip
	
	# Update all existing slots
	for child in equipment_grid.get_children():
		if child.has_method("set_tooltip_manager"):
			child.set_tooltip_manager(slot_tooltip)

func _setup_transparent_panel():
	"""Make equipment panel transparent"""
	var transparent_style = StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	add_theme_stylebox_override("panel", transparent_style)
	mouse_filter = Control.MOUSE_FILTER_PASS

func _setup_equipment_grid(slot_scene: PackedScene):
	"""Create equipment grid with gaps"""
	if not equipment_grid:
		return
	
	equipment_grid.columns = equipment_columns
	equipment_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var equipment_slot_index = 0
	
	for i in range(equipment_columns * equipment_rows):
		if i in equipment_skip_slots:
			# Create spacer for gap
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(slot_size, slot_size)
			spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			equipment_grid.add_child(spacer)
		else:
			# Create equipment slot
			var slot = slot_scene.instantiate()
			if not slot:
				continue
			
			slot.set_mouse_filter(Control.MOUSE_FILTER_STOP)
			slot.mouse_filter = Control.MOUSE_FILTER_STOP
			slot.custom_minimum_size = Vector2(slot_size, slot_size)
			slot.slot_index = equipment_slot_index
			slot.set_meta("is_equipment_slot", true)
			slot.add_to_group("equipment_slots")
			equipment_grid.add_child(slot)
			
			# Add slot name label
			if equipment_slot_index < equipment_slot_names.size():
				_add_slot_name_label(slot, equipment_slot_names[equipment_slot_index])
			
			if slot.has_method("set_tooltip_manager") and slot_tooltip:
				slot.set_tooltip_manager(slot_tooltip)
			
			equipment_slot_index += 1

func _add_slot_name_label(slot: Control, slot_name: String):
	"""Add name label to equipment slot"""
	var slot_name_label = Label.new()
	slot_name_label.name = "SlotNameLabel"
	slot_name_label.text = slot_name
	slot_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	slot_name_label.add_theme_font_size_override("font_size", 10)
	slot_name_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	slot_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	slot_name_label.anchor_left = 0
	slot_name_label.anchor_top = 0
	slot_name_label.anchor_right = 1
	slot_name_label.anchor_bottom = 0
	slot_name_label.offset_left = 2
	slot_name_label.offset_top = 2
	slot_name_label.offset_right = -2
	slot_name_label.offset_bottom = 14
	
	slot.add_child(slot_name_label)

# ===== UPDATE FUNCTIONS =====

func _update_equipment():
	"""Update equipment slots to display equipped items"""
	var equipped_items = Equipment.get_items()
	
	# Get only actual equipment slots (not spacers)
	var equipment_slots = []
	for child in equipment_grid.get_children():
		if child.has_method("set_item"):
			equipment_slots.append(child)
	
	for i in range(min(equipped_items.size(), equipment_slots.size())):
		var slot = equipment_slots[i]
		if equipped_items[i] != null:
			slot.set_item(equipped_items[i])
		else:
			slot.clear_item()

# ===== DROP HANDLING =====

func handle_outside_drop(mouse_pos: Vector2, dragged_slot: Control) -> bool:
	"""
	Check if drop is outside equipment grid and handle it.
	Returns true if drop was handled (outside grid).
	"""
	var equipment_rect = equipment_grid.get_global_rect()
	
	if not equipment_rect.has_point(mouse_pos):
		_drop_item_in_world(dragged_slot)
		return true
	
	return false

func _drop_item_in_world(dragged_slot: Control):
	"""Drop item from equipment into the game world"""
	var slot_idx = dragged_slot.get("dragged_from_slot_index")
	
	if slot_idx == null:
		return
	
	var item = Equipment.get_item_at_slot(slot_idx)
	if item and player_ref:
		_spawn_item_in_world(item)
	
	Equipment.remove_item_at_slot(slot_idx)

func _spawn_item_in_world(item: Dictionary):
	"""Spawn an item in the world"""
	if not item.has("scene") or not item.scene or not player_ref:
		return
	
	var forward = -player_ref.global_transform.basis.z
	var drop_position = player_ref.global_position + forward * 1 + Vector3(0, 0.3, 0)
	
	var item_instance = item.scene.instantiate()
	if not item_instance is Node3D:
		return
	
	get_tree().current_scene.add_child(item_instance)
	item_instance.global_position = drop_position
	
	# Restore item properties from equipment data
	if item_instance is BaseItem:
		# Restore level and quality
		if item.has("item_level"):
			item_instance.item_level = item.item_level
		if item.has("item_quality"):
			item_instance.item_quality = item.item_quality
		if item.has("value"):
			item_instance.value = item.value
		if item.has("item_subtype"):
			item_instance.item_subtype = item.item_subtype
		
		# Set stack count if item is stackable
		if item.get("stackable", false) and item.get("stack_count", 1) > 1:
			item_instance.stack_count = item.stack_count
		
		# Update properties after setting everything
		if item_instance.has_method("set_item_properties"):
			item_instance.set_item_properties(
				item.get("item_level", 1),
				item.get("item_quality", ItemQuality.Quality.NORMAL),
				item.get("value", 10)
			)
		elif item_instance.has_method("update_label_text"):
			item_instance.update_label_text()
	
	# Mark as just spawned so FOV doesn't hide it immediately
	if item_instance.has_method("set"):
		item_instance.set("just_spawned", true)
		item_instance.set("spawn_timer", 0.0)

# ===== UTILITY =====

func get_equipment_rect() -> Rect2:
	"""Get the global rect of the equipment grid"""
	return equipment_grid.get_global_rect()
