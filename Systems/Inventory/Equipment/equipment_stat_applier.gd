# equipment_stat_applier.gd
# Applies equipment stats to player stats component
extends Node

var player_stats: Node
var equipment: Node

func initialize(stats_component: Node, equipment_component: Node):
	"""Called to set references"""
	player_stats = stats_component
	equipment = equipment_component
	
	# Connect to equipment changes
	if equipment:
		equipment.equipment_changed.connect(_on_equipment_changed)

func _on_equipment_changed():
	"""Called when equipment changes - recalculate player stats"""
	print("EquipmentStatApplier: _on_equipment_changed() called!")
	apply_equipment_stats()

func apply_equipment_stats():
	"""Apply all equipment stats to player"""
	if not player_stats or not equipment:
		print("ERROR: Missing player_stats or equipment!")
		return
	
	print("=== Applying Equipment Stats ===")
	print("  Equipped items count: %d" % equipment.equipped_items.size())
	
	# Get total stats from all equipped items
	var gear_stats = EquipmentStatsCalculator.calculate_total_stats(
		equipment.equipped_items,
		equipment.get_active_weapon_set() if equipment.has_method("get_active_weapon_set") else 0
	)
	
	print("  Calculated gear stats:")
	print("    Strength: %d" % gear_stats.strength)
	print("    Dexterity: %d" % gear_stats.dexterity)
	print("    Armor: %d" % gear_stats.armor)
	print("    Fire Resist: %.1f%%" % (gear_stats.fire_resistance * 100))
	
	# ===== APPLY CORE STAT BONUSES =====
	player_stats.gear_strength = gear_stats.strength
	player_stats.gear_dexterity = gear_stats.dexterity
	player_stats.gear_fortitude = gear_stats.fortitude
	player_stats.gear_vitality = gear_stats.vitality
	player_stats.gear_agility = gear_stats.agility
	player_stats.gear_arcane = gear_stats.arcane
	
	# ===== APPLY RESOURCE BONUSES =====
	player_stats.gear_max_health = gear_stats.max_health
	player_stats.gear_max_stamina = gear_stats.max_stamina
	player_stats.gear_max_mana = gear_stats.max_mana
	
	# ===== APPLY REGEN BONUSES =====
	player_stats.gear_health_regen = gear_stats.health_regen
	player_stats.gear_stamina_regen = gear_stats.stamina_regen
	player_stats.gear_mana_regen = gear_stats.mana_regen
	
	# ===== APPLY ARMOR =====
	player_stats.gear_armor = gear_stats.armor
	
	# ===== APPLY RESISTANCES =====
	player_stats.gear_fire_resistance = gear_stats.fire_resistance
	player_stats.gear_frost_resistance = gear_stats.frost_resistance
	player_stats.gear_static_resistance = gear_stats.static_resistance
	player_stats.gear_poison_resistance = gear_stats.poison_resistance
	
	# ===== APPLY DAMAGE REDUCTIONS =====
	player_stats.gear_enemy_damage_reduction = gear_stats.enemy_damage_reduction
	player_stats.gear_environment_damage_reduction = gear_stats.environment_damage_reduction
	
	# ===== RECALCULATE ALL DERIVED STATS =====
	player_stats.recalculate_all_stats()
	
	print("  Final player stats:")
	print("    Total Strength: %d" % player_stats.strength)
	print("    Total Armor: %d" % player_stats.armor)
	print("=== Equipment Stats Applied ===")

func get_current_weapon_stats() -> Dictionary:
	"""Get stats from currently equipped weapon"""
	if not equipment:
		return {}
	
	var gear_stats = EquipmentStatsCalculator.calculate_total_stats(
		equipment.equipped_items,
		equipment.get_active_weapon_set() if equipment.has_method("get_active_weapon_set") else 0
	)
	
	return {
		"has_weapon": gear_stats.has_weapon,
		"damage": gear_stats.weapon_damage,
		"damage_type": gear_stats.weapon_damage_type,
		"range": gear_stats.weapon_range,
		"speed": gear_stats.weapon_speed,
		"crit_chance": gear_stats.weapon_crit_chance,
		"crit_multiplier": gear_stats.weapon_crit_multiplier,
		"block_rating": gear_stats.weapon_block_rating,
		"parry_window": gear_stats.weapon_parry_window
	}

func can_equip_item(item: Dictionary) -> bool:
	"""Check if player can equip item based on stat requirements"""
	if not player_stats or not item:
		return false
	
	var requirements = EquipmentStatsCalculator.get_equipment_requirements(item)
	
	# Use calculator to check requirements
	if player_stats.calculator:
		return player_stats.calculator.can_equip_item(requirements)
	
	# Fallback: manual check
	if requirements.has("strength") and player_stats.strength < requirements.strength:
		return false
	if requirements.has("dexterity") and player_stats.dexterity < requirements.dexterity:
		return false
	if requirements.has("fortitude") and player_stats.fortitude < requirements.fortitude:
		return false
	
	return true

func get_requirement_message(item: Dictionary) -> String:
	"""Get message explaining why item can't be equipped"""
	if not player_stats or not item:
		return ""
	
	var requirements = EquipmentStatsCalculator.get_equipment_requirements(item)
	if requirements.is_empty():
		return ""
	
	var missing = []
	
	if requirements.has("strength") and player_stats.strength < requirements.strength:
		missing.append("Strength: %d (need %d)" % [player_stats.strength, requirements.strength])
	
	if requirements.has("dexterity") and player_stats.dexterity < requirements.dexterity:
		missing.append("Dexterity: %d (need %d)" % [player_stats.dexterity, requirements.dexterity])
	
	if requirements.has("fortitude") and player_stats.fortitude < requirements.fortitude:
		missing.append("Fortitude: %d (need %d)" % [player_stats.fortitude, requirements.fortitude])
	
	if missing.is_empty():
		return ""
	
	return "Cannot equip - Missing: " + ", ".join(missing)
