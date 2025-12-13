extends Resource
class_name LootTable

## LootTable resource - define collections of items with drop chances
## Can be saved as .tres files and reused across different enemies/chests

## Drop weights determine relative probability:
## item weight / sum of all item weights in array = % chance

@export var drop_chance: float = 1.0  # 0.0 to 1.0 (0% to 100%)
@export var min_drops: int = 0  # Minimum number of items to drop
@export var max_drops: int = 1  # Maximum number of items to drop

# Arrays for loot entries (parallel arrays)
@export var item_scenes: Array[PackedScene] = []
@export var drop_weights: Array[float] = []  # Corresponds to item_scenes
@export var min_amounts: Array[int] = []  # Minimum quantity per drop
@export var max_amounts: Array[int] = []  # Maximum quantity per drop

func add_entry(item: PackedScene, weight: float = 1.0, min_amt: int = 1, max_amt: int = 1):
	item_scenes.append(item)
	drop_weights.append(weight)
	min_amounts.append(min_amt)
	max_amounts.append(max_amt)

func roll_loot() -> Array[PackedScene]:
	var dropped_items: Array[PackedScene] = []
	
	# Check if we should drop anything at all
	if randf() > drop_chance:
		return dropped_items
	
	# Validate arrays
	if item_scenes.is_empty():
		return dropped_items
	
	# Ensure all arrays are the same size, fill with defaults if needed
	while drop_weights.size() < item_scenes.size():
		drop_weights.append(1.0)
	while min_amounts.size() < item_scenes.size():
		min_amounts.append(1)
	while max_amounts.size() < item_scenes.size():
		max_amounts.append(1)
	
	# Calculate total weight
	var total_weight := 0.0
	for weight in drop_weights:
		total_weight += weight
	
	if total_weight <= 0:
		return dropped_items
	
	# Determine how many items to drop
	var num_drops = randi_range(min_drops, max_drops)
	
	for i in range(num_drops):
		var roll = randf() * total_weight
		var current_weight := 0.0
		
		for j in range(item_scenes.size()):
			current_weight += drop_weights[j]
			if roll <= current_weight:
				# Determine quantity
				var quantity = randi_range(min_amounts[j], max_amounts[j])
				for k in range(quantity):
					dropped_items.append(item_scenes[j])
				break
	
	return dropped_items
