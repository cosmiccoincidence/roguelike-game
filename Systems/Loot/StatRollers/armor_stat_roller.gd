# armor_stat_roller.gd
# Utility class for rolling armor stats based on subtype, level, and quality
class_name ArmorStatRoller
extends RefCounted

# Base armor values by subtype
const ARMOR_SUBTYPE_STATS = {
	"helmet": {"base_armor": 8, "slot_weight": 0.15},
	"chest": {"base_armor": 25, "slot_weight": 0.35},
	"pants": {"base_armor": 18, "slot_weight": 0.25},
	"boots": {"base_armor": 6, "slot_weight": 0.10},
	"gloves": {"base_armor": 5, "slot_weight": 0.10},
	"belt": {"base_armor": 4, "slot_weight": 0.05},
	"shield": {"base_armor": 15, "slot_weight": 0.20}
}

# Armor type modifiers
const ARMOR_TYPE_MODIFIERS = {
	"cloth": {
		"armor_mult": 0.4,  # 40% armor
		"fire_resist": 0.10,
		"frost_resist": 0.08,
		"static_resist": 0.12,
		"poison_resist": 0.05
	},
	"leather": {
		"armor_mult": 0.7,  # 70% armor
		"fire_resist": 0.05,
		"frost_resist": 0.03,
		"static_resist": 0.05,
		"poison_resist": 0.08
	},
	"mail": {
		"armor_mult": 1.0,  # 100% armor
		"fire_resist": 0.0,
		"frost_resist": 0.05,
		"static_resist": -0.05,  # Conducts electricity
		"poison_resist": 0.02
	},
	"plate": {
		"armor_mult": 1.3,  # 130% armor
		"fire_resist": -0.05,  # Conducts heat
		"frost_resist": 0.08,
		"static_resist": -0.10,  # Conducts electricity
		"poison_resist": 0.0
	}
}

static func roll_armor_stats(loot_item: Resource, item_level: int, item_quality: int) -> Dictionary:
	"""Roll all armor stats and return as dictionary"""
	var stats = {}
	
	var subtype = loot_item.item_subtype.to_lower()
	if not ARMOR_SUBTYPE_STATS.has(subtype):
		push_warning("Unknown armor subtype: %s" % subtype)
		return stats
	
	var base_stats = ARMOR_SUBTYPE_STATS[subtype]
	
	# Determine armor type
	var armor_type = "leather"  # Default
	if "armor_type" in loot_item:
		match loot_item.armor_type:
			0: armor_type = "cloth"
			1: armor_type = "leather"
			2: armor_type = "mail"
			3: armor_type = "plate"
	
	var type_mods = ARMOR_TYPE_MODIFIERS.get(armor_type, ARMOR_TYPE_MODIFIERS.leather)
	
	# Calculate multipliers
	var level_mult = 1.0 + (item_level - 1) * 0.15  # 15% per level
	var quality_mult = 1.0 + (item_quality * 0.25)  # 25% per quality tier
	
	# Roll armor rating
	var base_armor = base_stats.base_armor
	
	# Check for new properties first
	if "min_armor" in loot_item and loot_item.min_armor > 0:
		base_armor = randi_range(loot_item.min_armor, loot_item.max_armor)
	# Fall back to old property
	elif "base_armor_rating" in loot_item and loot_item.base_armor_rating > 0:
		base_armor = loot_item.base_armor_rating
	
	stats.armor = max(1, int(base_armor * type_mods.armor_mult * level_mult * quality_mult))
	
	# Add resistances based on armor type and quality
	stats.fire_resistance = type_mods.fire_resist * (1.0 + item_quality * 0.15)
	stats.frost_resistance = type_mods.frost_resist * (1.0 + item_quality * 0.15)
	stats.static_resistance = type_mods.static_resist * (1.0 + item_quality * 0.15)
	stats.poison_resistance = type_mods.poison_resist * (1.0 + item_quality * 0.15)
	
	# Add any base resistance bonuses from the loot item
	if "bonus_fire_resistance" in loot_item and loot_item.bonus_fire_resistance != 0:
		stats.fire_resistance += loot_item.bonus_fire_resistance
	if "bonus_frost_resistance" in loot_item and loot_item.bonus_frost_resistance != 0:
		stats.frost_resistance += loot_item.bonus_frost_resistance
	if "bonus_static_resistance" in loot_item and loot_item.bonus_static_resistance != 0:
		stats.static_resistance += loot_item.bonus_static_resistance
	if "bonus_poison_resistance" in loot_item and loot_item.bonus_poison_resistance != 0:
		stats.poison_resistance += loot_item.bonus_poison_resistance
	
	return stats

static func roll_base_armor_rating(base_armor: int, item_level: int, item_quality: int) -> int:
	"""
	LEGACY FUNCTION - For backwards compatibility with old loot system
	Roll armor rating based on base value, level, and quality
	"""
	# Validate base armor
	if base_armor <= 0:
		push_warning("Invalid base armor: %d, using default" % base_armor)
		return 3  # Default fallback
	
	# Scale with level (each level adds 15% to base armor)
	var level_multiplier = 1.0 + (item_level - 1) * 0.15
	
	# Scale with quality (each quality tier adds 25%)
	var quality_multiplier = 1.0 + (item_quality * 0.25)
	
	# Calculate final armor
	var final_armor = int(base_armor * level_multiplier * quality_multiplier)
	
	return max(1, final_armor)  # Minimum 1 armor

static func roll_special_armor_bonus(item_level: int, item_quality: int) -> Dictionary:
	"""Roll bonus special properties for armor"""
	var bonus = {}
	
	# Higher quality = more bonuses
	var bonus_chance = item_quality * 0.20  # 20% per quality tier
	
	if randf() < bonus_chance:
		# Pick a bonus type
		var bonus_type = randi() % 4
		
		match bonus_type:
			0:  # Damage reduction
				if randf() < 0.5:
					bonus.enemy_damage_reduction = 0.03 + (item_quality * 0.02)  # 3-11%
				else:
					bonus.environment_damage_reduction = 0.05 + (item_quality * 0.03)  # 5-17%
			1:  # Core stat bonus
				var stats = ["strength", "dexterity", "fortitude", "vitality", "agility", "arcane"]
				var chosen_stat = stats[randi() % stats.size()]
				bonus[chosen_stat] = 1 + item_quality  # 1-6 stat points
			2:  # Resource bonus
				var resources = ["max_health", "max_stamina", "max_mana"]
				var chosen_resource = resources[randi() % resources.size()]
				bonus[chosen_resource] = (5 + item_quality * 5)  # 5-30 resource
			3:  # Movement bonus
				bonus.movement_speed = 0.05 + (item_quality * 0.03)  # 5-20% speed
	
	return bonus
