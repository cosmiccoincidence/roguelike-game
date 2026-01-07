# item_dropper.gd
# Shared utility for spawning items in the world and restoring their properties
# Used by both Inventory and Equipment systems
extends Node

func drop_item_in_world(item_data: Dictionary, drop_position: Vector3) -> Node3D:
	"""
	Spawn an item in the world at the specified position.
	Returns the spawned item instance, or null if spawn failed.
	"""
	if not item_data.has("scene") or not item_data.scene:
		push_warning("Cannot drop item: No scene reference")
		return null
	
	var item_instance = item_data.scene.instantiate()
	if not item_instance is Node3D:
		push_warning("Cannot drop item: Scene is not a Node3D")
		item_instance.queue_free()
		return null
	
	# Add to scene
	var current_scene = get_tree().current_scene
	if not current_scene:
		push_warning("Cannot drop item: No current scene")
		item_instance.queue_free()
		return null
	
	current_scene.add_child(item_instance)
	item_instance.global_position = drop_position
	
	# Restore item properties
	if item_instance is BaseItem:
		_restore_item_properties(item_instance, item_data)
	
	# Mark as just spawned so FOV doesn't hide it immediately
	if item_instance.has_method("set"):
		item_instance.set("just_spawned", true)
		item_instance.set("spawn_timer", 0.0)
	
	return item_instance

func _restore_item_properties(item_instance: Node, item_data: Dictionary):
	"""Restore all properties from item data dictionary to the item instance"""
	
	# Call set_item_properties first (sets up base item with defaults)
	if item_instance.has_method("set_item_properties"):
		item_instance.set_item_properties(
			item_data.get("item_level", 1),
			item_data.get("item_quality", ItemQuality.Quality.NORMAL),
			item_data.get("value", 10)
		)
	
	# NOW restore all the specific properties (these override defaults)
	
	# Basic properties
	if item_data.has("name"):
		item_instance.item_name = item_data.name
	if item_data.has("icon"):
		item_instance.item_icon = item_data.icon
	if item_data.has("item_type"):
		item_instance.item_type = item_data.item_type
	if item_data.has("item_subtype"):
		item_instance.item_subtype = item_data.item_subtype
	if item_data.has("item_level"):
		item_instance.item_level = item_data.item_level
	if item_data.has("item_quality"):
		item_instance.item_quality = item_data.item_quality
	if item_data.has("mass"):
		item_instance.mass = item_data.mass
	if item_data.has("durability"):
		item_instance.durability = item_data.durability
	if item_data.has("value"):
		item_instance.value = item_data.value
	
	# Stacking properties
	if item_data.has("stackable"):
		item_instance.stackable = item_data.stackable
	if item_data.has("max_stack_size"):
		item_instance.max_stack_size = item_data.max_stack_size
	if item_data.get("stackable", false) and item_data.get("stack_count", 1) > 1:
		item_instance.stack_count = item_data.stack_count
	
	# Stat requirements
	if item_data.has("required_strength"):
		item_instance.required_strength = item_data.required_strength
	if item_data.has("required_dexterity"):
		item_instance.required_dexterity = item_data.required_dexterity
	
	# Weapon stats
	if item_data.has("weapon_class"):
		item_instance.weapon_class = item_data.weapon_class
	if item_data.has("weapon_damage"):
		item_instance.weapon_damage = item_data.weapon_damage
	if item_data.has("weapon_hand"):
		item_instance.weapon_hand = item_data.weapon_hand
	if item_data.has("weapon_range"):
		item_instance.weapon_range = item_data.weapon_range
	if item_data.has("weapon_speed"):
		item_instance.weapon_speed = item_data.weapon_speed
	if item_data.has("weapon_block_rating"):
		item_instance.weapon_block_rating = item_data.weapon_block_rating
	if item_data.has("weapon_parry_window"):
		item_instance.weapon_parry_window = item_data.weapon_parry_window
	if item_data.has("weapon_crit_chance"):
		item_instance.weapon_crit_chance = item_data.weapon_crit_chance
	if item_data.has("weapon_crit_multiplier"):
		item_instance.weapon_crit_multiplier = item_data.weapon_crit_multiplier
	
	# Armor stats
	if item_data.has("armor_class"):
		item_instance.armor_class = item_data.armor_class
	if item_data.has("armor_rating"):
		item_instance.armor_rating = item_data.armor_rating
	if item_data.has("base_armor_rating"):
		item_instance.base_armor_rating = item_data.base_armor_rating
	
	# Finally update label text (visual only)
	if item_instance.has_method("update_label_text"):
		item_instance.update_label_text()

func calculate_drop_position(player: Node3D, offset_forward: float = 1.0, offset_up: float = 0.35) -> Vector3:
	"""Calculate drop position in front of player"""
	if not player:
		return Vector3.ZERO
	
	var forward = -player.global_transform.basis.z
	return player.global_position + forward * offset_forward + Vector3(0, offset_up, 0)
