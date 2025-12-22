extends Node
class_name DualGridFloor

## Dual Grid Floor Tile System
## This system uses a second gridmap offset by (0.5, 0, 0.5) to create seamless
## floor transitions by analyzing 4 overlapping tiles from the primary gridmap.

# References to the two gridmaps
var primary_grid: GridMap
var floor_grid: GridMap

# Tile type to check for in the primary grid (the simple floor tile ID)
var simple_floor_tile_id: int = -1

# Dictionary to store tile IDs for different floor types and shapes
# Structure: { "floor_type": { "whole": id, "half": id, "threequarter": id, "quarter": id } }
var floor_tile_sets: Dictionary = {}

# Y level to process (usually 0 for floors)
var floor_y_level: int = 0


func _init(p_primary_grid: GridMap, p_floor_grid: GridMap):
	primary_grid = p_primary_grid
	floor_grid = p_floor_grid


## Register a floor type with its mesh tile IDs
## floor_type: string identifier (e.g., "grass", "road", "water", "floor")
## tile_ids: Dictionary with keys: "whole", "half", "threequarter", "quarter"
func register_floor_type(floor_type: String, tile_ids: Dictionary) -> void:
	floor_tile_sets[floor_type] = tile_ids


## Set which tile ID in the primary grid represents a simple floor tile
func set_simple_floor_tile(tile_id: int) -> void:
	simple_floor_tile_id = tile_id


## Main processing function - call this after primary map generation is complete
func process_dual_grid_floors() -> void:
	# Get bounds of the primary gridmap
	var used_cells = primary_grid.get_used_cells()
	if used_cells.is_empty():
		return
	
	var min_pos = used_cells[0]
	var max_pos = used_cells[0]
	
	for cell in used_cells:
		min_pos.x = min(min_pos.x, cell.x)
		min_pos.z = min(min_pos.z, cell.z)
		max_pos.x = max(max_pos.x, cell.x)
		max_pos.z = max(max_pos.z, cell.z)
	
	# Process each potential dual-grid position
	# We need to check positions that would overlap 4 tiles from the primary grid
	for x in range(min_pos.x, max_pos.x + 1):
		for z in range(min_pos.z, max_pos.z + 1):
			_process_dual_grid_cell(x, z)


## Process a single dual-grid cell position
func _process_dual_grid_cell(x: int, z: int) -> void:
	# Get the 4 overlapping tiles from primary grid
	# In dual-grid, a cell at (x, z) overlaps primary cells:
	# (x, z), (x+1, z), (x, z+1), (x+1, z+1)
	var tiles = [
		_get_floor_type_at(x, z),       # Top-left
		_get_floor_type_at(x + 1, z),   # Top-right
		_get_floor_type_at(x, z + 1),   # Bottom-left
		_get_floor_type_at(x + 1, z + 1) # Bottom-right
	]
	
	# If all tiles are empty, skip this dual-grid cell
	if tiles[0] == "" and tiles[1] == "" and tiles[2] == "" and tiles[3] == "":
		return
	
	# Group tiles by type and position
	var tile_groups = _analyze_tile_quadrants(tiles)
	
	# Place the appropriate meshes for each tile type found
	for tile_type in tile_groups.keys():
		var quadrants = tile_groups[tile_type]
		_place_floor_meshes(x, z, tile_type, quadrants)
	
	# Remove simple floor tiles from primary grid that we've processed
	_remove_simple_floors_if_needed(x, z, tiles)


## Get the floor type at a specific position in the primary grid
func _get_floor_type_at(x: int, z: int) -> String:
	var cell_item = primary_grid.get_cell_item(Vector3i(x, floor_y_level, z))
	
	if cell_item == GridMap.INVALID_CELL_ITEM:
		return ""
	
	# Check if this is a simple floor tile or another registered type
	# You'll need to expand this based on how you identify different floor types
	# For now, we'll use a simple approach where you map tile IDs to types
	return _get_tile_type_from_id(cell_item)


## Map a tile ID to a floor type string
## You should customize this based on your tile ID system
func _get_tile_type_from_id(tile_id: int) -> String:
	# Example implementation - customize based on your tile IDs
	# You might want to use a dictionary to map IDs to types
	if tile_id == simple_floor_tile_id:
		return "floor"
	
	# Add more mappings as needed for other types
	# For example:
	# if tile_id == grass_tile_id:
	#     return "grass"
	# if tile_id == road_tile_id:
	#     return "road"
	
	return ""


## Analyze which quadrants belong to each tile type
## Returns: { "tile_type": [array of quadrant indices 0-3] }
func _analyze_tile_quadrants(tiles: Array) -> Dictionary:
	var groups = {}
	
	for i in range(4):
		var tile_type = tiles[i]
		if tile_type != "":
			if not groups.has(tile_type):
				groups[tile_type] = []
			groups[tile_type].append(i)
	
	return groups


## Place the appropriate floor meshes based on quadrant configuration
func _place_floor_meshes(grid_x: int, grid_z: int, tile_type: String, quadrants: Array) -> void:
	if not floor_tile_sets.has(tile_type):
		push_warning("Floor type '%s' not registered!" % tile_type)
		return
	
	var tile_set = floor_tile_sets[tile_type]
	var quad_count = quadrants.size()
	
	match quad_count:
		4:
			# All 4 quadrants - use whole tile
			_place_tile(grid_x, grid_z, tile_set["whole"], 0)
		
		3:
			# 3 quadrants - use threequarter tile + quarter tile
			_place_threequarter_and_quarter(grid_x, grid_z, tile_type, quadrants, tile_set)
		
		2:
			# 2 quadrants - check if adjacent or diagonal
			if _are_quadrants_adjacent(quadrants):
				_place_half_tile(grid_x, grid_z, quadrants, tile_set)
			else:
				# Diagonal - use 2 quarter tiles
				for quad in quadrants:
					_place_quarter_tile(grid_x, grid_z, quad, tile_set)
		
		1:
			# Single quadrant - use quarter tile
			_place_quarter_tile(grid_x, grid_z, quadrants[0], tile_set)


## Check if two quadrants are adjacent
func _are_quadrants_adjacent(quadrants: Array) -> bool:
	if quadrants.size() != 2:
		return false
	
	var q1 = quadrants[0]
	var q2 = quadrants[1]
	
	# Quadrant layout:
	# 0 1
	# 2 3
	
	# Check for horizontal adjacency
	if (q1 == 0 and q2 == 1) or (q1 == 1 and q2 == 0):
		return true
	if (q1 == 2 and q2 == 3) or (q1 == 3 and q2 == 2):
		return true
	
	# Check for vertical adjacency
	if (q1 == 0 and q2 == 2) or (q1 == 2 and q2 == 0):
		return true
	if (q1 == 1 and q2 == 3) or (q1 == 3 and q2 == 1):
		return true
	
	return false


## Place a whole tile
func _place_tile(grid_x: int, grid_z: int, tile_id: int, rotation: int) -> void:
	floor_grid.set_cell_item(Vector3i(grid_x, floor_y_level, grid_z), tile_id, rotation)


## Place a half tile with appropriate rotation
func _place_half_tile(grid_x: int, grid_z: int, quadrants: Array, tile_set: Dictionary) -> void:
	var rotation = _get_half_tile_rotation(quadrants)
	_place_tile(grid_x, grid_z, tile_set["half"], rotation)


## Get rotation for half tile based on which quadrants it covers
func _get_half_tile_rotation(quadrants: Array) -> int:
	var q1 = quadrants[0]
	var q2 = quadrants[1]
	
	# Assuming half tile is modeled to cover top two quadrants by default
	# Rotations: 0 = top (0,1), 90 = right (1,3), 180 = bottom (2,3), 270 = left (0,2)
	
	if (q1 == 0 and q2 == 1) or (q1 == 1 and q2 == 0):
		return 0  # Top horizontal
	elif (q1 == 1 and q2 == 3) or (q1 == 3 and q2 == 1):
		return 10  # Right vertical (90 degrees = orientation 10 in Godot)
	elif (q1 == 2 and q2 == 3) or (q1 == 3 and q2 == 2):
		return 20  # Bottom horizontal (180 degrees = orientation 20)
	elif (q1 == 0 and q2 == 2) or (q1 == 2 and q2 == 0):
		return 30  # Left vertical (270 degrees = orientation 30)
	
	return 0


## Place a quarter tile with appropriate rotation
func _place_quarter_tile(grid_x: int, grid_z: int, quadrant: int, tile_set: Dictionary) -> void:
	var rotation = _get_quarter_tile_rotation(quadrant)
	
	# For quarter tiles, we might need to use basis rotation instead of simple orientation
	# This depends on how your quarter tile meshes are set up
	floor_grid.set_cell_item(Vector3i(grid_x, floor_y_level, grid_z), tile_set["quarter"], rotation)


## Get rotation for quarter tile based on which quadrant it covers
func _get_quarter_tile_rotation(quadrant: int) -> int:
	# Assuming quarter tile is modeled to cover top-left quadrant by default
	match quadrant:
		0: return 0   # Top-left
		1: return 10  # Top-right (90 degrees)
		2: return 30  # Bottom-left (270 degrees)
		3: return 20  # Bottom-right (180 degrees)
	return 0


## Place threequarter tile and the remaining quarter tile
func _place_threequarter_and_quarter(grid_x: int, grid_z: int, tile_type: String, quadrants: Array, tile_set: Dictionary) -> void:
	# Find which quadrant is NOT covered (the missing one)
	var all_quads = [0, 1, 2, 3]
	var missing_quad = -1
	
	for q in all_quads:
		if not quadrants.has(q):
			missing_quad = q
			break
	
	if missing_quad == -1:
		push_error("Error: couldn't find missing quadrant for threequarter tile")
		return
	
	# Place threequarter tile (rotated to leave the missing quadrant empty)
	var rotation = _get_threequarter_tile_rotation(missing_quad)
	_place_tile(grid_x, grid_z, tile_set["threequarter"], rotation)
	
	# Note: The quarter tile for the missing quadrant should be handled
	# in a subsequent call to this function for a different tile type


## Get rotation for threequarter tile based on which quadrant is MISSING
func _get_threequarter_tile_rotation(missing_quadrant: int) -> int:
	# Assuming threequarter tile is modeled with top-left quadrant missing by default
	match missing_quadrant:
		0: return 0   # Top-left missing
		1: return 30  # Top-right missing (270 degrees)
		2: return 10  # Bottom-left missing (90 degrees)
		3: return 20  # Bottom-right missing (180 degrees)
	return 0


## Remove simple floor tiles from primary grid after processing
func _remove_simple_floors_if_needed(grid_x: int, grid_z: int, tiles: Array) -> void:
	# Remove simple floor tiles from the 4 overlapping primary grid positions
	var positions = [
		Vector3i(grid_x, floor_y_level, grid_z),
		Vector3i(grid_x + 1, floor_y_level, grid_z),
		Vector3i(grid_x, floor_y_level, grid_z + 1),
		Vector3i(grid_x + 1, floor_y_level, grid_z + 1)
	]
	
	for i in range(4):
		if tiles[i] != "":
			var cell_item = primary_grid.get_cell_item(positions[i])
			if cell_item == simple_floor_tile_id:
				primary_grid.set_cell_item(positions[i], GridMap.INVALID_CELL_ITEM)


## Alternative placement method using multiple GridMap items for complex cases
## Use this if you need to place multiple meshes in the same dual-grid cell
func _place_multiple_quarters(grid_x: int, grid_z: int, tile_configs: Array) -> void:
	# tile_configs: Array of {type: String, quadrant: int}
	# This is more complex and might require using MultiMeshInstance3D or
	# custom mesh placement instead of GridMap for overlapping meshes
	pass
