# armor_stat_roller.gd
# Utility class for rolling armor stats based on subtype, level, and quality
class_name ArmorStatRoller
extends RefCounted

# Base armor defense values by subtype
const ARMOR_SUBTYPE_STATS = {
	"helmet": {"base_defense": 5},
	"bodyarmor": {"base_defense": 15},
	"pants": {"base_defense": 10},
	"boots": {"base_defense": 4},
	"gloves": {"base_defense": 3},
	"belt": {"base_defense": 6},
	"shield": {"base_defense": 12}
}

static func roll_armor_defense(item_subtype: String, item_level: int, item_quality: int) -> int:
	"""Roll armor defense based on subtype, level, and quality"""
	
	# Get base defense for this armor subtype
	var subtype_key = item_subtype.to_lower()
	if not ARMOR_SUBTYPE_STATS.has(subtype_key):
		push_warning("Unknown armor subtype: %s, using default defense" % item_subtype)
		return 3  # Default fallback
	
	var base_stats = ARMOR_SUBTYPE_STATS[subtype_key]
	var base_defense = base_stats.base_defense
	
	# Scale with level (each level adds 15% to base defense)
	var level_multiplier = 1.0 + (item_level - 1) * 0.15
	
	# Scale with quality: Damaged (0) = 0.8x, Normal (1) = 1.0x, Fine (2) = 1.2x
	var quality_multiplier = 0.8 + (item_quality * 0.2)
	
	# Calculate final defense
	var final_defense = int(base_defense * level_multiplier * quality_multiplier)
	
	return max(1, final_defense)  # Minimum 1 defense
