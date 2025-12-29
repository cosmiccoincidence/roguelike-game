# armor_stat_roller.gd
# Utility class for rolling armor stats based on item's base defense, level, and quality
class_name ArmorStatRoller
extends RefCounted

static func roll_armor_defense(base_defense: int, item_level: int, item_quality: int) -> int:
	"""Roll armor defense based on item's base defense, level, and quality"""
	
	# Validate base defense
	if base_defense <= 0:
		push_warning("Invalid base defense: %d, using default" % base_defense)
		return 3  # Default fallback
	
	# Scale with level (each level adds 15% to base defense)
	var level_multiplier = 1.0 + (item_level - 1) * 0.15
	
	# Scale with quality: Damaged (0) = 0.8x, Normal (1) = 1.0x, Fine (2) = 1.2x
	var quality_multiplier = 0.8 + (item_quality * 0.2)
	
	# Calculate final defense
	var final_defense = int(base_defense * level_multiplier * quality_multiplier)
	
	return max(1, final_defense)  # Minimum 1 defense
