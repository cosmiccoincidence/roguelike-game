# equipment_hand_helper.gd
# Helper class for validating weapon hand restrictions
class_name EquipmentHandHelper
extends RefCounted

# Weapon hand types (matches LootItem.EquipmentHand enum)
enum EquipmentHand {
	ANY = 0,      # Can equip in either hand
	PRIMARY = 1,  # Left hand only (slots 10, 14)
	OFFHAND = 2,  # Right hand only (slots 11, 15)
	TWOHAND = 3   # Takes both hands
}

# Primary weapon slots (left hand)
const PRIMARY_SLOTS = [10, 14]

# Offhand weapon slots (right hand)
const OFFHAND_SLOTS = [11, 15]

# Get paired slot for two-handed weapons
# Returns the offhand slot that corresponds to a primary slot (and vice versa)
static func get_paired_slot(slot_index: int) -> int:
	match slot_index:
		10: return 11  # L Hand 1 -> R Hand 1
		11: return 10  # R Hand 1 -> L Hand 1
		14: return 15  # L Hand 2 -> R Hand 2
		15: return 14  # R Hand 2 -> L Hand 2
		_: return -1

# Check if a weapon can be equipped in a specific slot based on hand restriction
static func can_equip_in_slot(equipment_hand: int, slot_index: int) -> bool:
	match equipment_hand:
		EquipmentHand.ANY:
			# Can equip in any weapon slot
			return slot_index in PRIMARY_SLOTS or slot_index in OFFHAND_SLOTS
		
		EquipmentHand.PRIMARY:
			# Only primary (left hand) slots
			return slot_index in PRIMARY_SLOTS
		
		EquipmentHand.OFFHAND:
			# Only offhand (right hand) slots
			return slot_index in OFFHAND_SLOTS
		
		EquipmentHand.TWOHAND:
			# Can place in either slot, but will occupy both
			return slot_index in PRIMARY_SLOTS or slot_index in OFFHAND_SLOTS
		
		_:
			return false

# Get the primary slot for a two-handed weapon
# If placing in offhand slot, returns the corresponding primary slot
static func get_primary_slot_for_twohand(slot_index: int) -> int:
	if slot_index in PRIMARY_SLOTS:
		return slot_index  # Already in primary
	elif slot_index in OFFHAND_SLOTS:
		return get_paired_slot(slot_index)  # Get corresponding primary
	return -1

# Check if slot is a primary (left hand) weapon slot
static func is_primary_slot(slot_index: int) -> bool:
	return slot_index in PRIMARY_SLOTS

# Check if slot is an offhand (right hand) weapon slot  
static func is_offhand_slot(slot_index: int) -> bool:
	return slot_index in OFFHAND_SLOTS
