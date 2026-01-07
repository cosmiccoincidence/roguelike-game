# debug_maps.gd
# Debug functions for map manipulation
extends Node

var debug_manager: Node = null

func _ready():
	debug_manager = get_parent()

func skip_level():
	"""Skip to the next map level"""
	if not debug_manager or not debug_manager.debug_enabled:
		return
	
	print("\n" + "=".repeat(50))
	print("⏭️  SKIPPING TO NEXT LEVEL")
	print("=".repeat(50))
	
	var world = get_tree().get_first_node_in_group("world")
	if not world:
		print("❌ World not found!")
		print("   Make sure world node is in 'world' group")
		print("=".repeat(50) + "\n")
		return
	
	var current_map = world.get_node_or_null("CurrentMap")
	if current_map and current_map.has_method("is_generation_in_progress"):
		if current_map.is_generation_in_progress():
			print("❌ Cannot skip - map generation in progress!")
			print("   Wait for map to finish generating")
			print("=".repeat(50) + "\n")
			return
	
	var game_manager = world.get_node_or_null("GameManager")
	if not game_manager:
		print("❌ GameManager not found!")
		print("   Expected at: World/GameManager")
		print("=".repeat(50) + "\n")
		return
	
	if not game_manager.has_method("_on_player_reached_exit"):
		print("❌ GameManager missing _on_player_reached_exit() method!")
		print("=".repeat(50) + "\n")
		return
	
	print("✓ Triggering level transition...")
	game_manager._on_player_reached_exit()
	print("=".repeat(50) + "\n")
