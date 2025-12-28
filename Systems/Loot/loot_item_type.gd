# res://resources/loot_item_type.gd
extends Resource
class_name LootItemType

@export var type_name: String = ""  # e.g., "weapon", "armor", "consumable", "material"
@export var display_name: String = ""  # e.g., "Weapon", "Armor", "Consumable"
@export var drop_weight: float = 1.0  # How common this type is in drops
@export var icon: Texture2D  # Optional icon for this item type
@export var description: String = ""  # Optional description
