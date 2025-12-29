# weapon_stat_roller.gd
# Utility class for rolling weapon stats based on item's base stats, level, and quality
class_name WeaponStatRoller
extends RefCounted

static func roll_weapon_damage(min_damage: int, max_damage: int, item_level: int, item_quality: int) -> int:
	"""Roll weapon damage based on item's damage range, level, and quality"""
	
	# Validate damage range
	if min_damage <= 0 or max_damage <= 0:
		push_warning("Invalid weapon damage range: %d-%d, using default" % [min_damage, max_damage])
		return 5  # Default fallback
	
	# Roll random damage within item's base range
	var base_damage = randi_range(min_damage, max_damage)
	
	# Scale with level (each level adds 10% to base damage)
	var level_multiplier = 1.0 + (item_level - 1) * 0.1
	
	# Scale with quality: Damaged (0) = 0.8x, Normal (1) = 1.0x, Fine (2) = 1.2x
	var quality_multiplier = 0.8 + (item_quality * 0.2)
	
	# Calculate final damage
	var final_damage = int(base_damage * level_multiplier * quality_multiplier)
	
	return max(1, final_damage)  # Minimum 1 damage
