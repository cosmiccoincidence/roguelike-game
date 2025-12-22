extends Node
class_name DualGridFloor

## Dual Grid Floor Tile System with Multi-Layer Support
## This system uses a second gridmap offset by (0.5, 0, 0.5) to create seamless
## floor transitions by analyzing 4 overlapping tiles from the primary gridmap.
## Supports placing multiple meshes per cell using stacked Y-levels.

# References to the two gridmaps
var primary_grid: GridMap
var floor_grid: GridMap

# Dictionary to store tile IDs for different floor types and shapes
# Structure: { "floor_type": { "whole": id, "half": id, "threequarter": id, "quarter": id } }
var floor_tile_sets: Dictionary = {}

# Map tile IDs from primary grid to floor type names
var tile_id_to_type: Dictionary = {}

# Y level to process in primary grid (usually 0 for floors)
var floor_y_level: int = 0

# Base Y level for floor grid (we'll stack additional meshes at +1, +2, +3)
var floor_grid_base_y: int = 0


func _init(p_primary_grid: GridMap, p_floor_grid: GridMap):
	primary_grid = p_primary_grid
	floor_grid = p_floor_grid


## Register a floor type with its mesh tile IDs
## floor_type: string identifier (e.g., "grass", "road", "water", "interior_floor")
## tile_ids: Dictionary with keys: "whole", "half", "threequarter", "quarter"
func register_floor_type(floor_type: String, tile_ids: Dictionary) -> void:
	floor_tile_sets[floor_type] = tile_ids


## Map a primary grid tile ID to a floor type name
func map_tile_to_type(tile_id: int, type_name: String) -> void:
	tile_id_to_type[tile_id] = type_name


## Main processing function - call this after primary map generation is complete
func process_dual_grid_floors() -> void:
	print("[DualGridFloor] Starting dual-grid floor processing...")
	
	# Get bounds of the primary gridmap
	var used_cells = primary_grid.get_used_cells()
	if used_cells.is_empty():
		print("[DualGridFloor] No cells found in primary grid")
		return
	
	var min_pos = used_cells[0]
	var max_pos = used_cells[0]
	
	for cell in used_cells:
		if cell.y != floor_y_level:
			continue
			
		min_pos.x = min(min_pos.x, cell.x)
		min_pos.z = min(min_pos.z, cell.z)
		max_pos.x = max(max_pos.x, cell.x)
		max_pos.z = max(max_pos.z, cell.z)
	
	print("[DualGridFloor] Processing area from ", min_pos, " to ", max_pos)
	
	# Process each potential dual-grid position
	var cells_processed = 0
	for x in range(min_pos.x, max_pos.x + 1):
		for z in range(min_pos.z, max_pos.z + 1):
			if _process_dual_grid_cell(x, z):
				cells_processed += 1
	
	print("[DualGridFloor] Processed ", cells_processed, " dual-grid floor cells")


## Process a single dual-grid cell position
## Returns true if any meshes were placed
func _process_dual_grid_cell(x: int, z: int) -> bool:
	# Get the 4 overlapping tiles from primary grid
	# In dual-grid, a cell at (x, z) overlaps primary cells:
	# (x, z), (x+1, z), (x, z+1), (x+1, z+1)
	var tiles = [
		_get_floor_type_at(x, z),       # Top-left (quadrant 0)
		_get_floor_type_at(x + 1, z),   # Top-right (quadrant 1)
		_get_floor_type_at(x, z + 1),   # Bottom-left (quadrant 2)
		_get_floor_type_at(x + 1, z + 1) # Bottom-right (quadrant 3)
	]
	
	# If all tiles are empty, skip this dual-grid cell
	if tiles[0] == "" and tiles[1] == "" and tiles[2] == "" and tiles[3] == "":
		return false
	
	# Group tiles by type and position
	var tile_groups = _analyze_tile_quadrants(tiles)
	
	# Place the appropriate meshes for each tile type found
	# We'll use multiple Y-levels if needed (up to 4 meshes = 4 Y-levels)
	var y_level = floor_grid_base_y
	
	for tile_type in tile_groups.keys():
		var quadrants = tile_groups[tile_type]
		_place_floor_meshes(x, z, y_level, tile_type, quadrants)
		y_level += 1  # Next mesh goes on next Y-level
	
	return true


## Get the floor type at a specific position in the primary grid
func _get_floor_type_at(x: int, z: int) -> String:
	var cell_item = primary_grid.get_cell_item(Vector3i(x, floor_y_level, z))
	
	if cell_item == GridMap.INVALID_CELL_ITEM:
		return ""
	
	# Look up the floor type from our mapping
	if tile_id_to_type.has(cell_item):
		return tile_id_to_type[cell_item]
	
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
## Now includes y_level parameter for multi-layer support
func _place_floor_meshes(grid_x: int, grid_z: int, y_level: int, tile_type: String, quadrants: Array) -> void:
	if not floor_tile_sets.has(tile_type):
		push_warning("[DualGridFloor] Floor type '%s' not registered!" % tile_type)
		return
	
	var tile_set = floor_tile_sets[tile_type]
	var quad_count = quadrants.size()
	
	match quad_count:
		4:
			# All 4 quadrants - use whole tile
			_place_tile(grid_x, grid_z, y_level, tile_set["whole"], 0)
		
		3:
			# 3 quadrants - use threequarter tile
			_place_threequarter_tile(grid_x, grid_z, y_level, quadrants, tile_set)
		
		2:
			# 2 quadrants - check if adjacent or diagonal
			if _are_quadrants_adjacent(quadrants):
				_place_half_tile(grid_x, grid_z, y_level, quadrants, tile_set)
			else:
				# Diagonal - use 2 quarter tiles on SAME y-level but different positions
				# This is a special case - we need to place both quarters
				_place_diagonal_quarters(grid_x, grid_z, y_level, quadrants, tile_set)
		
		1:
			# Single quadrant - use quarter tile
			_place_quarter_tile(grid_x, grid_z, y_level, quadrants[0], tile_set)


## Check if two quadrants are adjacent
func _are_quadrants_adjacent(quadrants: Array) -> bool:
	if quadrants.size() != 2:
		return false
	
	var q1 = quadrants[0]
	var q2 = quadrants[1]
	
	# Quadrant layout:
	# 0 1
	# 2 3
	
	# Horizontal adjacency
	if (q1 == 0 and q2 == 1) or (q1 == 1 and q2 == 0):
		return true
	if (q1 == 2 and q2 == 3) or (q1 == 3 and q2 == 2):
		return true
	
	# Vertical adjacency
	if (q1 == 0 and q2 == 2) or (q1 == 2 and q2 == 0):
		return true
	if (q1 == 1 and q2 == 3) or (q1 == 3 and q2 == 1):
		return true
	
	return false


## Place a whole tile
func _place_tile(grid_x: int, grid_z: int, y_level: int, tile_id: int, rotation: int) -> void:
	floor_grid.set_cell_item(Vector3i(grid_x, y_level, grid_z), tile_id, rotation)


## Place a half tile with appropriate rotation
func _place_half_tile(grid_x: int, grid_z: int, y_level: int, quadrants: Array, tile_set: Dictionary) -> void:
	var rotation = _get_half_tile_rotation(quadrants)
	_place_tile(grid_x, grid_z, y_level, tile_set["half"], rotation)


## Get rotation for half tile based on which quadrants it covers
func _get_half_tile_rotation(quadrants: Array) -> int:
	var q1 = quadrants[0]
	var q2 = quadrants[1]
	
	# Assuming half tile is modeled to cover top two quadrants by default (0, 1)
	# Godot GridMap orientations for Y-axis rotation:
	# 0 = 0°, 16 = 90°, 10 = 180°, 22 = 270°
	
	if (q1 == 0 and q2 == 1) or (q1 == 1 and q2 == 0):
		return 0  # Top horizontal
	elif (q1 == 1 and q2 == 3) or (q1 == 3 and q2 == 1):
		return 16  # Right vertical (90°)
	elif (q1 == 2 and q2 == 3) or (q1 == 3 and q2 == 2):
		return 10  # Bottom horizontal (180°)
	elif (q1 == 0 and q2 == 2) or (q1 == 2 and q2 == 0):
		return 22  # Left vertical (270°)
	
	return 0


## Place two diagonal quarter tiles
## These go on the SAME y-level since they don't overlap spatially
func _place_diagonal_quarters(grid_x: int, grid_z: int, y_level: int, quadrants: Array, tile_set: Dictionary) -> void:
	# For diagonal quadrants, we can actually place both on the same Y-level
	# because they occupy different physical quadrants of the cell
	for quad in quadrants:
		_place_quarter_tile(grid_x, grid_z, y_level, quad, tile_set)


## Place a quarter tile with appropriate rotation
func _place_quarter_tile(grid_x: int, grid_z: int, y_level: int, quadrant: int, tile_set: Dictionary) -> void:
	var rotation = _get_quarter_tile_rotation(quadrant)
	_place_tile(grid_x, grid_z, y_level, tile_set["quarter"], rotation)


## Get rotation for quarter tile based on which quadrant it covers
func _get_quarter_tile_rotation(quadrant: int) -> int:
	# Assuming quarter tile is modeled to cover top-left quadrant (0) by default
	match quadrant:
		0: return 0   # Top-left
		1: return 16  # Top-right (90°)
		2: return 22  # Bottom-left (270°)
		3: return 10  # Bottom-right (180°)
	return 0


## Place threequarter tile
func _place_threequarter_tile(grid_x: int, grid_z: int, y_level: int, quadrants: Array, tile_set: Dictionary) -> void:
	# Find which quadrant is NOT covered (the missing one)
	var all_quads = [0, 1, 2, 3]
	var missing_quad = -1
	
	for q in all_quads:
		if not quadrants.has(q):
			missing_quad = q
			break
	
	if missing_quad == -1:
		push_error("[DualGridFloor] Error: couldn't find missing quadrant for threequarter tile")
		return
	
	# Place threequarter tile (rotated to leave the missing quadrant empty)
	var rotation = _get_threequarter_tile_rotation(missing_quad)
	_place_tile(grid_x, grid_z, y_level, tile_set["threequarter"], rotation)


## Get rotation for threequarter tile based on which quadrant is MISSING
func _get_threequarter_tile_rotation(missing_quadrant: int) -> int:
	# Assuming threequarter tile is modeled with top-left quadrant missing by default
	match missing_quadrant:
		0: return 0   # Top-left missing
		1: return 22  # Top-right missing (270°)
		2: return 16  # Bottom-left missing (90°)
		3: return 10  # Bottom-right missing (180°)
	return 0


## Optional: Clear processed floor tiles from primary grid
## Call this after process_dual_grid_floors() if you want to remove the simple tiles
func clear_primary_grid_floors() -> void:
	print("[DualGridFloor] Clearing processed floor tiles from primary grid...")
	
	var used_cells = primary_grid.get_used_cells()
	var cleared_count = 0
	
	for cell in used_cells:
		if cell.y != floor_y_level:
			continue
			
		var tile_id = primary_grid.get_cell_item(cell)
		if tile_id_to_type.has(tile_id):
			primary_grid.set_cell_item(cell, GridMap.INVALID_CELL_ITEM)
			cleared_count += 1
	
	print("[DualGridFloor] Cleared ", cleared_count, " floor tiles from primary grid")
