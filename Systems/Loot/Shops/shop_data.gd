# shop_data.gd
# Resource that defines a shop's inventory and configuration
class_name ShopData
extends Resource

@export var shop_name: String = "General Store"
@export var shop_gold: int = 1000  # How much gold the shop has
@export var shop_items: Array[LootItem] = []  # Items the shop sells

# Price modifiers
@export var buy_price_multiplier: float = 1.25  # Player buys at 125% of base value
@export var sell_price_multiplier: float = 0.75  # Player sells at 75% of base value

# Stock system
@export var item_stock: Dictionary = {}  # LootItem -> stock count (0 = out of stock)

# Item level restrictions
@export var max_item_level: int = 99  # Don't show items above this level
@export var min_item_level: int = 1   # Don't show items below this level

# Markup/Markdown system (random price variations)
@export var price_variation_chance: float = 0.3  # 30% chance for price variation
@export var markup_range: Vector2 = Vector2(1.1, 1.5)  # 110% to 150% for marked up items
@export var markdown_range: Vector2 = Vector2(0.7, 0.9)  # 70% to 90% for marked down items

# Special pricing per item (overrides default multipliers)
var special_prices: Dictionary = {}  # LootItem -> float multiplier

func _init():
	# Initialize stock for all items
	_initialize_stock()

func _initialize_stock():
	"""Set initial stock for all items"""
	for item in shop_items:
		if not item_stock.has(item):
			# Random stock between 1-5 for each item
			item_stock[item] = randi_range(1, 5)
	
	# Apply random price variations
	_apply_price_variations()

func _apply_price_variations():
	"""Randomly mark up or mark down some items"""
	for item in shop_items:
		if randf() < price_variation_chance:
			# Randomly choose markup or markdown
			if randf() < 0.5:
				# Markup
				special_prices[item] = randf_range(markup_range.x, markup_range.y)
			else:
				# Markdown
				special_prices[item] = randf_range(markdown_range.x, markdown_range.y)

func get_buy_price(item: LootItem) -> int:
	"""Get the price the player pays to buy this item"""
	var base_price = item.base_value
	var multiplier = buy_price_multiplier
	
	# Check for special pricing
	if special_prices.has(item):
		multiplier = special_prices[item]
	
	return int(base_price * multiplier)

func get_sell_price(item_value: int) -> int:
	"""Get the price the shop pays when player sells an item"""
	return int(item_value * sell_price_multiplier)

func has_stock(item: LootItem) -> bool:
	"""Check if item is in stock"""
	return item_stock.get(item, 0) > 0

func get_stock(item: LootItem) -> int:
	"""Get stock count for an item"""
	return item_stock.get(item, 0)

func remove_stock(item: LootItem, amount: int = 1) -> bool:
	"""Remove stock when player buys"""
	if has_stock(item):
		item_stock[item] = max(0, item_stock[item] - amount)
		return true
	return false

func add_stock(item: LootItem, amount: int = 1):
	"""Add stock when player sells"""
	if item_stock.has(item):
		item_stock[item] += amount
	else:
		item_stock[item] = amount

func can_afford_to_buy_from_player(price: int) -> bool:
	"""Check if shop has enough gold to buy from player"""
	return shop_gold >= price

func is_item_level_valid(item_level: int) -> bool:
	"""Check if item level is within shop's range"""
	return item_level >= min_item_level and item_level <= max_item_level
