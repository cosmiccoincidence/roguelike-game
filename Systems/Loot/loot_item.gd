# res://resources/loot_item.gd
extends Resource
class_name LootItem

@export var item_name: String = ""
@export var item_scene: PackedScene
@export var icon: Texture2D
@export var item_type: String = ""  # weapon, armor, helmet, consumable, material, junk, gold, etc.

# Base item properties (before level/quality scaling)
@export_group("Base Properties")
@export var base_value: int = 10
@export var mass: float = 1.0
@export var stackable: bool = false
@export var max_stack_size: int = 99

# Drop properties
@export_group("Drop Properties")
@export var base_weight: float = 1.0  # How common this item is in the loot pool
@export var item_tags: Array[String] = []  # Additional filters like ["rare", "quest"]
