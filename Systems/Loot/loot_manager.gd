# res://systems/loot_manager.gd
extends Node

# Master loot table - all items in the game
@export var all_items: Array[LootItem] = []

# Cached items by type for fast filtering
var items_by_type: Dictionary = {}


func _ready():
	_build_lookup_tables()


func _build_lookup_tables():
	# Group items by type for fast filtering
	items_by_type.clear()
	
	for item in all_items:
		var type = item.item_type
		if type == "":
			type = "none"
		
		if not items_by_type.has(type):
			items_by_type[type] = []
		items_by_type[type].append(item)
	
	print("[LOOT MANAGER] Items organized into %d type categories" % items_by_type.size())


func generate_loot(enemy_level: int, loot_profile: LootProfile, player_luck: float = 0.0) -> Array[Dictionary]:
	print("[LOOT MANAGER] generate_loot - enemy_level: %d, player_luck: %.1f" % [enemy_level, player_luck])
	
	# Check if any loot drops at all
	var drop_roll = randf()
	print("[LOOT MANAGER] Drop chance roll: %.2f vs %.2f" % [drop_roll, loot_profile.drop_chance])
	
	if drop_roll > loot_profile.drop_chance:
		print("[LOOT MANAGER] ❌ Failed drop chance")
		return []
	
	print("[LOOT MANAGER] ✓ Passed drop chance")
	
	var dropped_items: Array[Dictionary] = []
	var num_drops = randi_range(loot_profile.min_drops, loot_profile.max_drops)
	print("[LOOT MANAGER] Rolling for %d items" % num_drops)
	
	for i in range(num_drops):
		print("[LOOT MANAGER] Rolling item %d/%d..." % [i + 1, num_drops])
		var item_data = _roll_single_item(enemy_level, loot_profile, player_luck)
		if item_data:
			dropped_items.append(item_data)
			print("[LOOT MANAGER] ✓ Rolled: %s (Lv.%d, %s)" % [
				item_data.item.item_name,
				item_data.item_level,
				ItemQuality.get_quality_name(item_data.item_quality)
			])
		else:
			print("[LOOT MANAGER] ❌ Failed to roll item")
	
	print("[LOOT MANAGER] Total items generated: %d" % dropped_items.size())
	return dropped_items


func _roll_single_item(enemy_level: int, profile: LootProfile, player_luck: float) -> Dictionary:
	# Get eligible items based on item type filters
	var eligible_items = _filter_eligible_items(profile)
	
	print("[LOOT MANAGER]   Found %d eligible items" % eligible_items.size())
	
	if eligible_items.is_empty():
		push_warning("[LOOT MANAGER]   ❌ No eligible items match the filters")
		return {}
	
	# Weighted random selection
	var selected_item = _weighted_select(eligible_items, profile)
	
	if not selected_item:
		return {}
	
	# Calculate item level (enemy_level ± variance)
	var item_level = enemy_level
	if profile.level_variance > 0:
		item_level += randi_range(-profile.level_variance, profile.level_variance)
	item_level = max(1, item_level)  # Minimum level 1
	
	# Roll item quality based on player luck
	var item_quality = ItemQuality.roll_quality(player_luck)
	
	# Calculate final value: base_value * (item_level) * quality_mod
	var quality_mod = ItemQuality.get_value_modifier(item_quality)
	var final_value = int(selected_item.base_value * (item_level) * quality_mod)
	
	return {
		"item": selected_item,
		"item_level": item_level,
		"item_quality": item_quality,
		"item_value": final_value
	}


func _filter_eligible_items(profile: LootProfile) -> Array[LootItem]:
	var eligible: Array[LootItem] = []
	
	for item in all_items:
		# Check item type filtering
		if not profile.allowed_item_types.is_empty():
			if not item.item_type in profile.allowed_item_types:
				continue
		
		if item.item_type in profile.excluded_item_types:
			continue
		
		# Check required tags
		if not profile.required_tags.is_empty():
			var has_required = false
			for tag in profile.required_tags:
				if tag in item.item_tags:
					has_required = true
					break
			if not has_required:
				continue
		
		# Check excluded tags
		var has_excluded = false
		for tag in profile.excluded_tags:
			if tag in item.item_tags:
				has_excluded = true
				break
		if has_excluded:
			continue
		
		eligible.append(item)
	
	return eligible


func _weighted_select(items: Array[LootItem], profile: LootProfile) -> LootItem:
	if items.is_empty():
		return null
	
	if items.size() == 1:
		return items[0]
	
	var weights: Array[float] = []
	var total_weight = 0.0
	
	for item in items:
		var weight = item.base_weight
		
		# Apply tag bonuses
		for tag in item.item_tags:
			if profile.bonus_tags.has(tag):
				weight *= profile.bonus_tags[tag]
		
		weight = max(0.001, weight)
		weights.append(weight)
		total_weight += weight
	
	# Weighted random selection
	var roll = randf() * total_weight
	var cumulative = 0.0
	
	for i in range(items.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return items[i]
	
	return items[-1]
