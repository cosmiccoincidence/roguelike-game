extends Node
class_name LootSpawner

## Static utility class for spawning loot items in the world

static func spawn_loot_from_table(loot_table: LootTable, spawn_position: Vector3, scene_root: Node, spread_radius: float = 1.0, spawner_height: float = 0.0) -> Array[Node3D]:
	if not loot_table:
		return []
	
	var items = loot_table.roll_loot()
	return spawn_items(items, spawn_position, scene_root, spread_radius, spawner_height)

static func spawn_items(item_scenes: Array[PackedScene], spawn_position: Vector3, scene_root: Node, spread_radius: float = 1.0, spawner_height: float = 0.0) -> Array[Node3D]:
	var spawned_items: Array[Node3D] = []
	
	print("LootSpawner: Attempting to spawn ", item_scenes.size(), " items")
	
	# Group items by scene path to enable stacking
	var item_counts: Dictionary = {}  # scene_path -> count
	
	for item_scene in item_scenes:
		if not item_scene:
			continue
		
		var scene_path = item_scene.resource_path
		if not item_counts.has(scene_path):
			item_counts[scene_path] = {"scene": item_scene, "count": 0}
		item_counts[scene_path].count += 1
	
	# Spawn one instance per unique item type
	for scene_path in item_counts.keys():
		var data = item_counts[scene_path]
		var item_instance = data.scene.instantiate()
		
		if item_instance is Node3D:
			# Check if stackable and set stack count
			var is_stackable = item_instance.get("stackable") if item_instance.has_method("get") else false
			var count = data.count
			
			# Add random spread
			var random_offset = Vector3(
				randf_range(-spread_radius, spread_radius),
				0,
				randf_range(-spread_radius, spread_radius)
			)
			
			var final_position = spawn_position + random_offset + Vector3(0, spawner_height, 0)
			
			# Add to scene first
			scene_root.add_child(item_instance)
			item_instance.global_position = final_position
			
			# Set stack count if stackable
			if is_stackable and count > 1:
				if item_instance.has_method("set"):
					item_instance.set("stack_count", count)
				# Update label to show stack count
				if item_instance.has_method("update_label_text"):
					item_instance.update_label_text()
				print("LootSpawner: Spawned stacked '", item_instance.name, "' (x", count, ") at ", final_position)
			else:
				# Non-stackable items spawn individually
				print("LootSpawner: Spawned '", item_instance.name, "' at ", final_position)
				spawned_items.append(item_instance)
				
				# Spawn remaining copies for non-stackable items
				for i in range(1, count):
					var extra_instance = data.scene.instantiate()
					if extra_instance is Node3D:
						var extra_offset = Vector3(
							randf_range(-spread_radius, spread_radius),
							0,
							randf_range(-spread_radius, spread_radius)
						)
						var extra_position = spawn_position + extra_offset + Vector3(0, spawner_height, 0)
						scene_root.add_child(extra_instance)
						extra_instance.global_position = extra_position
						print("LootSpawner: Spawned '", extra_instance.name, "' at ", extra_position)
						spawned_items.append(extra_instance)
				continue
			
			spawned_items.append(item_instance)
	
	print("LootSpawner: Successfully spawned ", spawned_items.size(), " item groups")
	return spawned_items

static func check_for_mesh(node: Node) -> bool:
	if node is MeshInstance3D:
		return node.visible and node.mesh != null
	for child in node.get_children():
		if check_for_mesh(child):
			return true
	return false

static func spawn_single_item(item_scene: PackedScene, spawn_position: Vector3, scene_root: Node) -> Node3D:
	if not item_scene:
		return null
	
	var item_instance = item_scene.instantiate()
	
	if item_instance is Node3D:
		scene_root.add_child(item_instance)
		item_instance.global_position = spawn_position + Vector3(0, 0.5, 0)
		return item_instance
	
	return null
