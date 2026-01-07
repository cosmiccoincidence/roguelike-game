# inventory_mass.gd
# Handles mass tracking and encumbrance for the inventory system
extends Node

var inventory_ref: Node = null  # Reference to main inventory

# Mass limits
var soft_max_mass: float = 20.0
var hard_max_mass: float = 22.0  # 110% of soft max

signal mass_changed(current_mass, max_mass)
signal encumbered_status_changed(is_encumbered)

func _ready():
	inventory_ref = get_parent()
	hard_max_mass = soft_max_mass * 1.1

func initialize(inventory_node: Node):
	"""Called by main inventory to set reference"""
	inventory_ref = inventory_node
	hard_max_mass = soft_max_mass * 1.1

func get_total_mass() -> float:
	"""Calculate total mass from inventory and equipped items"""
	var total: float = 0.0
	
	if not inventory_ref:
		return 0.0
	
	# Add mass from inventory items
	var items = inventory_ref.get_items()
	for item in items:
		if item != null and item.has("mass"):
			var item_mass = item.mass
			var count = item.get("stack_count", 1)
			total += item_mass * count
	
	# Add mass from equipped items
	if has_node("/root/Equipment"):
		var equipped_items = Equipment.get_items()
		for item in equipped_items:
			if item != null and item.has("mass"):
				var item_mass = item.mass
				var count = item.get("stack_count", 1)
				total += item_mass * count
	
	return total

func is_encumbered() -> bool:
	"""Check if player is over the soft mass limit"""
	return get_total_mass() > soft_max_mass

func can_add_mass(additional_mass: float) -> bool:
	"""Check if adding this mass would exceed hard limit"""
	var current_mass = get_total_mass()
	var projected_mass = current_mass + additional_mass
	return projected_mass <= hard_max_mass

func update_signals():
	"""Update all mass-related signals"""
	var current_mass = get_total_mass()
	mass_changed.emit(current_mass, soft_max_mass)
	encumbered_status_changed.emit(is_encumbered())
