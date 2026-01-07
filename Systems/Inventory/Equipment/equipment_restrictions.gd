# equipment_restrictions.gd
# Handles type, subtype, and stat requirement checking for equipment
extends Node

var equipment_ref: Node = null

func initialize(equipment_node: Node):
	"""Called by main equipment to set reference"""
	equipment_ref = equipment_node

func can_equip_item_in_slot(item_data, slot_index: int, slot_restrictions: Array, max_slots: int) -> bool:
	"""Check if an item can be equipped in a specific slot"""
	if slot_index < 0 or slot_index >= max_slots:
		return false
	
	if not item_data or not item_data.has("item_type"):
		return false
	
	var item_type = item_data.item_type.to_lower()
	var item_subtype = item_data.get("item_subtype", "").to_lower()
	
	var restriction = slot_restrictions[slot_index]
	var required_type = restriction.type.to_lower()
	var required_subtype = restriction.subtype.to_lower()
	
	# Check type first
	if item_type != required_type:
		return false
	
	# If subtype is required (not empty), check it
	if required_subtype != "":
		if item_subtype != required_subtype:
			return false
	
	# Additional check for weapons: validate hand restrictions
	if item_type == "weapon" and (EquipmentHandHelper.is_primary_slot(slot_index) or EquipmentHandHelper.is_offhand_slot(slot_index)):
		var weapon_hand = item_data.get("weapon_hand", 0)  # 0 = ANY (default)
		if not EquipmentHandHelper.can_equip_in_slot(weapon_hand, slot_index):
			return false
	
	# Check stat requirements
	if not check_stat_requirements(item_data):
		return false
	
	return true

func check_stat_requirements(item_data) -> bool:
	"""Check if player meets stat requirements to equip item"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Warning: No player found for stat requirement check")
		return true  # Allow equip if no player (shouldn't happen)
	
	# Get stats component or use player directly
	var stats_component = player.get_node_or_null("PlayerStats")
	
	# Check strength requirement
	var req_str = item_data.get("required_strength", 0)
	if req_str > 0:
		var player_str = null
		if stats_component and "strength" in stats_component:
			player_str = stats_component.strength
		elif "strength" in player:
			player_str = player.strength
		
		if player_str == null:
			print("Warning: Player missing strength stat")
			return true  # Allow if stat missing
		if player_str < req_str:
			print("Cannot equip: Requires %d Strength (you have %d)" % [req_str, player_str])
			return false
	
	# Check dexterity requirement
	var req_dex = item_data.get("required_dexterity", 0)
	if req_dex > 0:
		var player_dex = null
		if stats_component and "dexterity" in stats_component:
			player_dex = stats_component.dexterity
		elif "dexterity" in player:
			player_dex = player.dexterity
		
		if player_dex == null:
			print("Warning: Player missing dexterity stat")
			return true  # Allow if stat missing
		if player_dex < req_dex:
			print("Cannot equip: Requires %d Dexterity (you have %d)" % [req_dex, player_dex])
			return false
	
	# All requirements met
	return true

func validate_item_swap(from_item, to_item, from_slot: int, to_slot: int, slot_restrictions: Array, max_slots: int) -> bool:
	"""Check if items can be swapped between two slots"""
	# If moving an item to a slot, check if it can be equipped there
	if from_item != null and not can_equip_item_in_slot(from_item, to_slot, slot_restrictions, max_slots):
		print("Cannot swap: Item cannot be equipped in target slot")
		return false
	
	if to_item != null and not can_equip_item_in_slot(to_item, from_slot, slot_restrictions, max_slots):
		print("Cannot swap: Item cannot be equipped in source slot")
		return false
	
	return true

func get_restriction_error_message(item_data, slot_index: int, slot_restrictions: Array) -> String:
	"""Get a descriptive error message for why an item can't be equipped"""
	var restriction = slot_restrictions[slot_index]
	var item_type = item_data.get("item_type", "unknown")
	var item_subtype = item_data.get("item_subtype", "unknown")
	
	if restriction.subtype != "":
		return "Cannot equip %s (%s) in slot %d (requires %s - %s)" % [
			item_type, 
			item_subtype, 
			slot_index, 
			restriction.type, 
			restriction.subtype
		]
	else:
		return "Cannot equip %s in slot %d (requires %s - any subtype)" % [
			item_type, 
			slot_index, 
			restriction.type
		]
