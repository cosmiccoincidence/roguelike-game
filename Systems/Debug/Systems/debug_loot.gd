# debug_loot.gd
# Debug subsystem for loot system testing
extends Node

# Reference to main debug manager
var debug_manager: Node

func _ready():
	debug_manager = get_node_or_null("/root/DebugManager")
	if debug_manager:
		# Connect to debug signals
		debug_manager.debug_toggled.connect(_on_debug_toggled)
	
	print("[DEBUG LOOT] Ready")

func _on_debug_toggled(enabled: bool):
	"""Called when debug mode is toggled"""
	if not enabled:
		# Clean up any loot debug visualizations
		pass

func spawn_test_loot():
	"""Spawn test loot at player position using LootSpawner"""
	if not debug_manager or not debug_manager.debug_enabled:
		return
	
	print("\n" + "=".repeat(50))
	print("🎲 SPAWNING TEST LOOT")
	print("=".repeat(50))
	
	# Get player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("❌ No player found in scene!")
		print("   Make sure player is in 'player' group")
		print("=".repeat(50) + "\n")
		return
	
	# Get LootManager
	var loot_manager = get_node_or_null("/root/LootManager")
	if not loot_manager:
		print("❌ LootManager not found!")
		print("   Add it as autoload: Project → Project Settings → Autoload")
		print("=".repeat(50) + "\n")
		return
	
	# Check if items exist
	if loot_manager.all_items.is_empty():
		print("❌ No items in LootManager.all_items!")
		print("   Add LootItem resources to the all_items array in Inspector")
		print("=".repeat(50) + "\n")
		return
	
	print("✓ LootManager found with %d items" % loot_manager.all_items.size())
	
	# Try to load a test loot profile
	var profile_paths = [
		"res://Systems/Loot/Enemies/enemy1.tres",
		"res://Systems/Loot/Enemies/enemy1.tres",
		"res://Systems/Loot/Containers/chest.tres",
		"res://Systems/Loot/Containers/chest_weapon.tres"
	]
	
	var profile: LootProfile = null
	for path in profile_paths:
		if ResourceLoader.exists(path):
			profile = load(path)
			if profile:
				print("✓ Loaded profile: %s" % path)
				break
	
	if not profile:
		print("⚠️  No loot profile found, using first item directly")
		print("   Searched paths:")
		for path in profile_paths:
			print("   - %s" % path)
		
		# Spawn first item directly as fallback
		var first_item = loot_manager.all_items[0]
		if first_item and first_item.item_scene:
			var item_data = {
				"item": first_item,
				"item_level": 5,
				"item_quality": 1,
				"item_value": first_item.base_value,
				"stack_size": 1
			}
			
			var spawn_pos = player.global_position + Vector3(0, 0.5, 2)
			LootSpawner.spawn_loot_item(item_data, spawn_pos, get_tree().current_scene)
			print("✓ Spawned test item: %s" % first_item.item_name)
		else:
			print("❌ First item has no scene assigned!")
		
		print("=".repeat(50) + "\n")
		return
	
	# Generate loot using profile
	var enemy_level = 5
	print("Generating loot (Level %d, Profile: %s)..." % [enemy_level, profile.resource_path.get_file()])
	
	var spawn_pos = player.global_position + Vector3(0, 0.5, 2)
	LootSpawner.spawn_all_loot(profile, enemy_level, spawn_pos, get_tree().current_scene, player)
	
	print("✓ Loot spawned successfully!")
	print("=".repeat(50) + "\n")

func show_loot_manager_info():
	"""Display information about LootManager and loaded items"""
	if not debug_manager or not debug_manager.debug_enabled:
		return
	
	print("\n" + "=".repeat(50))
	print("📦 LOOT MANAGER INFO")
	print("=".repeat(50))
	
	var loot_manager = get_node_or_null("/root/LootManager")
	if not loot_manager:
		print("❌ LootManager not found!")
		print("=".repeat(50) + "\n")
		return
	
	print("✓ LootManager found")
	print("Total items: %d" % loot_manager.all_items.size())
	
	if loot_manager.all_items.is_empty():
		print("\n❌ No items in database!")
		print("=".repeat(50) + "\n")
		return
	
	# Group items by type
	var items_by_type = {}
	for item in loot_manager.all_items:
		if item:
			var type = item.item_type.to_lower()
			if not items_by_type.has(type):
				items_by_type[type] = []
			items_by_type[type].append(item)
	
	print("\nItems by type:")
	for type in items_by_type.keys():
		print("  %s: %d items" % [type.capitalize(), items_by_type[type].size()])
	
	print("\nFirst 10 items:")
	for i in range(min(10, loot_manager.all_items.size())):
		var item = loot_manager.all_items[i]
		if item:
			var scene_status = "✓" if item.item_scene else "❌"
			print("  %2d. %-20s [Lv.%2d] %s Scene" % [
				i + 1,
				item.item_name,
				item.base_item_level,
				scene_status
			])
	
	print("=".repeat(50) + "\n")
