# equipment_weapon_sets.gd
# Handles weapon set swapping and active set tracking
extends Node

var equipment_ref: Node = null
var active_weapon_set: int = 0  # 0 = slots 10-11 (L/R Hand 1), 1 = slots 14-15 (L/R Hand 2)

signal weapon_set_changed(new_set: int)

func initialize(equipment_node: Node):
	"""Called by main equipment to set reference"""
	equipment_ref = equipment_node

func swap_weapon_sets():
	"""Toggle between weapon set 0 (slots 10-11) and set 1 (slots 14-15)"""
	active_weapon_set = 1 if active_weapon_set == 0 else 0
	weapon_set_changed.emit(active_weapon_set)
	
	# Notify equipment that something changed
	if equipment_ref:
		equipment_ref.equipment_changed.emit()

func get_active_weapon_slots() -> Array[int]:
	"""Get the slot indices for the currently active weapon set"""
	if active_weapon_set == 0:
		return [10, 11]  # L Hand 1, R Hand 1
	else:
		return [14, 15]  # L Hand 2, R Hand 2

func is_weapon_slot_active(slot_index: int) -> bool:
	"""Check if a weapon slot is part of the active set"""
	var weapon_slots = [10, 11, 14, 15]
	if slot_index not in weapon_slots:
		return true  # Non-weapon slots are always active
	
	return slot_index in get_active_weapon_slots()

func get_active_set_number() -> int:
	"""Get the currently active weapon set number (0 or 1)"""
	return active_weapon_set
