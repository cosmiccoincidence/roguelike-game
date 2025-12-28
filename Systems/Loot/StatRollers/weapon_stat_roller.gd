# weapon_stat_roller.gd
# Utility class for rolling weapon stats based on subtype, level, and quality
class_name WeaponStatRoller
extends RefCounted

# Base weapon damage ranges by subtype
const WEAPON_SUBTYPE_STATS = {
	"sword": {"min_damage": 5, "max_damage": 12},
	"greatsword": {"min_damage": 10, "max_damage": 20},
	"axe": {"min_damage": 6, "max_damage": 14},
	"greataxe": {"min_damage": 12, "max_damage": 22},
	"dagger": {"min_damage": 3, "max_damage": 8},
	"bow": {"min_damage": 4, "max_damage": 10},
	"crossbow": {"min_damage": 6, "max_damage": 15},
	"staff": {"min_damage": 8, "max_damage": 15},
	"wand": {"min_damage": 5, "max_damage": 11},
	"mace": {"min_damage": 7, "max_damage": 13},
	"spear": {"min_damage": 6, "max_damage": 12}
}

static func roll_weapon_damage(item_subtype: String, item_level: int, item_quality: int) -> int:
	"""Roll weapon damage based on subtype, level, and quality"""
	
	# Get base damage range for this weapon subtype
	var subtype_key = item_subtype.to_lower()
	if not WEAPON_SUBTYPE_STATS.has(subtype_key):
		push_warning("Unknown weapon subtype: %s, using default damage" % item_subtype)
		return 5  # Default fallback
	
	var base_stats = WEAPON_SUBTYPE_STATS[subtype_key]
	
	# Roll random damage within base range
	var base_damage = randi_range(base_stats.min_damage, base_stats.max_damage)
	
	# Scale with level (each level adds 10% to base damage)
	var level_multiplier = 1.0 + (item_level - 1) * 0.1
	
	# Scale with quality: Damaged (0) = 0.8x, Normal (1) = 1.0x, Fine (2) = 1.2x
	var quality_multiplier = 0.8 + (item_quality * 0.2)
	
	# Calculate final damage
	var final_damage = int(base_damage * level_multiplier * quality_multiplier)
	
	return max(1, final_damage)  # Minimum 1 damage
