# loot_item.gd
# Resource definition for loot items - Designer sets base values only
class_name LootItem
extends Resource

# ===== BASIC INFO =====
@export var item_name: String = "Item"
@export var icon: Texture2D
@export var item_scene: PackedScene  # The actual item scene to spawn

# ===== CLASSIFICATION =====
@export var item_type: String = "misc"  # weapon, armor, consumable, material, accessory, etc.
@export var item_subtype: String = ""  # sword, axe, helmet, boots, ring, amulet, etc.
@export var item_tags: Array[String] = []  # Tags for filtering

# ===== PHYSICAL PROPERTIES =====
@export var mass: float = 1.0
@export var durability: int = 100  # 100 = new, 0 = broken
@export var base_value: int = 10  # Base value before level/quality modifiers
@export var stackable: bool = false
@export var max_stack_size: int = 1

# ===== STAT REQUIREMENTS =====
@export_group("Stat Requirements")
@export var required_strength: int = 0
@export var required_dexterity: int = 0
@export var required_fortitude: int = 0

# ===== WEAPON STATS (Base values - scaled by level/quality) =====
@export_group("Weapon Stats")
@export var weapon_damage: int = 0  # Base damage (will be scaled)

# Weapon damage type
enum DamageType {
	PHYSICAL,  # Blocked by armor
	MAGIC,     # Blocked by magic resist
	FIRE,      # Blocked by fire resist
	FROST,     # Blocked by frost resist
	STATIC,    # Blocked by static resist
	POISON     # Blocked by poison resist
}
@export var damage_type: DamageType = DamageType.PHYSICAL

# Physical damage subtype (only used if damage_type is PHYSICAL)
enum PhysicalDamageType {
	SLASH,   # Normal armor penetration
	PIERCE,  # Ignores 10% armor
	BLUNT    # Ignores 5% armor, +20% vs shields
}
@export var physical_damage_type: PhysicalDamageType = PhysicalDamageType.SLASH

@export var weapon_range: float = 1.5
@export var weapon_speed: float = 1.0
@export_range(0.0, 1.0) var weapon_crit_chance: float = 0.0
@export var weapon_crit_multiplier: float = 1.5
@export_range(0.0, 1.0) var weapon_block_rating: float = 0.0
@export var weapon_parry_window: float = 0.0

# Weapon hand restrictions
enum WeaponHand {
	ANY,        # Can equip in either hand
	PRIMARY,    # Left hand only (slots 10, 14)
	OFFHAND,    # Right hand only (slots 11, 15)
	TWOHAND     # Takes both hands
}
@export var weapon_hand: WeaponHand = WeaponHand.ANY

# ===== ARMOR STATS (Base values - scaled by level/quality) =====
@export_group("Armor Stats")
@export var armor: int = 0  # Base armor rating (will be scaled)

# Armor type affects resistance modifiers
enum ArmorType {
	CLOTH,    # Low armor, high elemental resist
	LEATHER,  # Balanced
	MAIL,     # Medium armor, medium resist
	PLATE     # High armor, low/negative elemental resist
}
@export var armor_type: ArmorType = ArmorType.LEATHER

# ===== STACKABLE SETTINGS =====
@export_group("Stackable Settings")
@export var min_drop_amount: int = 1
@export var max_drop_amount: int = 1
@export var scaled_quantity: bool = false  # Scale by source level

# ===== LOOT TABLE PROPERTIES =====
@export_group("Loot Table")
@export var item_drop_weight: float = 1.0  # Relative drop chance
@export var min_quantity: int = 1  # For loot table
@export var max_quantity: int = 1
@export var min_drop_level: int = 1  # Minimum source level for this item to drop
@export var max_drop_level: int = 100  # Maximum source level

# NOTE: Bonus stats (resistances, stat bonuses, regen, etc.) are NOT set here!
# They are randomly rolled by the stat rollers based on item_quality and item_level
# This keeps the designer interface simple and clean
