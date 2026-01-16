# entity_culling.gd
extends Node3D
class_name EntityCullingSystem

## Optimized entity culling with cached entity list

@export var player: Node3D
@export var vision_cone: Node3D
@export var map_container: Node3D
@export var update_interval: float = 0.1

var map_generator: GridMap
var is_passive_mode: bool = false
var update_timer: float = 0.0
var is_initialized: bool = false

# Cached entity list
var cached_entities: Array = []
var cache_dirty: bool = true
var cache_update_timer: float = 0.0
var cache_update_interval: float = 1.0  # Refresh entity cache every second

func _ready():
	if not player or not vision_cone or not map_container:
		push_error("EntityCulling: Missing references!")
		return
	
	find_map()
	
	# Connect to world signals for entity spawns/despawns
	var world = get_tree().get_first_node_in_group("world")
	if world:
		world.child_entered_tree.connect(_on_entity_spawned)
		world.child_exiting_tree.connect(_on_entity_despawned)

func find_map():
	map_generator = find_gridmap_recursive(map_container)
	if map_generator:
		is_initialized = true
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

func _on_entity_spawned(_node: Node):
	cache_dirty = true

func _on_entity_despawned(_node: Node):
	cache_dirty = true

func _process(delta):
	if not is_initialized:
		find_map()
		return
	
	# Check if map changed
	if not is_instance_valid(map_generator):
		is_initialized = false
		map_generator = null
		is_passive_mode = false
		cached_entities.clear()
		cache_dirty = true
		find_map()
		return
	
	# Refresh cache periodically or when dirty
	cache_update_timer += delta
	if cache_dirty or cache_update_timer >= cache_update_interval:
		cache_update_timer = 0.0
		refresh_entity_cache()
		cache_dirty = false
	
	# Show all on passive maps
	if is_passive_mode:
		if update_timer == 0.0:
			show_all_entities()
		return
	
	# Update visibility
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		update_entity_visibility()

func refresh_entity_cache():
	"""Rebuild the cached entity list"""
	cached_entities.clear()
	
	var world = get_tree().get_first_node_in_group("world")
	if not world:
		return
	
	find_entities_recursive(world, cached_entities)

func find_entities_recursive(node: Node, entities: Array):
	"""Recursively find all entities in the scene"""
	if node.is_in_group("enemy") or node.is_in_group("npc") or node.is_in_group("item"):
		if node is Node3D:
			entities.append(node)
	
	for child in node.get_children():
		find_entities_recursive(child, entities)

func update_entity_visibility():
	"""Update visibility for all cached entities"""
	# Check if vision is disabled
	var vision_disabled = false
	if vision_cone.has_method("get") and vision_cone.get("debug_disabled") != null:
		vision_disabled = vision_cone.get("debug_disabled")
	
	# Clean up invalid entities from cache
	cached_entities = cached_entities.filter(func(e): return is_instance_valid(e))
	
	for entity in cached_entities:
		# Show all if vision disabled or passive map
		if vision_disabled or is_passive_mode:
			entity.visible = true
			continue
		
		# Check visibility
		var is_visible = false
		if vision_cone.has_method("is_position_visible"):
			is_visible = vision_cone.is_position_visible(entity.global_position)
		elif vision_cone.has_method("is_tile_visible"):
			# Fallback for old system
			var entity_grid = map_generator.local_to_map(entity.global_position)
			var entity_world = map_generator.map_to_local(entity_grid)
			is_visible = vision_cone.is_tile_visible(entity_world)
		
		entity.visible = is_visible

func show_all_entities():
	"""Show all entities - used for passive maps"""
	for entity in cached_entities:
		if is_instance_valid(entity):
			entity.visible = true
