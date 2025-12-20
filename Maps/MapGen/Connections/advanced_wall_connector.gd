extends Resource
class_name AdvancedWallConnector

## Holds all tile ID variations for advanced wall auto-tiling
## Based on adjacency to same tile type
## Use tile IDs from your MeshLibrary instead of direct meshes

@export_group("Basic Shapes")
@export var o_tile_id: int = 15  ## No connections (isolated)
@export var u_tile_id: int = 20  ## One connection
@export var i_tile_id: int = 12  ## Two opposite connections (straight)

@export_group("L Shapes")
@export var l_none_tile_id: int = 13  ## Two adjacent connections, no corner
@export var l_single_tile_id: int = 14  ## Two adjacent connections, with corner

@export_group("T Shapes")
@export var t_none_tile_id: int = 16  ## Three connections, no corners
@export var t_single_right_tile_id: int = 17  ## Three connections, SE corner
@export var t_single_left_tile_id: int = 18  ## Three connections, SW corner
@export var t_double_tile_id: int = 19  ## Three connections, two corners

@export_group("X Shapes (All Four Sides)")
@export var x_none_tile_id: int = 21  ## Four connections, no corners
@export var x_single_tile_id: int = 22  ## Four connections, one corner
@export var x_side_tile_id: int = 23  ## Four connections, two adjacent corners
@export var x_opposite_tile_id: int = 24  ## Four connections, two opposite corners
@export var x_triple_tile_id: int = 25  ## Four connections, three corners
@export var x_quad_tile_id: int = 26  ## Four connections, all four corners

## Get the appropriate tile ID and rotation for a given adjacency map
func get_tile_and_rotation(adjacency_map: Dictionary) -> Dictionary:
	var shape = AdjacencyShapeResolver.get_advanced_shape(adjacency_map)
	var tile_id: int = -1
	var rotation: float = 0.0
	
	match shape:
		AdjacencyShapeResolver.AdjacencyShape.O:
			tile_id = o_tile_id
		AdjacencyShapeResolver.AdjacencyShape.U:
			tile_id = u_tile_id
			rotation = AdjacencyShapeResolver.get_rotation_for_shape(shape, adjacency_map)
		AdjacencyShapeResolver.AdjacencyShape.I:
			tile_id = i_tile_id
			rotation = AdjacencyShapeResolver.get_rotation_for_shape(shape, adjacency_map)
		AdjacencyShapeResolver.AdjacencyShape.L_NONE:
			tile_id = l_none_tile_id
			rotation = AdjacencyShapeResolver.get_rotation_for_shape(shape, adjacency_map)
		AdjacencyShapeResolver.AdjacencyShape.L_SINGLE:
			tile_id = l_single_tile_id
			rotation = AdjacencyShapeResolver.get_rotation_for_shape(shape, adjacency_map)
		AdjacencyShapeResolver.AdjacencyShape.T_NONE:
			tile_id = t_none_tile_id
			rotation = AdjacencyShapeResolver.get_rotation_for_shape(shape, adjacency_map)
		AdjacencyShapeResolver.AdjacencyShape.T_SINGLE_LEFT:
			tile_id = t_single_left_tile_id
			rotation = AdjacencyShapeResolver.get_rotation_for_shape(shape, adjacency_map)
		AdjacencyShapeResolver.AdjacencyShape.T_SINGLE_RIGHT:
			tile_id = t_single_right_tile_id
			rotation = AdjacencyShapeResolver.get_rotation_for_shape(shape, adjacency_map)
		AdjacencyShapeResolver.AdjacencyShape.T_DOUBLE:
			tile_id = t_double_tile_id
			rotation = AdjacencyShapeResolver.get_rotation_for_shape(shape, adjacency_map)
		AdjacencyShapeResolver.AdjacencyShape.X_NONE:
			tile_id = x_none_tile_id
		AdjacencyShapeResolver.AdjacencyShape.X_SINGLE:
			tile_id = x_single_tile_id
			rotation = AdjacencyShapeResolver.get_rotation_for_shape(shape, adjacency_map)
		AdjacencyShapeResolver.AdjacencyShape.X_OPPOSITE:
			tile_id = x_opposite_tile_id
			rotation = AdjacencyShapeResolver.get_rotation_for_shape(shape, adjacency_map)
		AdjacencyShapeResolver.AdjacencyShape.X_SIDE:
			tile_id = x_side_tile_id
			rotation = AdjacencyShapeResolver.get_rotation_for_shape(shape, adjacency_map)
		AdjacencyShapeResolver.AdjacencyShape.X_TRIPLE:
			tile_id = x_triple_tile_id
			rotation = AdjacencyShapeResolver.get_rotation_for_shape(shape, adjacency_map)
		AdjacencyShapeResolver.AdjacencyShape.X_QUAD:
			tile_id = x_quad_tile_id
	
	# Use fallback if tile not assigned
	if tile_id == -1:
		tile_id = o_tile_id if o_tile_id != -1 else 0
	
	return {
		"tile_id": tile_id,
		"rotation": rotation,
		"shape": shape
	}
