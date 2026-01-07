# debug_fov.gd
# Debug subsystem for fog of war (field of view) testing
extends Node

# Reference to main debug manager
var debug_manager: Node

func _ready():
	debug_manager = get_node_or_null("/root/DebugManager")
	if debug_manager:
		# Connect to debug signals
		debug_manager.debug_toggled.connect(_on_debug_toggled)
	
	print("[DEBUG FOV] Ready")

func _on_debug_toggled(enabled: bool):
	"""Called when debug mode is toggled"""
	if not enabled:
		# Re-enable fog system if it was disabled
		var fog_system = _get_fog_system()
		if fog_system and fog_system.get("debug_disabled"):
			fog_system.debug_disabled = false
			# Restore fog visibility based on explored state
			if fog_system.has_method("debug_toggle_system"):
				# Call the internal restore logic
				for tile_key in fog_system.fog_meshes.keys():
					if is_instance_valid(fog_system.fog_meshes[tile_key]):
						var is_revealed = fog_system.revealed_tiles.get(tile_key, false)
						fog_system.fog_meshes[tile_key].visible = not is_revealed

func _get_fog_system() -> Node:
	"""Find the FogOfWar node in the scene"""
	return get_tree().get_first_node_in_group("fog_of_war")

func toggle_fov_system():
	"""Toggle fog of war system on/off (M key)"""
	if not debug_manager or not debug_manager.debug_enabled:
		return
	
	var fog_system = _get_fog_system()
	if not fog_system:
		print("❌ FogOfWar system not found!")
		print("   Make sure FogOfWar node is in 'fog_of_war' group")
		return
	
	if not "debug_disabled" in fog_system:
		print("❌ FogOfWar missing debug_disabled variable!")
		return
	
	# Toggle the system
	if fog_system.has_method("debug_toggle_system"):
		fog_system.debug_toggle_system()
	else:
		# Manual toggle if method doesn't exist
		fog_system.debug_disabled = !fog_system.debug_disabled
		
		if fog_system.debug_disabled:
			print("\n" + "=".repeat(50))
			print("👁️  FOG OF WAR DISABLED")
			print("=".repeat(50))
			print("All fog is hidden")
			print("=".repeat(50) + "\n")
		else:
			print("\n" + "=".repeat(50))
			print("👁️  FOG OF WAR ENABLED")
			print("=".repeat(50))
			print("Fog restored based on explored areas")
			print("=".repeat(50) + "\n")

func reset_explored_map():
	"""Reset all explored areas (N key)"""
	if not debug_manager or not debug_manager.debug_enabled:
		return
	
	var fog_system = _get_fog_system()
	if not fog_system:
		print("❌ FogOfWar system not found!")
		return
	
	if fog_system.get("debug_disabled"):
		print("⚠️  Cannot reset - FOV system is disabled")
		print("   Enable system first with M key")
		return
	
	print("\n" + "=".repeat(50))
	print("🔄 RESETTING EXPLORED MAP")
	print("=".repeat(50))
	
	# Count tiles being reset
	var reset_count = 0
	if fog_system.has_method("debug_reset_fog"):
		fog_system.debug_reset_fog()
		
		# Count revealed tiles
		for tile_key in fog_system.revealed_tiles.keys():
			if not fog_system.revealed_tiles[tile_key]:
				reset_count += 1
	else:
		print("❌ FogOfWar missing debug_reset_fog() method!")
		print("=".repeat(50) + "\n")
		return
	
	print("✓ All explored areas reset")
	print("Fog tiles restored: %d" % reset_count)
	print("=".repeat(50) + "\n")

func reveal_entire_map():
	"""Reveal entire map (B key)"""
	if not debug_manager or not debug_manager.debug_enabled:
		return
	
	var fog_system = _get_fog_system()
	if not fog_system:
		print("❌ FogOfWar system not found!")
		return
	
	if fog_system.get("debug_disabled"):
		print("⚠️  Cannot reveal - FOV system is disabled")
		print("   Enable system first with M key")
		return
	
	print("\n" + "=".repeat(50))
	print("🗺️  REVEALING ENTIRE MAP")
	print("=".repeat(50))
	
	# Count tiles being revealed
	var revealed_count = 0
	if fog_system.has_method("reveal_all"):
		fog_system.reveal_all()
		
		# Count revealed tiles
		for tile_key in fog_system.revealed_tiles.keys():
			if fog_system.revealed_tiles[tile_key]:
				revealed_count += 1
	else:
		print("❌ FogOfWar missing reveal_all() method!")
		print("=".repeat(50) + "\n")
		return
	
	print("✓ Entire map revealed")
	print("Tiles revealed: %d" % revealed_count)
	print("=".repeat(50) + "\n")

func show_fov_info():
	"""Display fog of war system information"""
	if not debug_manager or not debug_manager.debug_enabled:
		return
	
	print("\n" + "=".repeat(50))
	print("👁️  FOG OF WAR INFO")
	print("=".repeat(50))
	
	var fog_system = _get_fog_system()
	if not fog_system:
		print("❌ FogOfWar system not found!")
		print("=".repeat(50) + "\n")
		return
	
	print("System Status: %s" % ("DISABLED" if fog_system.get("debug_disabled") else "ENABLED"))
	print("Passive Mode: %s" % ("YES" if fog_system.get("is_passive_mode") else "No"))
	
	# Count statistics
	var total_tiles = fog_system.fog_meshes.size()
	var revealed_tiles = 0
	var visible_fog = 0
	
	for tile_key in fog_system.revealed_tiles.keys():
		if fog_system.revealed_tiles[tile_key]:
			revealed_tiles += 1
	
	for mesh in fog_system.fog_meshes.values():
		if is_instance_valid(mesh) and mesh.visible:
			visible_fog += 1
	
	print("\nStatistics:")
	print("  Total fog tiles: %d" % total_tiles)
	print("  Explored tiles: %d (%.1f%%)" % [revealed_tiles, (revealed_tiles / float(total_tiles) * 100) if total_tiles > 0 else 0])
	print("  Hidden tiles: %d (%.1f%%)" % [total_tiles - revealed_tiles, ((total_tiles - revealed_tiles) / float(total_tiles) * 100) if total_tiles > 0 else 0])
	print("  Visible fog meshes: %d" % visible_fog)
	
	print("\nSettings:")
	print("  Reveal radius: %.1f tiles" % fog_system.get("reveal_radius"))
	print("  Fog height: %.2f units" % fog_system.get("fog_height"))
	print("  Update interval: %.2fs" % fog_system.get("update_interval"))
	print("  Map padding: %d tiles" % fog_system.get("map_padding"))
	
	if fog_system.map_generator:
		print("\nMap Generator: Found")
		print("  Instance ID: %d" % fog_system.map_generator.get_instance_id())
	else:
		print("\nMap Generator: Not found")
	
	print("=".repeat(50) + "\n")
