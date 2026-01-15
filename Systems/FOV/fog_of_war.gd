# fog_of_war.gd
extends Node3D
class_name FogOfWar

## Simple tile-based fog of war - tiles are revealed as you explore them

@export var player: CharacterBody3D
@export var map_container: Node3D
@export var fog_color: Color = Color(0, 0, 0, 1.0)  # Fully black
@export var tile_size: float = 1.0
@export var fog_height: float = 1.75  # Height of fog tiles to cover walls
@export var update_interval: float = 0.2
@export var reveal_radius: float = 35.0  # How far around player to reveal
@export var map_padding: int = 30  # Extra tiles around map border

var map_generator: GridMap
var revealed_tiles: Dictionary = {}  # Key: Vector2i(x,z), Value: bool
var fog_meshes: Dictionary = {}  # Key: Vector2i(x,z), Value: MeshInstance3D
var update_timer: float = 0.0
var fog_parent: Node3D
var last_map_instance_id: int = -1  # Track which map we created fog for
var is_passive_mode: bool = false  # Set when on passive maps
var debug_disabled: bool = false  # Debug: disable system

func _ready():
	if not player or not map_container:
		push_error("FogOfWar: Missing player or map_container!")
		return
	
	# Create parent node for all fog tiles
	fog_parent = Node3D.new()
	fog_parent.name = "FogTiles"
	add_child(fog_parent)
	
	find_map()
	
	if map_generator:
		create_fog_tiles()

func find_map():
	map_generator = find_gridmap_recursive(map_container)
	if map_generator:
		# Check if this is a passive map
		is_passive_mode = map_generator.get("is_passive_map")
		if is_passive_mode == null:
			is_passive_mode = false

func find_gridmap_recursive(node: Node) -> GridMap:
	if node is GridMap:
		return node
	for child in node.get_children():
		var result = find_gridmap_recursive(child)
		if result:
			return result
	return null

func create_fog_tiles():
	if not map_generator:
		return
	
	var used_cells = map_generator.get_used_cells()
	if used_cells.size() == 0:
		return
	
	# Find map bounds
	var min_x = INF
	var max_x = -INF
	var min_z = INF
	var max_z = -INF
	
	for cell in used_cells:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_z = min(min_z, cell.z)
		max_z = max(max_z, cell.z)
	
	# Expand bounds with padding
	min_x -= map_padding
	max_x += map_padding
	min_z -= map_padding
	max_z += map_padding
	
	var created_count = 0
	
	# Create fog quad for each tile in the expanded area
	for x in range(int(min_x), int(max_x) + 1):
		for z in range(int(min_z), int(max_z) + 1):
			var tile_key = Vector2i(x, z)
			
			# Skip if already created
			if fog_meshes.has(tile_key):
				continue
			
			# Create a small quad at this tile position
			var mesh_instance = MeshInstance3D.new()
			var quad_mesh = create_tile_quad()
			mesh_instance.mesh = quad_mesh
			
			# Position at tile center, at floor level
			var world_pos = map_generator.map_to_local(Vector3i(x, 0, z))
			mesh_instance.position = Vector3(world_pos.x, 0.0, world_pos.z)
			
			# Material
			var material = StandardMaterial3D.new()
			material.albedo_color = fog_color
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			material.disable_receive_shadows = true
			mesh_instance.material_override = material
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			
			fog_parent.add_child(mesh_instance)
			fog_meshes[tile_key] = mesh_instance
			revealed_tiles[tile_key] = false
			created_count += 1
	
	if is_passive_mode:
		# Wait a frame then reveal
		await get_tree().process_frame
		reveal_all()

func create_tile_quad() -> Mesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_size = tile_size / 2.0
	
	# Create vertical quad facing camera (covers from floor to fog_height)
	# We'll create 4 vertical faces (like a tall box without top/bottom)
	
	# Front face (facing +Z)
	var v1 = Vector3(-half_size, 0, half_size)
	var v2 = Vector3(half_size, 0, half_size)
	var v3 = Vector3(half_size, fog_height, half_size)
	var v4 = Vector3(-half_size, fog_height, half_size)
	
	surface_tool.add_vertex(v1)
	surface_tool.add_vertex(v2)
	surface_tool.add_vertex(v3)
	surface_tool.add_vertex(v1)
	surface_tool.add_vertex(v3)
	surface_tool.add_vertex(v4)
	
	# Back face (facing -Z)
	var v5 = Vector3(half_size, 0, -half_size)
	var v6 = Vector3(-half_size, 0, -half_size)
	var v7 = Vector3(-half_size, fog_height, -half_size)
	var v8 = Vector3(half_size, fog_height, -half_size)
	
	surface_tool.add_vertex(v5)
	surface_tool.add_vertex(v6)
	surface_tool.add_vertex(v7)
	surface_tool.add_vertex(v5)
	surface_tool.add_vertex(v7)
	surface_tool.add_vertex(v8)
	
	# Left face (facing -X)
	var v9 = Vector3(-half_size, 0, -half_size)
	var v10 = Vector3(-half_size, 0, half_size)
	var v11 = Vector3(-half_size, fog_height, half_size)
	var v12 = Vector3(-half_size, fog_height, -half_size)
	
	surface_tool.add_vertex(v9)
	surface_tool.add_vertex(v10)
	surface_tool.add_vertex(v11)
	surface_tool.add_vertex(v9)
	surface_tool.add_vertex(v11)
	surface_tool.add_vertex(v12)
	
	# Right face (facing +X)
	var v13 = Vector3(half_size, 0, half_size)
	var v14 = Vector3(half_size, 0, -half_size)
	var v15 = Vector3(half_size, fog_height, -half_size)
	var v16 = Vector3(half_size, fog_height, half_size)
	
	surface_tool.add_vertex(v13)
	surface_tool.add_vertex(v14)
	surface_tool.add_vertex(v15)
	surface_tool.add_vertex(v13)
	surface_tool.add_vertex(v15)
	surface_tool.add_vertex(v16)
	
	# Top face
	var t1 = Vector3(-half_size, fog_height, -half_size)
	var t2 = Vector3(half_size, fog_height, -half_size)
	var t3 = Vector3(half_size, fog_height, half_size)
	var t4 = Vector3(-half_size, fog_height, half_size)
	
	surface_tool.add_vertex(t1)
	surface_tool.add_vertex(t2)
	surface_tool.add_vertex(t3)
	surface_tool.add_vertex(t1)
	surface_tool.add_vertex(t3)
	surface_tool.add_vertex(t4)
	
	return surface_tool.commit()

func _process(delta):
	if not player:
		return
	
	# If system disabled, skip updates
	if debug_disabled:
		return
	
	# If no map generator, try to find it
	if not map_generator:
		find_map()
		if map_generator:
			var current_map_id = map_generator.get_instance_id()
			# Check if this is a different map than we had fog for
			if last_map_instance_id != -1 and last_map_instance_id != current_map_id:
				reset_fog()
			
			if fog_meshes.size() == 0:
				last_map_instance_id = current_map_id
				create_fog_tiles()
		return
	
	# Check if map was freed or changed
	if not is_instance_valid(map_generator):
		reset_fog()
		is_passive_mode = false  # Reset passive mode
		return
	
	# Check if the map instance changed
	var current_map_id = map_generator.get_instance_id()
	if last_map_instance_id != -1 and last_map_instance_id != current_map_id:
		reset_fog()
		is_passive_mode = false  # Reset passive mode
		last_map_instance_id = current_map_id
		find_map()  # Re-find map to update passive mode
		create_fog_tiles()
		return
	
	# If passive map, skip fog updates
	if is_passive_mode:
		return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		update_fog()

func reset_fog():
	"""Clear all fog tiles and revealed state"""
	# Free all fog meshes
	for mesh in fog_meshes.values():
		if is_instance_valid(mesh):
			mesh.queue_free()
	
	# Clear dictionaries
	fog_meshes.clear()
	revealed_tiles.clear()
	map_generator = null
	last_map_instance_id = -1

func update_fog():
	# Get player's grid position
	var player_grid = map_generator.local_to_map(player.global_position)
	
	# Reveal tiles within radius
	var reveal_tiles_count = int(reveal_radius)
	
	for x_offset in range(-reveal_tiles_count, reveal_tiles_count + 1):
		for z_offset in range(-reveal_tiles_count, reveal_tiles_count + 1):
			var check_pos = Vector3i(player_grid.x + x_offset, 0, player_grid.z + z_offset)
			var world_pos = map_generator.map_to_local(check_pos)
			var dist = Vector2(world_pos.x - player.global_position.x, world_pos.z - player.global_position.z).length()
			
			if dist <= reveal_radius:
				var tile_key = Vector2i(check_pos.x, check_pos.z)
				
				# Get tile_id
				var tile_id = map_generator.get_cell_item(check_pos)
				var tile_exists = false
				var is_wall = false
				
				if tile_id != -1:
					# Tile exists (wall or pre-processing floor)
					tile_exists = true
					is_wall = is_wall_tile(tile_id)
				else:
					# Tile is empty (-1) - check if it's a cleared floor or door
					if map_generator.has_method("is_position_walkable"):
						var is_walkable = map_generator.is_position_walkable(check_pos.x, check_pos.z)
						if is_walkable:
							# This is a cleared floor
							tile_exists = true
							is_wall = false
					
					# Check if it's a door position (treat as wall for discovery)
					if map_generator.has_method("has_door_at_position"):
						if map_generator.has_door_at_position(check_pos.x, check_pos.z):
							tile_exists = true
							is_wall = true  # Treat doors like walls for discovery
				
				if not tile_exists:
					# No tile here, don't reveal
					continue
				
				# Check line of sight
				var can_reveal = false
				if is_wall:
					can_reveal = has_line_of_sight_to_wall(player.global_position, world_pos)
				else:
					can_reveal = has_line_of_sight(player.global_position, world_pos)
				
				# Mark as explored if we can see it
				if can_reveal:
					revealed_tiles[tile_key] = true
				
				# Update fog visibility
				# Fog is hidden only if: 1) explored AND 2) currently visible
				if fog_meshes.has(tile_key):
					var is_explored = revealed_tiles.get(tile_key, false)
					if is_explored:
						# Tile is explored - keep fog hidden permanently
						fog_meshes[tile_key].visible = false
					else:
						# Not explored yet - show fog
						fog_meshes[tile_key].visible = true

func has_line_of_sight_to_wall(from: Vector3, to: Vector3) -> bool:
	"""Check if we can see a wall tile - stops at the wall itself, not blocked by it"""
	var from_2d = Vector2(from.x, from.z)
	var to_2d = Vector2(to.x, to.z)
	var direction = (to_2d - from_2d).normalized()
	var distance = from_2d.distance_to(to_2d)
	
	# Step along the line, but stop BEFORE the target wall
	var step_size = 0.5
	var current_dist = step_size
	
	while current_dist < distance - 0.5:  # Stop before reaching the target
		var check_pos_2d = from_2d + direction * current_dist
		var check_pos_3d = Vector3(check_pos_2d.x, 0, check_pos_2d.y)
		var check_grid = map_generator.local_to_map(check_pos_3d)
		var check_tile_id = map_generator.get_cell_item(check_grid)
		
		# Check if this position has a door FIRST (before walkable check)
		if check_tile_id == -1 and map_generator.has_method("has_door_at_position"):
			if map_generator.has_door_at_position(check_grid.x, check_grid.z):
				# Door position - check if door scene instance is open
				if is_door_open_at_position(check_pos_3d):
					# Door is open - don't block
					current_dist += step_size
					continue
				else:
					# Door is closed - blocks vision
					return false
		
		# Check if this is a cleared floor (walkable)
		if check_tile_id == -1 and map_generator.has_method("is_position_walkable"):
			if map_generator.is_position_walkable(check_grid.x, check_grid.z):
				# Cleared floor - doesn't block vision
				current_dist += step_size
				continue
		
		# Check if blocked by a wall along the way
		if is_wall_tile(check_tile_id):
			return false
		
		current_dist += step_size
	
	return true

func has_line_of_sight(from: Vector3, to: Vector3) -> bool:
	"""Check if there's a clear line of sight between two positions"""
	var from_2d = Vector2(from.x, from.z)
	var to_2d = Vector2(to.x, to.z)
	var direction = (to_2d - from_2d).normalized()
	var distance = from_2d.distance_to(to_2d)
	
	# Step along the line
	var step_size = 0.25  # Smaller steps to avoid missing cells
	var current_dist = step_size
	
	while current_dist < distance:
		var check_pos_2d = from_2d + direction * current_dist
		var check_pos_3d = Vector3(check_pos_2d.x, 0, check_pos_2d.y)
		var check_grid = map_generator.local_to_map(check_pos_3d)
		var check_tile_id = map_generator.get_cell_item(check_grid)
		
		# Check if this position has a door FIRST (before walkable check)
		if check_tile_id == -1 and map_generator.has_method("has_door_at_position"):
			var has_door = map_generator.has_door_at_position(check_grid.x, check_grid.z)
			if has_door:
				# Door position - check if door scene instance is open
				var door_open = is_door_open_at_position(check_pos_3d)
				if door_open:
					# Door is open - don't block
					current_dist += step_size
					continue
				else:
					# Door is closed - blocks vision
					return false
		
		# Check if this is a cleared floor (walkable)
		if check_tile_id == -1 and map_generator.has_method("is_position_walkable"):
			if map_generator.is_position_walkable(check_grid.x, check_grid.z):
				# Cleared floor - doesn't block vision
				current_dist += step_size
				continue
		
		# Check if this is a wall
		if is_wall_tile(check_tile_id):
			return false
		
		current_dist += step_size
	
	return true

func is_door_open_at_position(world_pos: Vector3) -> bool:
	"""Check if there's an open door at the given world position"""
	# Get all doors in the scene
	var doors = get_tree().get_nodes_in_group("door")
	
	# Check if any door is close to this position and is open
	for door in doors:
		if door is Door:  # Make sure it's actually a Door
			var door_pos = door.global_position
			var distance = Vector2(world_pos.x - door_pos.x, world_pos.z - door_pos.z).length()
			
			# If door is within 1 unit and is open (collision disabled)
			if distance < 1.0 and door.is_open:
				return true
	
	return false

func is_wall_tile(tile_id: int) -> bool:
	"""Check if a tile is a wall"""
	if tile_id == -1:
		return true  # Empty = wall
	
	# Get tile IDs from map
	var exterior_wall_id = map_generator.get("exterior_wall_tile_id")
	var interior_wall_id = map_generator.get("interior_wall_tile_id") 
	var entrance_id = map_generator.get("entrance_tile_id")
	var exit_id = map_generator.get("exit_tile_id")
	
	# Get wall connector to check for all wall variations
	var wall_connector = map_generator.get("interior_wall_connector")
	
	# Explicit wall check
	if exterior_wall_id != null and tile_id == exterior_wall_id:
		return true
	if interior_wall_id != null and tile_id == interior_wall_id:
		return true
	
	# Check if it's any of the wall variations
	if wall_connector:
		if tile_id == wall_connector.o_tile_id: return true
		if tile_id == wall_connector.u_tile_id: return true
		if tile_id == wall_connector.i_tile_id: return true
		if tile_id == wall_connector.l_none_tile_id: return true
		if tile_id == wall_connector.l_single_tile_id: return true
		if tile_id == wall_connector.t_none_tile_id: return true
		if tile_id == wall_connector.t_single_right_tile_id: return true
		if tile_id == wall_connector.t_single_left_tile_id: return true
		if tile_id == wall_connector.t_double_tile_id: return true
		if tile_id == wall_connector.x_none_tile_id: return true
		if tile_id == wall_connector.x_single_tile_id: return true
		if tile_id == wall_connector.x_side_tile_id: return true
		if tile_id == wall_connector.x_opposite_tile_id: return true
		if tile_id == wall_connector.x_triple_tile_id: return true
		if tile_id == wall_connector.x_quad_tile_id: return true
	
	# Entrance/exit are walkable
	if entrance_id != null and tile_id == entrance_id:
		return false
	if exit_id != null and tile_id == exit_id:
		return false
	
	# If not explicitly a wall, assume it's walkable
	return false

## DEBUG FUNCTIONS

func reveal_all():
	"""Reveal entire map - only tiles with actual geometry (comma key)"""
	if not map_generator:
		return
	
	for tile_key in revealed_tiles.keys():
		if not revealed_tiles[tile_key]:
			# Check if this tile has actual map geometry
			var check_pos = Vector3i(tile_key.x, 0, tile_key.y)
			
			# Check using floor type map if available
			var has_tile = false
			if map_generator.has_method("is_position_walkable"):
				has_tile = map_generator.is_position_walkable(check_pos.x, check_pos.z)
			
			# Fallback to direct tile check
			if not has_tile:
				var tile_id = map_generator.get_cell_item(check_pos)
				has_tile = (tile_id != -1)
			
			# Only reveal if tile exists
			if has_tile:
				revealed_tiles[tile_key] = true
				if fog_meshes.has(tile_key):
					fog_meshes[tile_key].visible = false

func debug_reset_fog():
	"""Debug: Reset all explored areas (period key)"""
	if not map_generator:
		return
	
	for tile_key in revealed_tiles.keys():
		if revealed_tiles[tile_key]:
			revealed_tiles[tile_key] = false
			if fog_meshes.has(tile_key):
				fog_meshes[tile_key].visible = true

func debug_toggle_system():
	"""Debug: Toggle system on/off (slash key)"""
	debug_disabled = not debug_disabled
	
	if debug_disabled:
		# When disabling, hide all fog meshes
		for mesh in fog_meshes.values():
			if is_instance_valid(mesh):
				mesh.visible = false
	else:
		# When re-enabling, restore fog based on revealed state
		for tile_key in fog_meshes.keys():
			if is_instance_valid(fog_meshes[tile_key]):
				# Show fog if NOT revealed, hide if revealed
				var is_revealed = revealed_tiles.get(tile_key, false)
				fog_meshes[tile_key].visible = not is_revealed
