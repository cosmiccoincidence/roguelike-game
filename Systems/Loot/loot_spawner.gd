# loot_spawner.gd
# Shared utility for spawning loot items in the world
# Used by both enemies and chests to avoid code duplication

class_name LootSpawner
extends RefCounted

static func spawn_loot_item(item_data: Dictionary, spawn_position: Vector3, parent_node: Node) -> void:
	"""
	Spawn a single loot item in the world.
	
	Parameters:
	- item_data: Dictionary containing item info from LootManager
	- spawn_position: Vector3 world position to spawn the item
	- parent_node: Node to add the spawned item to (usually current_scene)
	"""
	var item: LootItem = item_data["item"]
	var item_level: int = item_data["item_level"]
	var item_quality: int = item_data["item_quality"]
	var stack_size: int = item_data.get("stack_size", 1)
	
	if not item or not item.item_scene:
		push_warning("LootSpawner: Invalid item or missing scene")
		return
	
	# Instantiate the item
	var loot_instance = item.item_scene.instantiate()
	
	if not loot_instance:
		push_warning("LootSpawner: Failed to instantiate item scene")
		return
	
	# Add to scene first
	parent_node.add_child(loot_instance)
	
	# Find a valid spawn position with proper spacing
	var final_position = _find_valid_spawn_position(spawn_position, parent_node)
	loot_instance.global_position = final_position
	
	if loot_instance is BaseItem:
		# Use LootStatGenerator to create full item with all stats rolled
		var item_dict = LootStatGenerator.generate_item_stats(
			item,
			item_level,
			item_quality
		)
		
		# Override stack size if provided
		if stack_size > 1:
			item_dict["stack_count"] = stack_size
		
		# Apply all properties to the instance
		_apply_item_properties(loot_instance, item_dict)
		
		# Update label to reflect stack and quality
		if loot_instance.has_method("update_label_text"):
			loot_instance.update_label_text()
		
		# Debug output
		print("Spawned: %s (Lv.%d, %s)" % [
			item_dict.name,
			item_dict.level,
			LootStatGenerator.get_quality_name(item_dict.quality)
		])
		
		if item_dict.has("weapon_damage"):
			print("  Weapon: %d %s damage" % [
				item_dict.weapon_damage,
				item_dict.get("damage_type", "physical")
			])
		
		if item_dict.has("armor"):
			print("  Armor: %d" % item_dict.armor)

static func _apply_item_properties(instance: BaseItem, item_dict: Dictionary):
	"""Apply all properties from item dictionary to BaseItem instance"""
	
	# Basic properties
	instance.item_name = item_dict.get("name", "Item")
	instance.item_icon = item_dict.get("icon", null)  # Add icon
	instance.item_type = item_dict.get("type", "misc")
	instance.item_subtype = item_dict.get("subtype", "")
	instance.item_level = item_dict.get("level", 1)
	instance.item_quality = item_dict.get("quality", 0)
	instance.mass = item_dict.get("mass", 1.0)
	instance.value = item_dict.get("value", 10)
	instance.durability = item_dict.get("durability", 100)
	instance.stackable = item_dict.get("stackable", false)
	instance.max_stack_size = item_dict.get("max_stack_size", 1)
	
	# Stack count
	if item_dict.has("stack_count"):
		instance.stack_count = item_dict.stack_count
	
	# Requirements
	if "required_strength" in instance:
		instance.required_strength = item_dict.get("required_strength", 0)
	if "required_dexterity" in instance:
		instance.required_dexterity = item_dict.get("required_dexterity", 0)
	if "required_fortitude" in instance:
		instance.required_fortitude = item_dict.get("required_fortitude", 0)
	
	# Core stat bonuses
	if "strength" in instance:
		instance.strength = item_dict.get("strength", 0)
	if "dexterity" in instance:
		instance.dexterity = item_dict.get("dexterity", 0)
	if "fortitude" in instance:
		instance.fortitude = item_dict.get("fortitude", 0)
	if "vitality" in instance:
		instance.vitality = item_dict.get("vitality", 0)
	if "agility" in instance:
		instance.agility = item_dict.get("agility", 0)
	if "arcane" in instance:
		instance.arcane = item_dict.get("arcane", 0)
	
	# Resource bonuses
	if "max_health" in instance:
		instance.max_health = item_dict.get("max_health", 0)
	if "max_stamina" in instance:
		instance.max_stamina = item_dict.get("max_stamina", 0)
	if "max_mana" in instance:
		instance.max_mana = item_dict.get("max_mana", 0)
	
	# Regen bonuses
	if "health_regen" in instance:
		instance.health_regen = item_dict.get("health_regen", 0.0)
	if "stamina_regen" in instance:
		instance.stamina_regen = item_dict.get("stamina_regen", 0.0)
	if "mana_regen" in instance:
		instance.mana_regen = item_dict.get("mana_regen", 0.0)
	
	# Weapon stats
	if "weapon_damage" in instance:
		instance.weapon_damage = item_dict.get("weapon_damage", 0)
	if "damage_type" in instance:
		instance.damage_type = item_dict.get("damage_type", "physical")
	# Weapon stats (only set if present in item_dict, otherwise clear them)
	if "weapon_range" in instance:
		if "weapon_range" in item_dict:
			instance.weapon_range = item_dict.weapon_range
		else:
			instance.weapon_range = 0.0  # Clear scene default
	
	if "weapon_speed" in instance:
		if "weapon_speed" in item_dict:
			instance.weapon_speed = item_dict.weapon_speed
		else:
			instance.weapon_speed = 0.0  # Clear scene default
	
	if "weapon_crit_chance" in instance:
		if "weapon_crit_chance" in item_dict:
			instance.weapon_crit_chance = item_dict.weapon_crit_chance
		else:
			instance.weapon_crit_chance = 0.0  # Clear scene default
	
	if "weapon_crit_multiplier" in instance:
		if "weapon_crit_multiplier" in item_dict:
			instance.weapon_crit_multiplier = item_dict.weapon_crit_multiplier
		else:
			instance.weapon_crit_multiplier = 0.0  # Clear scene default
	if "weapon_block_rating" in instance:
		instance.weapon_block_rating = item_dict.get("weapon_block_rating", 0.0)
	if "weapon_parry_window" in instance:
		instance.weapon_parry_window = item_dict.get("weapon_parry_window", 0.0)
	if "weapon_hand" in instance:
		instance.weapon_hand = item_dict.get("hand", 0)  # enum value
	
	# Armor/Defense
	if "armor" in instance:
		instance.armor = item_dict.get("armor", 0)
	# Legacy support
	elif "armor_rating" in instance:
		instance.armor_rating = item_dict.get("armor", 0)
	
	# Armor type
	if "armor_type" in instance and "armor_type" in item_dict:
		instance.armor_type = item_dict.armor_type
	
	# Resistances
	if "fire_resistance" in instance:
		instance.fire_resistance = item_dict.get("fire_resistance", 0.0)
	if "frost_resistance" in instance:
		instance.frost_resistance = item_dict.get("frost_resistance", 0.0)
	if "static_resistance" in instance:
		instance.static_resistance = item_dict.get("static_resistance", 0.0)
	if "poison_resistance" in instance:
		instance.poison_resistance = item_dict.get("poison_resistance", 0.0)
	
	# Damage reduction
	if "enemy_damage_reduction" in instance:
		instance.enemy_damage_reduction = item_dict.get("enemy_damage_reduction", 0.0)
	if "environment_damage_reduction" in instance:
		instance.environment_damage_reduction = item_dict.get("environment_damage_reduction", 0.0)
	
	# Combat bonuses
	if "attack_speed" in instance:
		instance.attack_speed = item_dict.get("attack_speed", 0.0)
	if "crit_chance" in instance:
		instance.crit_chance = item_dict.get("crit_chance", 0.0)
	if "crit_damage" in instance:
		instance.crit_damage = item_dict.get("crit_damage", 0.0)
	
	# Movement
	if "movement_speed" in instance:
		instance.movement_speed = item_dict.get("movement_speed", 0.0)
	
	# Ability costs
	if "sprint_stamina_cost" in instance:
		instance.sprint_stamina_cost = item_dict.get("sprint_stamina_cost", 0.0)
	if "dodge_roll_stamina_cost" in instance:
		instance.dodge_roll_stamina_cost = item_dict.get("dodge_roll_stamina_cost", 0.0)
	if "dash_stamina_cost" in instance:
		instance.dash_stamina_cost = item_dict.get("dash_stamina_cost", 0.0)

static func _find_valid_spawn_position(origin: Vector3, parent_node: Node) -> Vector3:
	"""
	Find a valid spawn position that is:
	- At least 0.15 tiles from origin (source)
	- At least 0.15 tiles from player
	- At least 0.15 tiles from other items
	- On the ground (Y = 0.55)
	"""
	const MIN_SPACING = 0.15
	const MAX_ATTEMPTS = 20
	const MAX_RADIUS = 1.5
	
	# Get player position
	var player = parent_node.get_tree().get_first_node_in_group("player")
	var player_pos = player.global_position if player else Vector3.ZERO
	
	# Get all existing items
	var existing_items = parent_node.get_tree().get_nodes_in_group("item")
	
	for attempt in range(MAX_ATTEMPTS):
		# Generate random position in a circle around origin
		var angle = randf() * TAU
		var radius = randf_range(MIN_SPACING, MAX_RADIUS)
		var offset = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		
		# Use origin's X and Z, but set Y to ground level (0.55)
		var candidate_pos = Vector3(origin.x + offset.x, 0.55, origin.z + offset.z)
		
		# Check spacing from origin (2D distance)
		var dist_from_origin = Vector2(candidate_pos.x - origin.x, candidate_pos.z - origin.z).length()
		if dist_from_origin < MIN_SPACING:
			continue
		
		# Check spacing from player (2D distance, ignore Y)
		if player:
			var dist_from_player = Vector2(candidate_pos.x - player_pos.x, candidate_pos.z - player_pos.z).length()
			if dist_from_player < MIN_SPACING:
				continue
		
		# Check spacing from other items
		var too_close = false
		for item in existing_items:
			if is_instance_valid(item):
				var item_pos = item.global_position
				var dist_from_item = Vector2(candidate_pos.x - item_pos.x, candidate_pos.z - item_pos.z).length()
				if dist_from_item < MIN_SPACING:
					too_close = true
					break
		
		if not too_close:
			# Found a valid position!
			return candidate_pos
	
	# Fallback: place at minimum spacing on ground level
	var fallback_angle = randf() * TAU
	var fallback_offset = Vector3(cos(fallback_angle) * MIN_SPACING, 0.0, sin(fallback_angle) * MIN_SPACING)
	return Vector3(origin.x + fallback_offset.x, 0.55, origin.z + fallback_offset.z)

static func spawn_all_loot(loot_profile: LootProfile, enemy_level: int, spawn_position: Vector3, parent_node: Node, player: Node = null) -> void:
	"""
	Generate and spawn all loot from a loot profile.
	
	Parameters:
	- loot_profile: LootProfile resource defining what can drop
	- enemy_level: Level of enemy/chest for scaling
	- spawn_position: Vector3 world position to spawn items
	- parent_node: Node to add spawned items to
	- player: Optional player reference for luck calculation
	"""
	if not loot_profile:
		return
	
	# Get LootManager autoload singleton
	var loot_manager = parent_node.get_node_or_null("/root/LootManager")
	
	if not loot_manager:
		push_error("LootSpawner: LootManager not found at /root/LootManager!")
		return
	
	# Get player luck stat
	var player_luck = 0.0
	if player:
		# Try new stat system first
		var stats = player.get_node_or_null("PlayerStats")
		if stats and "luck" in stats:
			player_luck = stats.luck
		elif player.has_method("get_total_luck"):
			player_luck = player.get_total_luck()
		elif "luck" in player:
			player_luck = player.luck
	
	# Generate loot based on enemy_level and player_luck
	var loot_data = loot_manager.generate_loot(enemy_level, loot_profile, player_luck)
	
	# Spawn each item
	for item_data in loot_data:
		spawn_loot_item(item_data, spawn_position, parent_node)
