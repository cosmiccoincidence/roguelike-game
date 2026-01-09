# equipment_stats_calculator.gd
# Calculates total stats from equipped items for the 6-stat system
class_name EquipmentStatsCalculator
extends RefCounted

static func calculate_total_stats(equipped_items: Array, active_weapon_set: int = 0) -> Dictionary:
	"""
	Calculate total stats from all equipped items.
	Only weapons from the active set (10-11 or 14-15) contribute to combat stats.
	Returns a dictionary with all calculated bonuses.
	"""
	var stats = {
		# ===== CORE STAT BONUSES =====
		"strength": 0,
		"dexterity": 0,
		"fortitude": 0,
		"vitality": 0,
		"agility": 0,
		"arcane": 0,
		
		# ===== RESOURCE BONUSES =====
		"max_health": 0,
		"max_stamina": 0,
		"max_mana": 0,
		
		# ===== REGEN BONUSES =====
		"health_regen": 0.0,
		"stamina_regen": 0.0,
		"mana_regen": 0.0,
		
		# ===== DEFENSE =====
		"armor": 0,
		"fire_resistance": 0.0,
		"frost_resistance": 0.0,
		"static_resistance": 0.0,
		"poison_resistance": 0.0,
		
		# ===== SOURCE DAMAGE REDUCTION =====
		"enemy_damage_reduction": 0.0,
		"environment_damage_reduction": 0.0,
		
		# ===== MOVEMENT =====
		"movement_speed": 0.0,
		
		# ===== WEAPON STATS (from active weapon) =====
		"weapon_damage": 0,
		"weapon_damage_type": "physical",  # physical, magic, fire, frost, static
		"weapon_range": 0.0,
		"weapon_speed": 0.0,
		"weapon_crit_chance": 0.0,
		"weapon_crit_multiplier": 1.0,
		"weapon_block_rating": 0.0,
		"weapon_parry_window": 0.0,
		
		# ===== COMBAT BONUSES =====
		"attack_speed": 0.0,  # Bonus attack speed from gear
		"crit_chance": 0.0,  # Bonus crit chance from gear
		"crit_damage": 0.0,  # Bonus crit damage from gear
		
		# ===== ABILITY COSTS =====
		"sprint_stamina_cost": 0.0,
		"dodge_roll_stamina_cost": 0.0,
		"dash_stamina_cost": 0.0,
		
		# ===== FLAGS =====
		"has_weapon": false
	}
	
	# Determine active weapon slots based on set
	var active_weapon_slots: Array[int] = []
	if active_weapon_set == 0:
		active_weapon_slots = [10, 11]  # L Hand 1, R Hand 1
	else:
		active_weapon_slots = [14, 15]  # L Hand 2, R Hand 2
	
	# Track equipped weapons (only from active set)
	var equipped_weapons = []
	
	# Collect weapons from active set
	for slot_idx in active_weapon_slots:
		if slot_idx < equipped_items.size():
			var item = equipped_items[slot_idx]
			if item and not _is_twohand_placeholder(item):
				equipped_weapons.append(item)
	
	# Process all equipped items
	for i in range(equipped_items.size()):
		var item = equipped_items[i]
		
		# Debug: what type is this?
		if item != null:
			var type_name = "Unknown"
			if item is Node:
				type_name = "Node"
			elif item is Dictionary:
				type_name = "Dictionary"
			elif item is Resource:
				type_name = "Resource"
			
			print("  Slot %d has item (type: %s)" % [i, type_name])
			
			if item is Node:
				print("    Item is a Node: %s" % item.name)
			elif item is Dictionary:
				print("    Item is a Dictionary with keys: %s" % str(item.keys()))
		
		if not item or _is_twohand_placeholder(item):
			continue
		
		print("  Processing item in slot %d: %s" % [i, item.get("item_name", "Unknown")])
		print("    Has 'armor' property: %s" % str(item.has("armor")))
		if item.has("armor"):
			print("    Armor value: %d" % item.armor)
		
		# ===== CORE STAT BONUSES =====
		_add_stat_bonus(stats, item, "strength")
		_add_stat_bonus(stats, item, "dexterity")
		_add_stat_bonus(stats, item, "fortitude")
		_add_stat_bonus(stats, item, "vitality")
		_add_stat_bonus(stats, item, "agility")
		_add_stat_bonus(stats, item, "arcane")
		
		# ===== RESOURCE BONUSES =====
		_add_stat_bonus(stats, item, "max_health")
		_add_stat_bonus(stats, item, "max_stamina")
		_add_stat_bonus(stats, item, "max_mana")
		
		# ===== REGEN BONUSES =====
		_add_stat_bonus(stats, item, "health_regen")
		_add_stat_bonus(stats, item, "stamina_regen")
		_add_stat_bonus(stats, item, "mana_regen")
		
		# ===== ARMOR (all pieces contribute) =====
		if item.has("armor") and item.armor > 0:
			stats.armor += item.armor
			print("    Added %d armor (total now: %d)" % [item.armor, stats.armor])
		# Legacy support - check both old naming conventions
		elif item.has("armor_rating") and item.armor_rating > 0:
			stats.armor += item.armor_rating
			print("    Added %d armor from armor_rating (total now: %d)" % [item.armor_rating, stats.armor])
		elif item.has("base_armor_rating") and item.base_armor_rating > 0:
			stats.armor += item.base_armor_rating
			print("    Added %d armor from base_armor_rating (total now: %d)" % [item.base_armor_rating, stats.armor])
		
		# ===== RESISTANCES (all pieces contribute) =====
		_add_stat_bonus(stats, item, "fire_resistance")
		_add_stat_bonus(stats, item, "frost_resistance")
		_add_stat_bonus(stats, item, "static_resistance")
		_add_stat_bonus(stats, item, "poison_resistance")
		
		# ===== DAMAGE REDUCTIONS =====
		_add_stat_bonus(stats, item, "enemy_damage_reduction")
		_add_stat_bonus(stats, item, "environment_damage_reduction")
		
		# ===== MOVEMENT =====
		_add_stat_bonus(stats, item, "movement_speed")
		
		# ===== COMBAT BONUSES (all pieces can contribute) =====
		_add_stat_bonus(stats, item, "attack_speed")
		_add_stat_bonus(stats, item, "crit_chance")
		_add_stat_bonus(stats, item, "crit_damage")
		
		# ===== ABILITY COSTS =====
		_add_stat_bonus(stats, item, "sprint_stamina_cost")
		_add_stat_bonus(stats, item, "dodge_roll_stamina_cost")
		_add_stat_bonus(stats, item, "dash_stamina_cost")
	
	# ===== WEAPON STATS (only from active weapon) =====
	if equipped_weapons.size() > 0:
		var primary_weapon = equipped_weapons[0]
		stats.has_weapon = true
		
		# Weapon damage
		if primary_weapon.has("weapon_damage"):
			stats.weapon_damage = primary_weapon.weapon_damage
		elif primary_weapon.has("damage"):  # Legacy
			stats.weapon_damage = primary_weapon.damage
		
		# Weapon damage type
		if primary_weapon.has("damage_type"):
			stats.weapon_damage_type = primary_weapon.damage_type
		
		# Weapon range
		if primary_weapon.has("weapon_range"):
			stats.weapon_range = primary_weapon.weapon_range
		elif primary_weapon.has("range"):  # Legacy
			stats.weapon_range = primary_weapon.range
		
		# Weapon speed
		if primary_weapon.has("weapon_speed"):
			stats.weapon_speed = primary_weapon.weapon_speed
		elif primary_weapon.has("attack_speed"):  # Legacy
			stats.weapon_speed = primary_weapon.attack_speed
		
		# Weapon crit chance
		if primary_weapon.has("weapon_crit_chance"):
			stats.weapon_crit_chance = primary_weapon.weapon_crit_chance
		elif primary_weapon.has("crit_chance"):  # Legacy
			stats.weapon_crit_chance = primary_weapon.crit_chance
		
		# Weapon crit multiplier
		if primary_weapon.has("weapon_crit_multiplier"):
			stats.weapon_crit_multiplier = primary_weapon.weapon_crit_multiplier
		elif primary_weapon.has("crit_multiplier"):  # Legacy
			stats.weapon_crit_multiplier = primary_weapon.crit_multiplier
		
		# Weapon block rating
		if primary_weapon.has("weapon_block_rating"):
			stats.weapon_block_rating = primary_weapon.weapon_block_rating
		elif primary_weapon.has("block_rating"):  # Legacy
			stats.weapon_block_rating = primary_weapon.block_rating
		
		# Weapon parry window
		if primary_weapon.has("weapon_parry_window"):
			stats.weapon_parry_window = primary_weapon.weapon_parry_window
		elif primary_weapon.has("parry_window"):  # Legacy
			stats.weapon_parry_window = primary_weapon.parry_window
	
	return stats

static func _add_stat_bonus(stats: Dictionary, item: Dictionary, stat_name: String):
	"""Helper to safely add stat bonus from item to totals"""
	if item.has(stat_name):
		var value = item[stat_name]
		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			stats[stat_name] += value

static func _is_twohand_placeholder(item) -> bool:
	"""Check if item is a two-handed placeholder"""
	if not item:
		return false
	return item.has("_twohand_occupant") and item._twohand_occupant

static func get_equipment_requirements(item: Dictionary) -> Dictionary:
	"""Get stat requirements for equipping an item"""
	var requirements = {}
	
	if item.has("required_strength") and item.required_strength > 0:
		requirements.strength = item.required_strength
	
	if item.has("required_dexterity") and item.required_dexterity > 0:
		requirements.dexterity = item.required_dexterity
	
	if item.has("required_fortitude") and item.required_fortitude > 0:
		requirements.fortitude = item.required_fortitude
	
	return requirements

static func format_item_stats(item: Dictionary) -> String:
	"""Format item stats for display in UI (tooltip, etc.)"""
	var lines = []
	
	# Core stat bonuses
	if item.get("strength", 0) != 0:
		lines.append("+%d Strength" % item.strength)
	if item.get("dexterity", 0) != 0:
		lines.append("+%d Dexterity" % item.dexterity)
	if item.get("fortitude", 0) != 0:
		lines.append("+%d Fortitude" % item.fortitude)
	if item.get("vitality", 0) != 0:
		lines.append("+%d Vitality" % item.vitality)
	if item.get("agility", 0) != 0:
		lines.append("+%d Agility" % item.agility)
	if item.get("arcane", 0) != 0:
		lines.append("+%d Arcane" % item.arcane)
	
	# Defense
	if item.get("armor", 0) != 0:
		lines.append("+%d Armor" % item.armor)
	
	# Resistances
	if item.get("fire_resistance", 0.0) != 0.0:
		lines.append("+%.0f%% Fire Resistance" % (item.fire_resistance * 100))
	if item.get("frost_resistance", 0.0) != 0.0:
		lines.append("+%.0f%% Frost Resistance" % (item.frost_resistance * 100))
	if item.get("static_resistance", 0.0) != 0.0:
		lines.append("+%.0f%% Static Resistance" % (item.static_resistance * 100))
	if item.get("poison_resistance", 0.0) != 0.0:
		lines.append("+%.0f%% Poison Resistance" % (item.poison_resistance * 100))
	
	# Weapon stats
	if item.has("weapon_damage"):
		lines.append("Damage: %d (%s)" % [item.weapon_damage, item.get("damage_type", "physical")])
	
	return "\n".join(lines)
