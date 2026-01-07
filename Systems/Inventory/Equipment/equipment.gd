# equipment.gd
# Main equipment system - delegates to component scripts
extends Node

var equipped_items: Array = []
var max_equipment_slots: int = 16  # 16 equipment slots for 4x4 grid

# Define what type and subtype each slot accepts
var slot_restrictions: Array = [
	{"type": "armor", "subtype": "helmet"},      # Slot 0 - Helmet
	{"type": "bag", "subtype": "bag"},           # Slot 1 - Bag
	{"type": "accessory", "subtype": "amulet"},  # Slot 2 - Amulet
	{"type": "trinket", "subtype": "totem"},     # Slot 3 - Totem
	{"type": "armor", "subtype": "bodyarmor"},   # Slot 4 - Bodyarmor
	{"type": "accessory", "subtype": "cape"},    # Slot 5 - Cape
	{"type": "accessory", "subtype": "ring"},    # Slot 6 - Ring 1
	{"type": "accessory", "subtype": "ring"},    # Slot 7 - Ring 2
	{"type": "armor", "subtype": "pants"},       # Slot 8 - Pants
	{"type": "armor", "subtype": "belt"},        # Slot 9 - Belt
	{"type": "weapon", "subtype": ""},           # Slot 10 - L Hand 1
	{"type": "weapon", "subtype": ""},           # Slot 11 - R Hand 1
	{"type": "armor", "subtype": "boots"},       # Slot 12 - Boots
	{"type": "armor", "subtype": "gloves"},      # Slot 13 - Gloves
	{"type": "weapon", "subtype": ""},           # Slot 14 - L Hand 2
	{"type": "weapon", "subtype": ""}            # Slot 15 - R Hand 2
]

# Component references
var restrictions_manager: Node
var weapon_sets_manager: Node
var two_handed_manager: Node

signal equipment_changed
signal weapon_set_changed(new_set: int)

func _ready():
	# Initialize equipment array
	equipped_items.resize(max_equipment_slots)
	for i in range(max_equipment_slots):
		equipped_items[i] = null
	
	# Create component scripts
	_setup_components()

func _setup_components():
	"""Create and initialize component scripts"""
	# Restrictions manager
	var restrictions_script = load("res://Systems/Inventory/Equipment/equipment_restrictions.gd")
	if restrictions_script:
		restrictions_manager = Node.new()
		restrictions_manager.name = "RestrictionsManager"
		restrictions_manager.set_script(restrictions_script)
		add_child(restrictions_manager)
		restrictions_manager.initialize(self)
	
	# Weapon sets manager
	var weapon_sets_script = load("res://Systems/Inventory/Equipment/equipment_weapon_sets.gd")
	if weapon_sets_script:
		weapon_sets_manager = Node.new()
		weapon_sets_manager.name = "WeaponSetsManager"
		weapon_sets_manager.set_script(weapon_sets_script)
		add_child(weapon_sets_manager)
		weapon_sets_manager.initialize(self)
		weapon_sets_manager.weapon_set_changed.connect(_on_weapon_set_changed)
	
	# Two-handed manager
	var two_handed_script = load("res://Systems/Inventory/Equipment/equipment_two_handed.gd")
	if two_handed_script:
		two_handed_manager = Node.new()
		two_handed_manager.name = "TwoHandedManager"
		two_handed_manager.set_script(two_handed_script)
		add_child(two_handed_manager)
		two_handed_manager.initialize(self)

# ===== SIGNAL RELAYS =====

func _on_weapon_set_changed(new_set: int):
	weapon_set_changed.emit(new_set)

# ===== WEAPON SET FUNCTIONS =====

func swap_weapon_sets():
	"""Toggle between weapon sets"""
	if weapon_sets_manager:
		weapon_sets_manager.swap_weapon_sets()

func get_active_weapon_slots() -> Array[int]:
	"""Get active weapon slot indices"""
	if weapon_sets_manager:
		return weapon_sets_manager.get_active_weapon_slots()
	return [10, 11]  # Default to set 0

func is_weapon_slot_active(slot_index: int) -> bool:
	"""Check if weapon slot is active"""
	if weapon_sets_manager:
		return weapon_sets_manager.is_weapon_slot_active(slot_index)
	return true

# ===== STATS FUNCTIONS =====

func get_equipment_stats() -> Dictionary:
	"""Get calculated stats from all equipped items"""
	var active_set = weapon_sets_manager.get_active_set_number() if weapon_sets_manager else 0
	return EquipmentStatsCalculator.calculate_total_stats(equipped_items, active_set)

# ===== RESTRICTION FUNCTIONS =====

func can_equip_item_in_slot(item_data, slot_index: int) -> bool:
	"""Check if item can be equipped in slot"""
	if restrictions_manager:
		return restrictions_manager.can_equip_item_in_slot(item_data, slot_index, slot_restrictions, max_equipment_slots)
	return false

# ===== ITEM MANAGEMENT =====

func set_item_at_slot(slot_index: int, item_data):
	"""Set an item at a specific equipment slot"""
	if slot_index < 0 or slot_index >= max_equipment_slots:
		return false
	
	# If item_data is null (clearing slot), allow it
	if item_data == null or can_equip_item_in_slot(item_data, slot_index):
		# Handle two-handed weapons
		if two_handed_manager and item_data and item_data.has("weapon_hand") and item_data.weapon_hand == 3:
			two_handed_manager.handle_two_handed_equip(item_data, slot_index, equipped_items)
		else:
			# Normal equip
			equipped_items[slot_index] = item_data
		
		equipment_changed.emit()
		# Notify inventory system to update mass
		Inventory._update_mass_signals()
		return true
	else:
		# Item can't be equipped - show error
		if restrictions_manager:
			var error_msg = restrictions_manager.get_restriction_error_message(item_data, slot_index, slot_restrictions)
			push_warning(error_msg)
		return false

func swap_items(from_slot: int, to_slot: int):
	"""Swap items between two equipment slots"""
	if from_slot < 0 or from_slot >= max_equipment_slots:
		return
	if to_slot < 0 or to_slot >= max_equipment_slots:
		return
	
	var from_item = equipped_items[from_slot]
	var to_item = equipped_items[to_slot]
	
	# Check if items can be equipped in their new slots
	if restrictions_manager:
		if not restrictions_manager.validate_item_swap(from_item, to_item, from_slot, to_slot, slot_restrictions, max_equipment_slots):
			return
	
	# Swap the items
	var temp = equipped_items[from_slot]
	equipped_items[from_slot] = equipped_items[to_slot]
	equipped_items[to_slot] = temp
	
	equipment_changed.emit()
	Inventory._update_mass_signals()

func remove_item_at_slot(slot_index: int):
	"""Remove item from equipment slot"""
	if slot_index < 0 or slot_index >= max_equipment_slots:
		return
	
	# Handle two-handed weapon removal
	if two_handed_manager:
		two_handed_manager.handle_two_handed_remove(slot_index, equipped_items)
	else:
		equipped_items[slot_index] = null
	
	equipment_changed.emit()
	Inventory._update_mass_signals()

# ===== UTILITY =====

func get_item_at_slot(slot_index: int):
	"""Get item at specific slot"""
	if slot_index >= 0 and slot_index < max_equipment_slots:
		return equipped_items[slot_index]
	return null

func get_items() -> Array:
	"""Get all equipped items"""
	return equipped_items

func clear():
	"""Clear all equipment"""
	for i in range(max_equipment_slots):
		equipped_items[i] = null
	equipment_changed.emit()

func get_slot_requirement(slot_index: int) -> Dictionary:
	"""Get the type/subtype requirement for a specific slot"""
	if slot_index >= 0 and slot_index < max_equipment_slots:
		return slot_restrictions[slot_index]
	return {"type": "", "subtype": ""}
