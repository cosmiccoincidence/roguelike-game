# equipment_stats_calculator.gd
# Utility to calculate total stats from equipped items
class_name EquipmentStatsCalculator
extends RefCounted

static func calculate_total_stats(equipped_items: Array) -> Dictionary:
	"""
	Calculate total stats from all equipped items.
	Returns a dictionary with all calculated stats.
	"""
	var stats = {
		"weapon_damage": 0,
		"armor_defense": 0,
		"weapon_range": 0.0,
		"weapon_speed": 0.0,
		"weapon_block_window": 0.0,
		"weapon_parry_window": 0.0,
		"has_weapon": false
	}
	
	# Weapon slots: 10, 11, 14, 15
	var weapon_slots = [10, 11, 14, 15]
	
	# Track equipped weapons
	var equipped_weapons = []
	
	for slot_idx in weapon_slots:
		if slot_idx < equipped_items.size():
			var item = equipped_items[slot_idx]
			if item and not _is_twohand_placeholder(item):
				equipped_weapons.append(item)
	
	# Sum armor defense from all armor pieces
	for item in equipped_items:
		if item and not _is_twohand_placeholder(item):
			if item.has("armor_defense") and item.armor_defense > 0:
				stats.armor_defense += item.armor_defense
	
	# Weapon stats - use primary weapon (first equipped weapon found)
	if equipped_weapons.size() > 0:
		var primary_weapon = equipped_weapons[0]
		stats.has_weapon = true
		
		# Weapon damage
		if primary_weapon.has("weapon_damage"):
			stats.weapon_damage = primary_weapon.weapon_damage
		
		# Weapon range
		if primary_weapon.has("weapon_range"):
			stats.weapon_range = primary_weapon.weapon_range
		
		# Weapon speed
		if primary_weapon.has("weapon_speed"):
			stats.weapon_speed = primary_weapon.weapon_speed
		
		# Weapon block window
		if primary_weapon.has("weapon_block_window"):
			stats.weapon_block_window = primary_weapon.weapon_block_window
		
		# Weapon parry window
		if primary_weapon.has("weapon_parry_window"):
			stats.weapon_parry_window = primary_weapon.weapon_parry_window
	
	return stats

static func _is_twohand_placeholder(item) -> bool:
	"""Check if an item is a two-handed weapon placeholder"""
	return typeof(item) == TYPE_DICTIONARY and item.has("_twohand_occupant")
