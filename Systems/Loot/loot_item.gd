# loot_item.gd
# Resource definition for loot items
class_name LootItem
extends Resource

# Basic item info
@export var item_name: String = "Item"
@export var icon: Texture2D
@export var item_scene: PackedScene  # The actual item scene to spawn

# Item classification
@export var item_type: String = "misc"  # weapon, armor, consumable, material, etc.
@export var item_subtype: String = ""  # sword, axe, helmet, boots, health_potion, etc.
@export var item_tags: Array[String] = []  # Tags for filtering (e.g., ["common", "starter", "metal"])

# Physical properties
@export var mass: float = 1.0
@export var base_value: int = 10  # Base value before level/quality modifiers
@export var stackable: bool = false
@export var max_stack_size: int = 1

# Stackable item settings
@export var min_drop_amount: int = 1  # Minimum stack size when dropped
@export var max_drop_amount: int = 1  # Maximum stack size when dropped
@export var scaled_quantity: bool = false  # Scale drop amount by enemy level

# Loot table properties
@export var item_drop_weight: float = 1.0  # How common this specific item is (higher = more common)
@export var min_quantity: int = 1  # For stackable items
@export var max_quantity: int = 1  # For stackable items
