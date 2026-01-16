# fog_of_war_multimesh.gd
extends Node3D
class_name FogOfWarMultiMesh

## High-performance fog of war using MultiMeshInstance3D
## Same visual result as original, 10-50x faster

@export var player: CharacterBody3D
@export var map_container: Node3D
@export var fog_color: Color = Color(0, 0, 0, 1.0)
@export var fog_height: float = 1.75
@export var update_interval: float = 0.2
@export var reveal_radius: float = 30.0
@export var map_padding: int = 10  # Reduced from 30

var map_generator: GridMap
var multimesh_instance: MultiMeshInstance3D
var tile_positions: Array = []  # World positions of each fog tile
var tile_keys: Dictionary = {}  # Vector2i -> index in multimesh
var revealed_tiles: Dictionary = {}  # Vector2i -> bool
var update_timer: float = 0.0
var is_passive_mode: bool = false
var last_map_instance_id: int = -1

# Box mesh for fog tiles (created once, reused)
var box_mesh: ArrayMesh

func _ready():
	if not player or not map_container:
		push_error("FogOfWar: Missing player or map_container!")
		return
	
	# Connect to detect when map is added
	if not map_container.child_entered_tree.is_connected(_on_map_container_child_added):
		map_container.child_entered_tree.connect(_on_map_container_child_added)
	
	find_map()
	if map_generator:
		create_fog_tiles()

func _on_map_container_child_added(_node: Node):
	if not map_generator:
		find_map()
		if map_generator:
			create_fog_tiles()

func find_map():
	map_generator = find_gridmap_recursive(map_container)
	if map_generator:
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

func create_box_mesh() -> ArrayMesh:
	"""Create a 0.5x0.5 box mesh for fog quadrants"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 0.5x0.5 tile = 0.25 half-size
	var half_size = 0.25
	
	# Front face (+Z)
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
	
	# Back face (-Z)
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
	
	# Left face (-X)
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
	
	# Right face (+X)
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
	
	# Expand with padding
	min_x -= map_padding
	max_x += map_padding
	min_z -= map_padding
	max_z += map_padding
	
	# Build list of tile positions
	tile_positions.clear()
	tile_keys.clear()
	revealed_tiles.clear()
	
	var index = 0
	for x in range(int(min_x), int(max_x) + 1):
		for z in range(int(min_z), int(max_z) + 1):
			# Create 4 fog quadrants per tile (0.5x0.5 each)
			# This gives us finer control, especially for thin building walls
			for sub_x in range(2):
				for sub_z in range(2):
					var world_pos = map_generator.map_to_local(Vector3i(x, 0, z))
					# Offset to create quadrants: -0.25, +0.25 from center
					var offset_x = (sub_x - 0.5) * 0.5
					var offset_z = (sub_z - 0.5) * 0.5
					var sub_pos = Vector3(world_pos.x + offset_x, world_pos.y, world_pos.z + offset_z)
					
					tile_positions.append(sub_pos)
					# Use sub-key to track quadrants: tile coords * 2 + quadrant
					var sub_key = Vector2i(x * 2 + sub_x, z * 2 + sub_z)
					tile_keys[sub_key] = index
					revealed_tiles[sub_key] = false
					index += 1
	
	# Create box mesh
	box_mesh = create_box_mesh()
	
	# Create MultiMesh
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = tile_positions.size()
	multimesh.mesh = box_mesh
	
	# Set transforms for all instances
	for i in range(tile_positions.size()):
		var pos = tile_positions[i]
		var transform = Transform3D(Basis(), pos)
		multimesh.set_instance_transform(i, transform)
	
	# Create MultiMeshInstance3D
	multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.multimesh = multimesh
	
	# Material
	var material = StandardMaterial3D.new()
	material.albedo_color = fog_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_receive_shadows = true
	multimesh_instance.material_override = material
	multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	add_child(multimesh_instance)
	
	last_map_instance_id = map_generator.get_instance_id()
	
	print("FogOfWar: MultiMesh created successfully")
	
	last_map_instance_id = map_generator.get_instance_id()
	
	# On passive maps: reveal all tiles that have actual map geometry
	if is_passive_mode:
		reveal_map_tiles()

func _process(delta):
	if not player:
		return
	
	# Check if map changed
	if not map_generator or not is_instance_valid(map_generator):
		reset_fog()
		find_map()
		if map_generator:
			create_fog_tiles()
		return
	
	var current_map_id = map_generator.get_instance_id()
	if last_map_instance_id != -1 and last_map_instance_id != current_map_id:
		reset_fog()
		last_map_instance_id = current_map_id
		find_map()
		create_fog_tiles()
		return
	
	if is_passive_mode:
		return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		update_fog()

func reset_fog():
	if multimesh_instance:
		multimesh_instance.queue_free()
		multimesh_instance = null
	
	tile_positions.clear()
	tile_keys.clear()
	revealed_tiles.clear()
	map_generator = null
	last_map_instance_id = -1
	is_passive_mode = false

func update_fog():
	if not map_generator or not multimesh_instance:
		return
	
	var player_grid = map_generator.local_to_map(player.global_position)
	var reveal_tiles = int(reveal_radius)
	var tiles_revealed = 0
	
	for x_offset in range(-reveal_tiles, reveal_tiles + 1):
		for z_offset in range(-reveal_tiles, reveal_tiles + 1):
			var check_pos = Vector3i(player_grid.x + x_offset, 0, player_grid.z + z_offset)
			var tile_id = map_generator.get_cell_item(check_pos)
			
			# Check if this is a non-walkable tile (wall)
			var is_walkable = false
			if tile_id == -1 and map_generator.has_method("is_position_walkable"):
				is_walkable = map_generator.is_position_walkable(check_pos.x, check_pos.z)
			
			var is_non_walkable_wall = (tile_id != -1 and not is_walkable)
			
			# Check each quadrant of this tile individually
			for sub_x in range(2):
				for sub_z in range(2):
					var sub_key = Vector2i(check_pos.x * 2 + sub_x, check_pos.z * 2 + sub_z)
					
					# Skip if already revealed or not in our multimesh
					if not tile_keys.has(sub_key):
						continue
					if revealed_tiles.get(sub_key, false):
						continue
					
					# Get world position of THIS QUADRANT (not tile center)
					var tile_world = map_generator.map_to_local(check_pos)
					var offset_x = (sub_x - 0.5) * 0.5
					var offset_z = (sub_z - 0.5) * 0.5
					var quadrant_world = Vector3(tile_world.x + offset_x, tile_world.y, tile_world.z + offset_z)
					
					# Check distance to THIS QUADRANT
					var dist = Vector2(quadrant_world.x - player.global_position.x, 
									   quadrant_world.z - player.global_position.z).length()
					
					if dist > reveal_radius:
						continue
					
					# For non-walkable tiles only: only reveal quadrants on player-facing side
					if is_non_walkable_wall:
						# Get direction from tile center to player
						var to_player = Vector2(player.global_position.x - tile_world.x, 
												player.global_position.z - tile_world.z).normalized()
						
						# Get direction from tile center to this quadrant
						var to_quadrant = Vector2(offset_x, offset_z).normalized()
						
						# Check if quadrant is on same side as player (dot product > 0)
						var dot = to_player.dot(to_quadrant)
						
						# If dot product is negative or near zero, quadrant is on far side
						if dot <= 0.1:
							continue
					
					# Check line of sight to THIS QUADRANT
					if not should_reveal_tile(check_pos, quadrant_world):
						continue
					
					# Hide this quadrant
					var instance_index = tile_keys[sub_key]
					var current_transform = multimesh_instance.multimesh.get_instance_transform(instance_index)
					current_transform = current_transform.scaled(Vector3(0.001, 0.001, 0.001))
					multimesh_instance.multimesh.set_instance_transform(instance_index, current_transform)
					
					revealed_tiles[sub_key] = true
					tiles_revealed += 1

func should_reveal_tile(check_pos: Vector3i, world_pos: Vector3) -> bool:
	var tile_id = map_generator.get_cell_item(check_pos)
	var tile_exists = false
	var is_wall = false
	
	if tile_id != -1:
		tile_exists = true
		is_wall = is_wall_tile(tile_id)
	else:
		if map_generator.has_method("is_position_walkable"):
			if map_generator.is_position_walkable(check_pos.x, check_pos.z):
				tile_exists = true
				is_wall = false
		
		if map_generator.has_method("has_door_at_position"):
			if map_generator.has_door_at_position(check_pos.x, check_pos.z):
				tile_exists = true
				is_wall = true
	
	if not tile_exists:
		return false
	
	if is_wall:
		return has_line_of_sight_to_wall(player.global_position, world_pos)
	else:
		return has_line_of_sight(player.global_position, world_pos)

func has_line_of_sight_to_wall(from: Vector3, to: Vector3) -> bool:
	var from_2d = Vector2(from.x, from.z)
	var to_2d = Vector2(to.x, to.z)
	var direction = (to_2d - from_2d).normalized()
	var distance = from_2d.distance_to(to_2d)
	var step_size = 0.5
	var current_dist = step_size
	
	while current_dist < distance - 0.5:
		var check_pos_2d = from_2d + direction * current_dist
		var check_pos_3d = Vector3(check_pos_2d.x, 0, check_pos_2d.y)
		var check_grid = map_generator.local_to_map(check_pos_3d)
		var check_tile_id = map_generator.get_cell_item(check_grid)
		
		if check_tile_id == -1 and map_generator.has_method("has_door_at_position"):
			if map_generator.has_door_at_position(check_grid.x, check_grid.z):
				if not is_door_open_at_position(check_pos_3d):
					return false
		
		if check_tile_id == -1 and map_generator.has_method("is_position_walkable"):
			if map_generator.is_position_walkable(check_grid.x, check_grid.z):
				current_dist += step_size
				continue
		
		if is_wall_tile(check_tile_id):
			return false
		
		current_dist += step_size
	
	return true

func has_line_of_sight(from: Vector3, to: Vector3) -> bool:
	var from_2d = Vector2(from.x, from.z)
	var to_2d = Vector2(to.x, to.z)
	var direction = (to_2d - from_2d).normalized()
	var distance = from_2d.distance_to(to_2d)
	var step_size = 0.5
	var current_dist = step_size
	
	while current_dist < distance:
		var check_pos_2d = from_2d + direction * current_dist
		var check_pos_3d = Vector3(check_pos_2d.x, 0, check_pos_2d.y)
		var check_grid = map_generator.local_to_map(check_pos_3d)
		var check_tile_id = map_generator.get_cell_item(check_grid)
		
		if check_tile_id == -1 and map_generator.has_method("has_door_at_position"):
			if map_generator.has_door_at_position(check_grid.x, check_grid.z):
				if not is_door_open_at_position(check_pos_3d):
					return false
		
		if check_tile_id == -1 and map_generator.has_method("is_position_walkable"):
			if map_generator.is_position_walkable(check_grid.x, check_grid.z):
				current_dist += step_size
				continue
		
		if is_wall_tile(check_tile_id):
			return false
		
		current_dist += step_size
	
	return true

func is_door_open_at_position(world_pos: Vector3) -> bool:
	var doors = get_tree().get_nodes_in_group("door")
	for door in doors:
		if door.has_method("get") and door.get("is_open"):
			var door_pos = door.global_position
			var distance = Vector2(world_pos.x - door_pos.x, world_pos.z - door_pos.z).length()
			if distance < 1.0 and door.is_open:
				return true
	return false

func is_building_wall_tile(tile_id: int) -> bool:
	"""Check if a tile is a building interior wall"""
	if tile_id == -1:
		return false
	
	var interior_wall_id = map_generator.get("interior_wall_tile_id")
	if interior_wall_id != null and tile_id == interior_wall_id:
		return true
	
	# Also check wall connector tiles
	var wall_connector = map_generator.get("interior_wall_connector")
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
	
	return false

func is_wall_tile(tile_id: int) -> bool:
	if tile_id == -1:
		return true
	
	var exterior_wall_id = map_generator.get("exterior_wall_tile_id")
	var interior_wall_id = map_generator.get("interior_wall_tile_id")
	var entrance_id = map_generator.get("entrance_tile_id")
	var exit_id = map_generator.get("exit_tile_id")
	var wall_connector = map_generator.get("interior_wall_connector")
	
	if exterior_wall_id != null and tile_id == exterior_wall_id:
		return true
	if interior_wall_id != null and tile_id == interior_wall_id:
		return true
	
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
	
	if entrance_id != null and tile_id == entrance_id:
		return false
	if exit_id != null and tile_id == exit_id:
		return false
	
	return false

func reveal_map_tiles():
	"""Reveal only tiles that have actual map geometry (for passive maps)"""
	if not multimesh_instance or not map_generator:
		return
	
	var tiles_revealed = 0
	
	# Iterate through all tile keys (which are now quadrant keys)
	for sub_key in tile_keys.keys():
		# Convert quadrant key back to tile coords
		var tile_x = int(sub_key.x / 2)
		var tile_z = int(sub_key.y / 2)
		var check_pos = Vector3i(tile_x, 0, tile_z)
		var tile_id = map_generator.get_cell_item(check_pos)
		
		# Check if this tile has actual geometry
		var has_tile = false
		if tile_id != -1:
			has_tile = true
		else:
			# Check if it's a walkable floor
			if map_generator.has_method("is_position_walkable"):
				has_tile = map_generator.is_position_walkable(check_pos.x, check_pos.z)
		
		# Only reveal if tile exists
		if has_tile:
			var instance_index = tile_keys[sub_key]
			var current_transform = multimesh_instance.multimesh.get_instance_transform(instance_index)
			current_transform = current_transform.scaled(Vector3(0.001, 0.001, 0.001))
			multimesh_instance.multimesh.set_instance_transform(instance_index, current_transform)
			revealed_tiles[sub_key] = true
			tiles_revealed += 1

func reveal_all():
	"""Reveal everything (debug/fallback)"""
	if not multimesh_instance:
		return
	
	for i in range(tile_positions.size()):
		var current_transform = multimesh_instance.multimesh.get_instance_transform(i)
		current_transform = current_transform.scaled(Vector3(0.001, 0.001, 0.001))
		multimesh_instance.multimesh.set_instance_transform(i, current_transform)
	
	for key in revealed_tiles.keys():
		revealed_tiles[key] = true
