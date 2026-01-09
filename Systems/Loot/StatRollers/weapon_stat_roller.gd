# weapon_stat_roller.gd
# Utility class for rolling weapon stats based on subtype, level, and quality
class_name WeaponStatRoller
extends RefCounted

# Base weapon damage ranges by subtype
const WEAPON_SUBTYPE_STATS = {
	"sword": {
		"min_damage": 8, "max_damage": 15,
		"damage_type": "physical",
		"range": 1.5, "speed": 1.0,
		"crit_chance": 0.05, "crit_mult": 1.5
	},
	"greatsword": {
		"min_damage": 15, "max_damage": 28,
		"damage_type": "physical",
		"range": 2.0, "speed": 0.7,
		"crit_chance": 0.03, "crit_mult": 2.0
	},
	"dagger": {
		"min_damage": 4, "max_damage": 10,
		"damage_type": "physical",
		"range": 1.0, "speed": 1.5,
		"crit_chance": 0.15, "crit_mult": 1.8
	},
	"axe": {
		"min_damage": 10, "max_damage": 18,
		"damage_type": "physical",
		"range": 1.5, "speed": 0.9,
		"crit_chance": 0.07, "crit_mult": 1.7
	},
	"mace": {
		"min_damage": 9, "max_damage": 16,
		"damage_type": "physical",
		"range": 1.3, "speed": 0.95,
		"crit_chance": 0.04, "crit_mult": 1.5
	},
	"spear": {
		"min_damage": 7, "max_damage": 14,
		"damage_type": "physical",
		"range": 2.5, "speed": 1.1,
		"crit_chance": 0.06, "crit_mult": 1.6
	},
	"bow": {
		"min_damage": 6, "max_damage": 12,
		"damage_type": "physical",
		"range": 5.0, "speed": 1.0,
		"crit_chance": 0.10, "crit_mult": 1.7
	},
	"staff": {
		"min_damage": 12, "max_damage": 22,
		"damage_type": "magic",
		"range": 3.0, "speed": 0.8,
		"crit_chance": 0.08, "crit_mult": 1.6
	},
	"wand": {
		"min_damage": 8, "max_damage": 15,
		"damage_type": "magic",
		"range": 2.5, "speed": 1.2,
		"crit_chance": 0.10, "crit_mult": 1.5
	}
}

static func roll_weapon_stats(loot_item: Resource, item_level: int, item_quality: int) -> Dictionary:
	"""Roll all weapon stats and return as dictionary"""
	var stats = {}
	
	var subtype = loot_item.item_subtype.to_lower()
	var base_stats = WEAPON_SUBTYPE_STATS.get(subtype, null)
	
	if not base_stats:
		# Unknown subtype - use LootItem values if available
		if loot_item.weapon_damage > 0:
			# Calculate multipliers
			var level_mult = 1.0 + (item_level - 1) * 0.1  # 10% per level
			var quality_mult = 1.0 + (item_quality * 0.2)  # 20% per quality tier
			
			stats.weapon_damage = max(1, int(loot_item.weapon_damage * level_mult * quality_mult))
			stats.weapon_range = loot_item.weapon_range if loot_item.weapon_range > 0 else 1.5
			stats.weapon_speed = loot_item.weapon_speed if loot_item.weapon_speed > 0 else 1.0
			stats.weapon_crit_chance = loot_item.weapon_crit_chance * quality_mult
			stats.weapon_crit_multiplier = loot_item.weapon_crit_multiplier + (item_quality * 0.1)
			stats.damage_type = "physical"  # Default
			
			# Add physical damage subtype
			if "physical_damage_type" in loot_item:
				match loot_item.physical_damage_type:
					0: stats.physical_damage_type = "slash"
					1: stats.physical_damage_type = "pierce"
					2: stats.physical_damage_type = "blunt"
			else:
				stats.physical_damage_type = "slash"  # Default
		else:
			push_warning("Unknown weapon subtype '%s' and no weapon_damage set in LootItem!" % subtype)
		
		return stats
	
	# Known subtype - proceed normally
	# Calculate multipliers
	var level_mult = 1.0 + (item_level - 1) * 0.1  # 10% per level
	var quality_mult = 1.0 + (item_quality * 0.2)  # 20% per quality tier
	
	# Use weapon_damage from loot_item if set, otherwise use subtype defaults
	var base_damage = loot_item.weapon_damage if loot_item.weapon_damage > 0 else randi_range(base_stats.min_damage, base_stats.max_damage)
	
	stats.weapon_damage = max(1, int(base_damage * level_mult * quality_mult))
	
	# Damage type
	stats.damage_type = base_stats.damage_type
	
	# Physical damage subtype (only for physical weapons)
	if stats.damage_type == "physical":
		# Check if LootItem has it set
		if "physical_damage_type" in loot_item:
			match loot_item.physical_damage_type:
				0: stats.physical_damage_type = "slash"
				1: stats.physical_damage_type = "pierce"
				2: stats.physical_damage_type = "blunt"
		else:
			# Assign based on weapon subtype
			match subtype:
				"sword", "axe", "greatsword": stats.physical_damage_type = "slash"
				"dagger", "spear", "bow": stats.physical_damage_type = "pierce"
				"mace": stats.physical_damage_type = "blunt"
				_: stats.physical_damage_type = "slash"  # Default
	
	# Weapon properties
	stats.weapon_range = base_stats.range
	stats.weapon_speed = base_stats.speed
	stats.weapon_crit_chance = base_stats.crit_chance * quality_mult
	stats.weapon_crit_multiplier = base_stats.crit_mult + (item_quality * 0.1)
	
	return stats

static func roll_weapon_damage(min_damage: int, max_damage: int, item_level: int, item_quality: int) -> int:
	"""
	LEGACY FUNCTION - For backwards compatibility with old loot system
	Roll weapon damage based on min/max range, level, and quality
	"""
	# Validate damage range
	if min_damage <= 0 or max_damage <= 0:
		push_warning("Invalid weapon damage range: %d-%d, using default" % [min_damage, max_damage])
		return 5  # Default fallback
	
	# Roll random damage within range
	var base_damage = randi_range(min_damage, max_damage)
	
	# Scale with level (each level adds 10% to base damage)
	var level_multiplier = 1.0 + (item_level - 1) * 0.1
	
	# Scale with quality (each quality tier adds 20%)
	var quality_multiplier = 1.0 + (item_quality * 0.2)
	
	# Calculate final damage
	var final_damage = int(base_damage * level_multiplier * quality_multiplier)
	
	return max(1, final_damage)  # Minimum 1 damage

static func roll_elemental_weapon_bonus(item_level: int, item_quality: int) -> Dictionary:
	"""Roll bonus elemental stats for magical weapons"""
	var bonus = {}
	
	# Chance to add elemental bonus increases with quality
	var elemental_chance = item_quality * 0.15  # 15% per quality tier
	
	if randf() < elemental_chance:
		# Pick random element
		var elements = ["fire", "frost", "static", "poison"]
		var chosen_element = elements[randi() % elements.size()]
		
		# Add resistance to matching element
		var resist_amount = 0.05 + (item_quality * 0.03)  # 5-20% resistance
		bonus[chosen_element + "_resistance"] = resist_amount
		
		# Maybe change damage type to element (50% chance for high quality)
		if item_quality >= 3 and randf() < 0.5:
			bonus.damage_type = chosen_element
	
	return bonus
