# roads_mapgen.gd
# Road generation feature - handles pathfinding and road placement
class_name RoadsMapGen
extends RefCounted

# ============================================================================
# REFERENCES
# ============================================================================

var map_generator: GridMap
var entrance_zone_tiles: Array
var exit_zone_tiles: Array
var grass_tile_id: int
var stone_road_tile_id: int
var exterior_wall_tile_id: int

# ============================================================================
# SETTINGS
# ============================================================================

var road_width: int = 2
var road_min_distance_from_exterior: int = 2
var road_zone_proximity: int = 5

# ============================================================================
# DATA
# ============================================================================

var road_tiles: Array = []

# ============================================================================
# SETUP
# ============================================================================

func setup(generator: CoreMapGen):
	map_generator = generator
	entrance_zone_tiles = generator.entrance_zone_tiles
	exit_zone_tiles = generator.exit_zone_tiles
	grass_tile_id = generator.grass_tile_id
	stone_road_tile_id = generator.stone_road_tile_id
	exterior_wall_tile_id = generator.exterior_wall_tile_id

# ============================================================================
# GENERATION
# ============================================================================

func generate():
	print("Generating road from entrance to exit...")
	road_tiles.clear()
	
	if entrance_zone_tiles.size() == 0 or exit_zone_tiles.size() == 0:
		print("Warning: Cannot generate road - missing entrance or exit zone")
		return
	
	var entrance_center = get_zone_center(entrance_zone_tiles)
	var exit_center = get_zone_center(exit_zone_tiles)
	
	print("  Entrance center: ", entrance_center)
	print("  Exit center: ", exit_center)
	
	# Try strict pathfinding first
	var path = find_road_path(entrance_center, exit_center)
	
	if path.size() == 0:
		print("  Strict pathfinding failed, trying semi-relaxed (2 tiles from walls)...")
		path = find_road_path_semi_relaxed(entrance_center, exit_center, 2)
	
	if path.size() == 0:
		print("  Semi-relaxed pathfinding failed, trying more relaxed (1 tile from walls)...")
		path = find_road_path_semi_relaxed(entrance_center, exit_center, 1)
	
	if path.size() == 0:
		print("  All constrained pathfinding failed, using fully relaxed...")
		path = find_road_path_relaxed(entrance_center, exit_center)
	
	if path.size() == 0:
		print("ERROR: Still could not find road path")
		return
	
	print("  Found path with ", path.size(), " tiles")
	
	# Place road tiles
	var tiles_placed = 0
	for i in range(path.size()):
		var path_tile = path[i]
		
		var current_tile = map_generator.get_cell_item(path_tile)
		if current_tile == grass_tile_id or current_tile == map_generator.entrance_tile_id or current_tile == map_generator.exit_tile_id:
			map_generator.set_cell_item(path_tile, stone_road_tile_id)
			road_tiles.append(path_tile)
			tiles_placed += 1
		
		# Make road wider
		var perpendicular_offset = get_perpendicular_offset_from_path(i, path)
		var side_tile = path_tile + perpendicular_offset
		
		var side_tile_type = map_generator.get_cell_item(side_tile)
		if side_tile_type == grass_tile_id or side_tile_type == map_generator.entrance_tile_id or side_tile_type == map_generator.exit_tile_id:
			map_generator.set_cell_item(side_tile, stone_road_tile_id)
			road_tiles.append(side_tile)
			tiles_placed += 1
	
	print("Road generated - ", tiles_placed, " tiles placed")

# ============================================================================
# PATHFINDING
# ============================================================================

func find_road_path(start: Vector3i, goal: Vector3i) -> Array:
	var open_set = [start]
	var came_from = {}
	var g_score = {start: 0}
	
	var iterations = 0
	var max_iterations = 100000
	
	while open_set.size() > 0 and iterations < max_iterations:
		iterations += 1
		
		var current = open_set[0]
		var lowest_g = g_score.get(current, 999999)
		for node in open_set:
			var g = g_score.get(node, 999999)
			if g < lowest_g:
				lowest_g = g
				current = node
		
		if current == goal:
			print("  Strict path found in ", iterations, " iterations")
			return reconstruct_path(came_from, current)
		
		open_set.erase(current)
		
		var neighbors = [
			Vector3i(current.x + 1, 0, current.z),
			Vector3i(current.x - 1, 0, current.z),
			Vector3i(current.x, 0, current.z + 1),
			Vector3i(current.x, 0, current.z - 1)
		]
		
		for neighbor in neighbors:
			if not is_valid_road_tile(neighbor, start, goal):
				continue
			
			var step_cost = 1.0 + (sin(neighbor.x * 0.2) * cos(neighbor.z * 0.2)) * 0.3
			var tentative_g = g_score.get(current, 999999) + step_cost
			
			if tentative_g < g_score.get(neighbor, 999999):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				
				if not open_set.has(neighbor):
					open_set.append(neighbor)
	
	print("  Strict pathfinding failed after ", iterations, " iterations")
	return []

func find_road_path_semi_relaxed(start: Vector3i, goal: Vector3i, min_wall_distance: int) -> Array:
	var open_set = [start]
	var came_from = {}
	var g_score = {start: 0}
	var f_score = {start: heuristic_organic(start, goal)}
	
	var iterations = 0
	var max_iterations = 50000
	
	while open_set.size() > 0 and iterations < max_iterations:
		iterations += 1
		
		var current = open_set[0]
		var lowest_f = f_score.get(current, 999999)
		for node in open_set:
			var f = f_score.get(node, 999999)
			if f < lowest_f:
				lowest_f = f
				current = node
		
		if current == goal:
			print("  Semi-relaxed path found (", min_wall_distance, " tiles from walls) in ", iterations, " iterations")
			return reconstruct_path(came_from, current)
		
		open_set.erase(current)
		
		var neighbors = [
			Vector3i(current.x + 1, 0, current.z),
			Vector3i(current.x - 1, 0, current.z),
			Vector3i(current.x, 0, current.z + 1),
			Vector3i(current.x, 0, current.z - 1)
		]
		
		for neighbor in neighbors:
			var tile = map_generator.get_cell_item(neighbor)
			if tile != grass_tile_id and tile != map_generator.entrance_tile_id and tile != map_generator.exit_tile_id:
				continue
			
			var dist_to_start = abs(neighbor.x - start.x) + abs(neighbor.z - start.z)
			var dist_to_goal = abs(neighbor.x - goal.x) + abs(neighbor.z - goal.z)
			
			if dist_to_start > road_zone_proximity and dist_to_goal > road_zone_proximity:
				var wall_dist = distance_to_nearest_exterior_wall(neighbor)
				if wall_dist < min_wall_distance:
					continue
			
			var tentative_g = g_score.get(current, 999999) + 1
			
			if tentative_g < g_score.get(neighbor, 999999):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + heuristic_organic(neighbor, goal)
				
				if not open_set.has(neighbor):
					open_set.append(neighbor)
	
	print("  Semi-relaxed pathfinding (", min_wall_distance, " tiles) failed after ", iterations, " iterations")
	return []

func find_road_path_relaxed(start: Vector3i, goal: Vector3i) -> Array:
	var open_set = [start]
	var came_from = {}
	var g_score = {start: 0}
	var f_score = {start: heuristic(start, goal)}
	
	var iterations = 0
	var max_iterations = 10000
	
	while open_set.size() > 0 and iterations < max_iterations:
		iterations += 1
		
		var current = open_set[0]
		var lowest_f = f_score.get(current, 999999)
		for node in open_set:
			var f = f_score.get(node, 999999)
			if f < lowest_f:
				lowest_f = f
				current = node
		
		if current == goal:
			print("  Path found in ", iterations, " iterations")
			return reconstruct_path(came_from, current)
		
		open_set.erase(current)
		
		var neighbors = [
			Vector3i(current.x + 1, 0, current.z),
			Vector3i(current.x - 1, 0, current.z),
			Vector3i(current.x, 0, current.z + 1),
			Vector3i(current.x, 0, current.z - 1)
		]
		
		for neighbor in neighbors:
			var tile = map_generator.get_cell_item(neighbor)
			if tile != grass_tile_id and tile != map_generator.entrance_tile_id and tile != map_generator.exit_tile_id:
				continue
			
			var tentative_g = g_score.get(current, 999999) + 1
			
			if tentative_g < g_score.get(neighbor, 999999):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + heuristic(neighbor, goal)
				
				if not open_set.has(neighbor):
					open_set.append(neighbor)
	
	print("  Relaxed pathfinding failed after ", iterations, " iterations")
	return []

func is_valid_road_tile(pos: Vector3i, start: Vector3i, goal: Vector3i) -> bool:
	if map_generator.get_cell_item(pos) != grass_tile_id:
		return false
	
	var dist_to_start = abs(pos.x - start.x) + abs(pos.z - start.z)
	var dist_to_goal = abs(pos.x - goal.x) + abs(pos.z - goal.z)
	
	if dist_to_start <= road_zone_proximity or dist_to_goal <= road_zone_proximity:
		return true
	
	var dist_to_wall = distance_to_nearest_exterior_wall(pos)
	return dist_to_wall >= road_min_distance_from_exterior

func distance_to_nearest_exterior_wall(pos: Vector3i) -> int:
	var check_radius = road_min_distance_from_exterior + 2
	var min_dist = 999999
	
	for dx in range(-check_radius, check_radius + 1):
		for dz in range(-check_radius, check_radius + 1):
			var check_pos = Vector3i(pos.x + dx, 0, pos.z + dz)
			if map_generator.get_cell_item(check_pos) == exterior_wall_tile_id:
				var dist = abs(dx) + abs(dz)
				if dist < min_dist:
					min_dist = dist
	
	return min_dist

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func get_zone_center(zone_tiles: Array) -> Vector3i:
	if zone_tiles.size() == 0:
		return Vector3i.ZERO
	
	var sum_x = 0
	var sum_z = 0
	for tile in zone_tiles:
		sum_x += tile.x
		sum_z += tile.z
	
	return Vector3i(sum_x / zone_tiles.size(), 0, sum_z / zone_tiles.size())

func heuristic(a: Vector3i, b: Vector3i) -> int:
	return abs(a.x - b.x) + abs(a.z - b.z)

func heuristic_organic(pos: Vector3i, goal: Vector3i) -> float:
	var base_distance = abs(pos.x - goal.x) + abs(pos.z - goal.z)
	var noise_x = sin(pos.x * 0.3) * cos(pos.z * 0.3)
	var noise_z = cos(pos.x * 0.3) * sin(pos.z * 0.3)
	var noise = (noise_x + noise_z) * 2.0
	var random_offset = float((pos.x * 73 + pos.z * 37) % 6 - 3)
	return float(base_distance) + noise + random_offset

func reconstruct_path(came_from: Dictionary, current: Vector3i) -> Array:
	var path = [current]
	while came_from.has(current):
		current = came_from[current]
		path.insert(0, current)
	return path

func get_perpendicular_offset_from_path(index: int, path: Array) -> Vector3i:
	var direction = Vector3i.ZERO
	
	if index < path.size() - 1:
		var next = path[index + 1]
		var current = path[index]
		direction = next - current
	elif index > 0:
		var current = path[index]
		var prev = path[index - 1]
		direction = current - prev
	
	if direction.x != 0:
		return Vector3i(0, 0, 1)
	elif direction.z != 0:
		return Vector3i(1, 0, 0)
	else:
		return Vector3i(1, 0, 0)
