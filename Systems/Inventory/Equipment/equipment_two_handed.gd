# equipment_two_handed.gd
# Handles two-handed weapon equipping logic
extends Node

var equipment_ref: Node = null

func initialize(equipment_node: Node):
	"""Called by main equipment to set reference"""
	equipment_ref = equipment_node

func handle_two_handed_equip(item_data, slot_index: int, equipped_items: Array) -> int:
	"""
	Handle equipping a two-handed weapon.
	Returns the actual slot index where the item was equipped (may differ from input).
	"""
	if not item_data or not item_data.has("weapon_hand") or item_data.weapon_hand != 3:
		return slot_index  # Not a two-handed weapon
	
	# Two-handed weapon: ensure it goes in primary slot
	var primary_slot = slot_index
	if EquipmentHandHelper.is_offhand_slot(slot_index):
		# If placed in offhand, move to corresponding primary
		primary_slot = EquipmentHandHelper.get_primary_slot_for_twohand(slot_index)
	
	var paired_slot = EquipmentHandHelper.get_paired_slot(primary_slot)
	
	# Clear the paired offhand slot
	if paired_slot >= 0:
		equipped_items[paired_slot] = null
	
	# Equip in primary slot
	equipped_items[primary_slot] = item_data
	
	# Mark the paired slot as occupied by setting a reference
	if paired_slot >= 0:
		equipped_items[paired_slot] = {"_twohand_occupant": true, "primary_slot": primary_slot}
	
	return primary_slot

func handle_two_handed_remove(slot_index: int, equipped_items: Array):
	"""Handle removing a two-handed weapon or its placeholder"""
	var item = equipped_items[slot_index]
	
	# Check if this is a two-handed weapon placeholder
	if item and typeof(item) == TYPE_DICTIONARY and item.has("_twohand_occupant"):
		# This is a placeholder - remove the actual item from primary slot
		var primary_slot = item.get("primary_slot", -1)
		if primary_slot >= 0:
			equipped_items[primary_slot] = null
		equipped_items[slot_index] = null
	else:
		# Check if removing a two-handed weapon - also clear paired slot
		if item and item.has("weapon_hand") and item.weapon_hand == 3:  # TWOHAND
			var paired_slot = EquipmentHandHelper.get_paired_slot(slot_index)
			if paired_slot >= 0:
				equipped_items[paired_slot] = null
		equipped_items[slot_index] = null

func is_two_handed_placeholder(item) -> bool:
	"""Check if an item is a two-handed weapon placeholder"""
	return typeof(item) == TYPE_DICTIONARY and item.has("_twohand_occupant")
