# fog_of_war_simple.gd
extends Node3D
class_name FogOfWarSimple

## Simple fog of war - single mesh per tile, only exterior walls block LOS

@export var player: CharacterBody3D
@export var map_container: Node3D
@export var fog_color: Color = Color(0, 0, 0, 1.0)
@export var fog_height: float = 1.75
@export var update_interval: float = 0.2
@export var reveal_radius: float = 50.0
@export var map_padding: int = 50

var map_generator: GridMap
var multimesh_instance: MultiMeshInstance3D
var tile_positions: Array = []  # World positions of each fog tile
var tile_keys: Dictionary = {}  # Vector2i -> index in multimesh
var revealed_tiles: Dictionary = {}  # Vector2i -> bool
var update_timer: float = 0.0
var is_passive_mode: bool = false
var last_map_instance_id: int = -1
var box_mesh: ArrayMesh
var last_player_position: Vector3 = Vector3.ZERO
var movement_threshold: float = 0.5  # Only update fog when player moves this far
var debug_disabled: bool = false  # For debug toggle

func _ready():
	if not player or not map_container:
		push_error("FogOfWar: Missing player or map_container!")
		return
	
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
	"""Create a 1x1 box mesh for fog tiles"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_size = 0.5
	
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
	
	# Build list of tile positions - ONE per tile
	tile_positions.clear()
	tile_keys.clear()
	revealed_tiles.clear()
	
	var index = 0
	for x in range(int(min_x), int(max_x) + 1):
		for z in range(int(min_z), int(max_z) + 1):
			var world_pos = map_generator.map_to_local(Vector3i(x, 0, z))
			tile_positions.append(world_pos)
			var key = Vector2i(x, z)
			tile_keys[key] = index
			revealed_tiles[key] = false
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
	
	# Initialize last player position
	if player:
		last_player_position = player.global_position
	
	print("FogOfWar: Created ", tile_positions.size(), " fog tiles")
	
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
	
	if is_passive_mode or debug_disabled:
		return
	
	# Check if player has moved enough to warrant an update
	var player_moved_distance = player.global_position.distance_to(last_player_position)
	
	update_timer += delta
	if update_timer >= update_interval and player_moved_distance >= movement_threshold:
		update_timer = 0.0
		last_player_position = player.global_position
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
	var radius_squared = reveal_radius * reveal_radius  # Avoid sqrt
	var player_pos_2d = Vector2(player.global_position.x, player.global_position.z)
	
	for x_offset in range(-reveal_tiles, reveal_tiles + 1):
		for z_offset in range(-reveal_tiles, reveal_tiles + 1):
			var check_pos = Vector3i(player_grid.x + x_offset, 0, player_grid.z + z_offset)
			var key = Vector2i(check_pos.x, check_pos.z)
			
			# Skip if not in our multimesh
			if not tile_keys.has(key):
				continue
			
			# Skip if already revealed (most common case - check first)
			if revealed_tiles.get(key, false):
				continue
			
			# Get world position of this tile
			var tile_world = map_generator.map_to_local(check_pos)
			var tile_pos_2d = Vector2(tile_world.x, tile_world.z)
			
			# Check distance with squared distance (faster - no sqrt)
			var dist_squared = player_pos_2d.distance_squared_to(tile_pos_2d)
			
			if dist_squared > radius_squared:
				continue
			
			# Check if this is a door tile
			var is_door = false
			if map_generator.has_method("has_door_at_position"):
				is_door = map_generator.has_door_at_position(check_pos.x, check_pos.z)
			
			# Reveal if: door (always) or has LOS
			if is_door or has_line_of_sight(player.global_position, tile_world):
				# Hide this tile
				var instance_index = tile_keys[key]
				var current_transform = multimesh_instance.multimesh.get_instance_transform(instance_index)
				current_transform = current_transform.scaled(Vector3(0.001, 0.001, 0.001))
				multimesh_instance.multimesh.set_instance_transform(instance_index, current_transform)
				revealed_tiles[key] = true

func has_line_of_sight(from: Vector3, to: Vector3) -> bool:
	var from_2d = Vector2(from.x, from.z)
	var to_2d = Vector2(to.x, to.z)
	var direction = (to_2d - from_2d).normalized()
	var distance = from_2d.distance_to(to_2d)
	var step_size = 0.75  # Larger steps = fewer checks, better performance
	var current_dist = step_size
	
	while current_dist < distance - 0.5:
		var check_pos_2d = from_2d + direction * current_dist
		var check_pos_3d = Vector3(check_pos_2d.x, 0, check_pos_2d.y)
		var check_grid = map_generator.local_to_map(check_pos_3d)
		var check_tile_id = map_generator.get_cell_item(check_grid)
		
		# Only exterior walls block line of sight (doors no longer block)
		var exterior_wall_id = map_generator.get("exterior_wall_tile_id")
		if exterior_wall_id != null and check_tile_id == exterior_wall_id:
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

func reveal_map_tiles():
	"""Reveal only tiles that have actual map geometry (for passive maps)"""
	if not multimesh_instance or not map_generator:
		return
	
	for key in tile_keys.keys():
		var check_pos = Vector3i(key.x, 0, key.y)
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
			var instance_index = tile_keys[key]
			var current_transform = multimesh_instance.multimesh.get_instance_transform(instance_index)
			current_transform = current_transform.scaled(Vector3(0.001, 0.001, 0.001))
			multimesh_instance.multimesh.set_instance_transform(instance_index, current_transform)
			revealed_tiles[key] = true

func reveal_all():
	"""Reveal everything (debug/fallback)"""
	if not multimesh_instance or not map_generator:
		return
	
	for key in tile_keys.keys():
		var check_pos = Vector3i(key.x, 0, key.y)
		var tile_id = map_generator.get_cell_item(check_pos)
		
		# Check if this tile has actual geometry
		var has_tile = false
		if tile_id != -1:
			has_tile = true
		else:
			# Check if it's a walkable floor or door
			if map_generator.has_method("is_position_walkable"):
				has_tile = map_generator.is_position_walkable(check_pos.x, check_pos.z)
			if not has_tile and map_generator.has_method("has_door_at_position"):
				has_tile = map_generator.has_door_at_position(check_pos.x, check_pos.z)
		
		# Only reveal if tile exists
		if has_tile:
			var instance_index = tile_keys[key]
			var current_transform = multimesh_instance.multimesh.get_instance_transform(instance_index)
			current_transform = current_transform.scaled(Vector3(0.001, 0.001, 0.001))
			multimesh_instance.multimesh.set_instance_transform(instance_index, current_transform)
			revealed_tiles[key] = true

func debug_reset_fog():
	"""Reset all fog tiles to hidden (debug)"""
	if not multimesh_instance:
		return
	
	for i in range(tile_positions.size()):
		var pos = tile_positions[i]
		var transform = Transform3D(Basis(), pos)
		multimesh_instance.multimesh.set_instance_transform(i, transform)
	
	for key in revealed_tiles.keys():
		revealed_tiles[key] = false
	
	# Force immediate update to reveal area around player
	if player:
		last_player_position = player.global_position
		update_fog()

func debug_toggle_system():
	"""Toggle fog system on/off (debug)"""
	debug_disabled = not debug_disabled
	
	if debug_disabled:
		# Hide the multimesh when disabled
		if multimesh_instance:
			multimesh_instance.visible = false
	else:
		# Show the multimesh when enabled
		if multimesh_instance:
			multimesh_instance.visible = true
