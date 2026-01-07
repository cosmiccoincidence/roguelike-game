# inventory_stacking.gd
# Handles item stacking logic for the inventory system
extends Node

var inventory_ref: Node = null  # Reference to main inventory

func initialize(inventory_node: Node):
	"""Called by main inventory to set reference"""
	inventory_ref = inventory_node

func try_stack_item(item_data: Dictionary, amount: int) -> int:
	"""
	Try to stack item with existing stacks in inventory.
	Returns the remaining amount that couldn't be stacked.
	"""
	if not inventory_ref:
		return amount
	
	var item_name = item_data.get("name", "")
	var is_stackable = item_data.get("stackable", false)
	
	if not is_stackable:
		return amount  # Can't stack, return full amount
	
	var items = inventory_ref.get_items()
	var remaining = amount
	
	for item in items:
		if item != null and item.name == item_name and item.get("stackable", false):
			var space_in_stack = item.max_stack_size - item.stack_count
			var amount_to_add = min(remaining, space_in_stack)
			
			if amount_to_add > 0:
				item.stack_count += amount_to_add
				remaining -= amount_to_add
				
				if remaining <= 0:
					return 0  # Successfully stacked everything
	
	return remaining  # Return what couldn't be stacked

func create_new_stacks(item_data: Dictionary, amount: int, max_slots: int) -> bool:
	"""
	Create new stack(s) in empty inventory slots.
	Returns true if all stacks were created successfully.
	"""
	if not inventory_ref:
		return false
	
	var items = inventory_ref.get_items()
	var item_name = item_data.get("name", "")
	var is_stackable = item_data.get("stackable", false)
	var max_stack = item_data.get("max_stack_size", 99)
	var remaining = amount
	
	while remaining > 0:
		# Find first empty slot
		var empty_slot = -1
		for i in range(max_slots):
			if items[i] == null:
				empty_slot = i
				break
		
		if empty_slot == -1:
			print("Cannot add item: Inventory full")
			return false
		
		var stack_size = min(remaining, max_stack if is_stackable else 1)
		
		# Create item entry from dictionary
		items[empty_slot] = _create_item_entry(item_data, stack_size)
		
		remaining -= stack_size
	
	return true

func _create_item_entry(item_data: Dictionary, stack_size: int) -> Dictionary:
	"""Create a new item entry dictionary for inventory storage"""
	return {
		"name": item_data.get("name", "Unknown Item"),
		"icon": item_data.get("icon"),
		"scene": item_data.get("scene"),
		"mass": item_data.get("mass", 1.0),
		"durability": item_data.get("durability", 100),
		"value": item_data.get("value", 0),
		"stackable": item_data.get("stackable", false),
		"max_stack_size": item_data.get("max_stack_size", 99),
		"stack_count": stack_size,
		"item_type": item_data.get("item_type", ""),
		"item_level": item_data.get("item_level", 1),
		"item_quality": item_data.get("item_quality", 1),
		"item_subtype": item_data.get("item_subtype", ""),
		"required_strength": item_data.get("required_strength", 0),
		"required_dexterity": item_data.get("required_dexterity", 0),
		"weapon_class": item_data.get("weapon_class", ""),
		"weapon_damage": item_data.get("weapon_damage", 0),
		"armor_class": item_data.get("armor_class", ""),
		"armor_rating": item_data.get("armor_rating", 0),
		"weapon_hand": item_data.get("weapon_hand", 0),
		"weapon_range": item_data.get("weapon_range", 2.0),
		"weapon_speed": item_data.get("weapon_speed", 1.0),
		"weapon_block_rating": item_data.get("weapon_block_rating", 0.0),
		"weapon_parry_window": item_data.get("weapon_parry_window", 0.0),
		"weapon_crit_chance": item_data.get("weapon_crit_chance", 0.0),
		"weapon_crit_multiplier": item_data.get("weapon_crit_multiplier", 1.0)
	}
