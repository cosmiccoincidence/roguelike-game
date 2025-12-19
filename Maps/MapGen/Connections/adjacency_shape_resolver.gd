class_name AdjacencyShapeResolver
extends RefCounted

## Resolves adjacency shapes for auto-tiling walls

enum AdjacencyShape {
	O,           # No connections (isolated)
	U,           # One connection
	I,           # Two opposite connections (straight)
	L_NONE,      # Two adjacent connections, no corner
	L_SINGLE,    # Two adjacent connections, with corner
	T_NONE,      # Three connections, no corners
	T_SINGLE_LEFT,   # Three connections, one corner (left)
	T_SINGLE_RIGHT,  # Three connections, one corner (right)
	T_DOUBLE,    # Three connections, two corners
	X_NONE,      # Four connections, no corners
	X_SINGLE,    # Four connections, one corner
	X_OPPOSITE,  # Four connections, two opposite corners
	X_SIDE,      # Four connections, two adjacent corners
	X_TRIPLE,    # Four connections, three corners
	X_QUAD       # Four connections, all four corners
}

enum Direction {
	NORTH,
	SOUTH,
	EAST,
	WEST,
	NORTH_EAST,
	SOUTH_EAST,
	SOUTH_WEST,
	NORTH_WEST
}

## Check if a direction is diagonal
static func is_diagonal(dir: Direction) -> bool:
	return dir in [Direction.NORTH_EAST, Direction.SOUTH_EAST, Direction.SOUTH_WEST, Direction.NORTH_WEST]

## Get the advanced shape based on adjacency connections
static func get_advanced_shape(adjacency_map: Dictionary) -> AdjacencyShape:
	var cardinal_count = count_cardinal_connections(adjacency_map)
	
	match cardinal_count:
		0:
			return AdjacencyShape.O
		1:
			return AdjacencyShape.U
		2:
			return get_two_connection_shape(adjacency_map)
		3:
			return get_three_connection_shape(adjacency_map)
		4:
			return get_four_connection_shape(adjacency_map)
	
	return AdjacencyShape.O

static func count_cardinal_connections(adjacency_map: Dictionary) -> int:
	var count = 0
	for dir in [Direction.NORTH, Direction.SOUTH, Direction.EAST, Direction.WEST]:
		if adjacency_map.get(dir, false):
			count += 1
	return count

static func get_two_connection_shape(adjacency_map: Dictionary) -> AdjacencyShape:
	var north = adjacency_map.get(Direction.NORTH, false)
	var south = adjacency_map.get(Direction.SOUTH, false)
	var east = adjacency_map.get(Direction.EAST, false)
	var west = adjacency_map.get(Direction.WEST, false)
	
	# Check if opposite (I shape) or adjacent (L shape)
	if (north and south) or (east and west):
		return AdjacencyShape.I
	
	# L shape - check corners
	if north and east:
		return AdjacencyShape.L_SINGLE if adjacency_map.get(Direction.NORTH_EAST, false) else AdjacencyShape.L_NONE
	elif north and west:
		return AdjacencyShape.L_SINGLE if adjacency_map.get(Direction.NORTH_WEST, false) else AdjacencyShape.L_NONE
	elif south and east:
		return AdjacencyShape.L_SINGLE if adjacency_map.get(Direction.SOUTH_EAST, false) else AdjacencyShape.L_NONE
	elif south and west:
		return AdjacencyShape.L_SINGLE if adjacency_map.get(Direction.SOUTH_WEST, false) else AdjacencyShape.L_NONE
	
	return AdjacencyShape.L_NONE

static func get_three_connection_shape(adjacency_map: Dictionary) -> AdjacencyShape:
	var north = adjacency_map.get(Direction.NORTH, false)
	var south = adjacency_map.get(Direction.SOUTH, false)
	var east = adjacency_map.get(Direction.EAST, false)
	var west = adjacency_map.get(Direction.WEST, false)
	
	# Determine which direction is missing (the opening of the T)
	var missing_direction = -1
	if not north:
		missing_direction = 0  # North missing = opening faces north
	elif not south:
		missing_direction = 1  # South missing = opening faces south
	elif not east:
		missing_direction = 2  # East missing = opening faces east
	elif not west:
		missing_direction = 3  # West missing = opening faces west
	
	# Count corners and determine which ones are present
	var corners = []
	
	match missing_direction:
		0:  # North missing (South, East, West connected)
			if adjacency_map.get(Direction.SOUTH_EAST, false):
				corners.append("SE")
			if adjacency_map.get(Direction.SOUTH_WEST, false):
				corners.append("SW")
		1:  # South missing (North, East, West connected)
			if adjacency_map.get(Direction.NORTH_EAST, false):
				corners.append("NE")
			if adjacency_map.get(Direction.NORTH_WEST, false):
				corners.append("NW")
		2:  # East missing (North, South, West connected)
			if adjacency_map.get(Direction.NORTH_WEST, false):
				corners.append("NW")
			if adjacency_map.get(Direction.SOUTH_WEST, false):
				corners.append("SW")
		3:  # West missing (North, South, East connected)
			if adjacency_map.get(Direction.NORTH_EAST, false):
				corners.append("NE")
			if adjacency_map.get(Direction.SOUTH_EAST, false):
				corners.append("SE")
	
	var corner_count = corners.size()
	
	match corner_count:
		0:
			return AdjacencyShape.T_NONE
		1:
			# Determine if it's left or right based on which corner is present
			# When looking at the T from the opening side:
			# - RIGHT corner = clockwise from opening
			# - LEFT corner = counter-clockwise from opening
			
			var corner = corners[0]
			
			match missing_direction:
				0:  # North missing (opening faces north) - SWAPPED
					# Looking north: SW is right, SE is left
					return AdjacencyShape.T_SINGLE_RIGHT if corner == "SW" else AdjacencyShape.T_SINGLE_LEFT
				1:  # South missing (opening faces south) - SWAPPED
					# Looking south: NE is right, NW is left
					return AdjacencyShape.T_SINGLE_RIGHT if corner == "NE" else AdjacencyShape.T_SINGLE_LEFT
				2:  # East missing (opening faces east)
					# Looking east: NW is right, SW is left
					return AdjacencyShape.T_SINGLE_RIGHT if corner == "NW" else AdjacencyShape.T_SINGLE_LEFT
				3:  # West missing (opening faces west)
					# Looking west: SE is right, NE is left
					return AdjacencyShape.T_SINGLE_RIGHT if corner == "SE" else AdjacencyShape.T_SINGLE_LEFT
			
			return AdjacencyShape.T_SINGLE_LEFT  # Fallback
		2:
			return AdjacencyShape.T_DOUBLE
	
	return AdjacencyShape.T_NONE

static func get_four_connection_shape(adjacency_map: Dictionary) -> AdjacencyShape:
	var corner_count = 0
	
	if adjacency_map.get(Direction.NORTH_EAST, false):
		corner_count += 1
	if adjacency_map.get(Direction.SOUTH_EAST, false):
		corner_count += 1
	if adjacency_map.get(Direction.SOUTH_WEST, false):
		corner_count += 1
	if adjacency_map.get(Direction.NORTH_WEST, false):
		corner_count += 1
	
	match corner_count:
		0:
			return AdjacencyShape.X_NONE
		1:
			return AdjacencyShape.X_SINGLE
		2:
			# Check if opposite or adjacent
			var ne = adjacency_map.get(Direction.NORTH_EAST, false)
			var se = adjacency_map.get(Direction.SOUTH_EAST, false)
			var sw = adjacency_map.get(Direction.SOUTH_WEST, false)
			var nw = adjacency_map.get(Direction.NORTH_WEST, false)
			
			if (ne and sw) or (se and nw):
				return AdjacencyShape.X_OPPOSITE
			else:
				return AdjacencyShape.X_SIDE
		3:
			return AdjacencyShape.X_TRIPLE
		4:
			return AdjacencyShape.X_QUAD
	
	return AdjacencyShape.X_NONE

## Get rotation angle for a given shape and adjacency
static func get_rotation_for_shape(shape: AdjacencyShape, adjacency_map: Dictionary) -> float:
	match shape:
		AdjacencyShape.U:
			return get_single_connection_rotation(adjacency_map)
		AdjacencyShape.I:
			return get_i_shape_rotation(adjacency_map)
		AdjacencyShape.L_NONE, AdjacencyShape.L_SINGLE:
			return get_l_shape_rotation(adjacency_map)
		AdjacencyShape.T_NONE, AdjacencyShape.T_SINGLE_LEFT, AdjacencyShape.T_SINGLE_RIGHT, AdjacencyShape.T_DOUBLE:
			return get_t_shape_rotation(adjacency_map)
		AdjacencyShape.X_SINGLE:
			return get_x_single_rotation(adjacency_map)
		AdjacencyShape.X_OPPOSITE:
			return get_x_opposite_rotation(adjacency_map)
		AdjacencyShape.X_SIDE:
			return get_x_side_rotation(adjacency_map)
		AdjacencyShape.X_TRIPLE:
			return get_x_triple_rotation(adjacency_map)
	
	return 0.0

static func get_single_connection_rotation(adjacency_map: Dictionary) -> float:
	if adjacency_map.get(Direction.NORTH, false):
		return 0.0
	elif adjacency_map.get(Direction.EAST, false):
		return 270.0  # East connection (was 90°, fixed)
	elif adjacency_map.get(Direction.SOUTH, false):
		return 180.0
	elif adjacency_map.get(Direction.WEST, false):
		return 90.0  # West connection (was 270°, fixed)
	return 0.0

static func get_i_shape_rotation(adjacency_map: Dictionary) -> float:
	if adjacency_map.get(Direction.NORTH, false):
		return 0.0  # North-South
	else:
		return 90.0  # East-West

static func get_l_shape_rotation(adjacency_map: Dictionary) -> float:
	var north = adjacency_map.get(Direction.NORTH, false)
	var south = adjacency_map.get(Direction.SOUTH, false)
	var east = adjacency_map.get(Direction.EAST, false)
	var west = adjacency_map.get(Direction.WEST, false)
	
	if north and east:
		return 0.0  # NE corner
	elif south and east:
		return 270.0  # SE corner (was 90°, fixed)
	elif south and west:
		return 180.0  # SW corner
	elif north and west:
		return 90.0  # NW corner (was 270°, fixed)
	return 0.0

static func get_t_shape_rotation(adjacency_map: Dictionary) -> float:
	# Find the single non-connection (the opening of the T)
	# The rotation should point the opening toward the missing connection
	if not adjacency_map.get(Direction.NORTH, false):
		return 180.0  # Opening faces north (flipped from 0)
	elif not adjacency_map.get(Direction.EAST, false):
		return 90.0   # Opening faces east
	elif not adjacency_map.get(Direction.SOUTH, false):
		return 0.0    # Opening faces south (flipped from 180)
	elif not adjacency_map.get(Direction.WEST, false):
		return 270.0  # Opening faces west
	return 0.0

static func get_x_single_rotation(adjacency_map: Dictionary) -> float:
	# X2 - one corner present
	if adjacency_map.get(Direction.NORTH_EAST, false):
		return 0.0
	elif adjacency_map.get(Direction.SOUTH_EAST, false):
		return 270.0  # Was 90°, add 180° for SE
	elif adjacency_map.get(Direction.SOUTH_WEST, false):
		return 180.0
	elif adjacency_map.get(Direction.NORTH_WEST, false):
		return 90.0   # Was 270°, add 180° for NW
	return 0.0

static func get_x_opposite_rotation(adjacency_map: Dictionary) -> float:
	if adjacency_map.get(Direction.NORTH_EAST, false):
		return 0.0
	else:
		return 90.0

static func get_x_side_rotation(adjacency_map: Dictionary) -> float:
	# X3 - two adjacent corners present
	var ne = adjacency_map.get(Direction.NORTH_EAST, false)
	var se = adjacency_map.get(Direction.SOUTH_EAST, false)
	var sw = adjacency_map.get(Direction.SOUTH_WEST, false)
	var nw = adjacency_map.get(Direction.NORTH_WEST, false)
	
	if nw and ne:
		return 0.0      # North side - correct
	elif ne and se:
		return 270.0    # East side - was 90°, add 180°
	elif se and sw:
		return 180.0    # South side - correct
	elif sw and nw:
		return 90.0     # West side - was 270°, add 180°
	return 0.0

static func get_x_triple_rotation(adjacency_map: Dictionary) -> float:
	# X5 - three corners present (one missing)
	# Find the single non-connection
	if not adjacency_map.get(Direction.NORTH_EAST, false):
		return 90.0     # NE missing - was 270°, add 180°
	elif not adjacency_map.get(Direction.SOUTH_EAST, false):
		return 0.0      # SE missing - correct
	elif not adjacency_map.get(Direction.SOUTH_WEST, false):
		return 270.0    # SW missing - was 90°, add 180°
	elif not adjacency_map.get(Direction.NORTH_WEST, false):
		return 180.0    # NW missing - correct
	return 0.0
