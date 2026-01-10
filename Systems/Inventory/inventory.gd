# inventory.gd
# Main inventory system - delegates to component scripts
extends Node

var items: Array = []
var max_slots: int = 32  # Match the UI grid (4 columns × 8 rows)
var player_ref: Node3D = null  # Reference to player for drop position

# Component references
var gold_manager: Node
var mass_manager: Node
var stacking_manager: Node

# Signals
signal inventory_changed
signal item_dropped(item_data, position)
signal mass_changed(current_mass, max_mass)
signal gold_changed(amount)
signal encumbered_status_changed(is_encumbered)

func _ready():
	# Initialize items array
	items.resize(max_slots)
	for i in range(max_slots):
		items[i] = null
	
	# Create component scripts
	_setup_components()

func _setup_components():
	"""Create and initialize component scripts"""
	# Gold manager
	var gold_script = load("res://Systems/Inventory/inventory_gold.gd")
	if gold_script:
		gold_manager = Node.new()
		gold_manager.name = "GoldManager"
		gold_manager.set_script(gold_script)
		add_child(gold_manager)
		gold_manager.gold_changed.connect(_on_gold_changed)
	
	# Mass manager
	var mass_script = load("res://Systems/Inventory/inventory_mass.gd")
	if mass_script:
		mass_manager = Node.new()
		mass_manager.name = "MassManager"
		mass_manager.set_script(mass_script)
		add_child(mass_manager)
		mass_manager.initialize(self)
		mass_manager.mass_changed.connect(_on_mass_changed)
		mass_manager.encumbered_status_changed.connect(_on_encumbered_changed)
	
	# Stacking manager
	var stacking_script = load("res://Systems/Inventory/inventory_stacking.gd")
	if stacking_script:
		stacking_manager = Node.new()
		stacking_manager.name = "StackingManager"
		stacking_manager.set_script(stacking_script)
		add_child(stacking_manager)
		stacking_manager.initialize(self)

# ===== SIGNAL RELAYS =====

func _on_gold_changed(amount: int):
	gold_changed.emit(amount)

func _on_mass_changed(current_mass: float, max_mass: float):
	mass_changed.emit(current_mass, max_mass)

func _on_encumbered_changed(is_encumbered: bool):
	encumbered_status_changed.emit(is_encumbered)

# ===== GOLD FUNCTIONS =====

func add_gold(amount: int):
	if gold_manager:
		gold_manager.add_gold(amount)

func remove_gold(amount: int) -> bool:
	if gold_manager:
		return gold_manager.remove_gold(amount)
	return false

func get_gold() -> int:
	if gold_manager:
		return gold_manager.get_gold()
	return 0

# ===== MASS FUNCTIONS =====

func get_total_mass() -> float:
	if mass_manager:
		return mass_manager.get_total_mass()
	return 0.0

func is_encumbered() -> bool:
	if mass_manager:
		return mass_manager.is_encumbered()
	return false

func _update_mass_signals():
	"""Update mass-related signals"""
	if mass_manager:
		mass_manager.update_signals()

# ===== ITEM MANAGEMENT =====

func add_item(item_data: Dictionary) -> bool:
	"""Add item to inventory using dictionary of properties"""
	var item_name = item_data.get("name", "Unknown Item")
	var amount = item_data.get("amount", 1)
	var item_mass = item_data.get("mass", 1.0)
	
	# Special handling for gold
	if item_name.to_lower() == "gold":
		add_gold(amount)
		return true
	
	# Check mass limit
	var new_item_mass = item_mass * amount
	if mass_manager and not mass_manager.can_add_mass(new_item_mass):
		var current = mass_manager.get_total_mass()
		var hard_max = mass_manager.hard_max_mass
		print("Cannot add item: Would exceed maximum carry mass (%.1f + %.1f = %.1f / %.1f)" % [current, new_item_mass, current + new_item_mass, hard_max])
		return false
	
	# Try to stack with existing items
	var remaining_amount = amount
	if stacking_manager and item_data.get("stackable", false):
		remaining_amount = stacking_manager.try_stack_item(item_data, amount)
		if remaining_amount < amount:
			# At least some items were stacked
			inventory_changed.emit()
			_update_mass_signals()
			
			if remaining_amount <= 0:
				return true  # All stacked successfully
	
	# Create new stacks for remaining amount
	if stacking_manager:
		if stacking_manager.create_new_stacks(item_data, remaining_amount, max_slots):
			inventory_changed.emit()
			_update_mass_signals()
			return true
		return false
	
	return false

func swap_items(from_slot: int, to_slot: int):
	"""Swap items between two inventory slots"""
	if from_slot < 0 or from_slot >= max_slots:
		return
	if to_slot < 0 or to_slot >= max_slots:
		return
	
	var temp = items[from_slot]
	items[from_slot] = items[to_slot]
	items[to_slot] = temp
	
	inventory_changed.emit()

func remove_item_at_slot(slot_index: int) -> bool:
	"""Remove item from inventory slot"""
	if slot_index >= 0 and slot_index < max_slots and items[slot_index] != null:
		items[slot_index] = null
		inventory_changed.emit()
		_update_mass_signals()
		return true
	return false

func drop_item_at_slot(slot_index: int):
	"""Drop item from inventory into the game world"""
	if slot_index < 0 or slot_index >= max_slots or items[slot_index] == null:
		return
	
	if not player_ref:
		print("Cannot drop item: No player reference")
		return
	
	var item = items[slot_index]
	
	# Use ItemDropper singleton to spawn the item
	if has_node("/root/ItemDropper"):
		var drop_position = ItemDropper.calculate_drop_position(player_ref)
		var spawned_item = ItemDropper.drop_item_in_world(item, drop_position)
		
		if spawned_item:
			# Emit signal for other systems
			item_dropped.emit(item, drop_position)
			
			# Remove from inventory
			items[slot_index] = null
			inventory_changed.emit()
			_update_mass_signals()
	else:
		push_warning("ItemDropper singleton not found - cannot drop item")

# ===== UTILITY =====

func set_player(player: Node3D):
	"""Set player reference"""
	player_ref = player

func get_item_at_slot(slot_index: int):
	"""Get item at specific slot"""
	if slot_index >= 0 and slot_index < items.size():
		return items[slot_index]
	return null

func get_items() -> Array:
	"""Get all items"""
	return items

func clear():
	"""Clear all items"""
	items.clear()
	inventory_changed.emit()
	_update_mass_signals()

func get_total_value() -> int:
	"""Calculate total value of all items"""
	var total: int = 0
	for item in items:
		if item != null and item.has("value"):
			var item_value = item.value
			var count = item.get("stack_count", 1)
			total += item_value * count
	return total
