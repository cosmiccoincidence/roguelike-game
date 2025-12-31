# shop_ui.gd
# Shop interface for buying and selling items
extends Control

# Node references
@onready var shop_panel: Panel = $ShopPanel
@onready var shop_grid: GridContainer = $ShopPanel/ShopGrid
@onready var shop_name_label: Label = $ShopNameLabel
@onready var shop_gold_label: Label = $ShopGoldLabel
@onready var slot_tooltip: Control = null  # Will be set from inventory UI

# Constants
const SHOP_SLOT_SCENE_PATH = "res://Systems/UserInterface/Inventory/shop_slot.tscn"

# Grid configuration
var slot_size: int = 64
var columns: int = 4
var rows: int = 6  # 24 slots for shop inventory

# Current shop data
var current_shop_data: ShopData = null

func _ready():
	# Start hidden
	hide()
	
	# Connect to ShopManager signals
	ShopManager.shop_opened.connect(_on_shop_opened)
	ShopManager.shop_closed.connect(_on_shop_closed)
	ShopManager.shop_gold_changed.connect(_on_shop_gold_changed)
	
	# Setup shop grid
	_setup_shop_grid()

func _setup_shop_grid():
	"""Create shop inventory slots"""
	var slot_scene = load(SHOP_SLOT_SCENE_PATH)
	if not slot_scene:
		push_error("Could not load shop slot scene from: ", SHOP_SLOT_SCENE_PATH)
		return
	
	shop_grid.columns = columns
	
	for i in range(columns * rows):
		var slot = slot_scene.instantiate()
		if not slot:
			continue
		
		slot.custom_minimum_size = Vector2(slot_size, slot_size)
		slot.slot_index = i
		slot.add_to_group("shop_slots")
		shop_grid.add_child(slot)
		
		# Set tooltip manager if available
		if slot.has_method("set_tooltip_manager") and slot_tooltip:
			slot.set_tooltip_manager(slot_tooltip)
		
		# Connect buy signal
		if slot.has_signal("item_purchased"):
			slot.item_purchased.connect(_on_item_purchased)

func set_tooltip_manager(tooltip: Control):
	"""Set the tooltip manager from inventory UI"""
	slot_tooltip = tooltip
	
	# Update all existing slots
	for slot in shop_grid.get_children():
		if slot.has_method("set_tooltip_manager"):
			slot.set_tooltip_manager(slot_tooltip)

func _on_shop_opened(shop_data: ShopData):
	"""Called when a shop is opened"""
	current_shop_data = shop_data
	
	# Update UI
	shop_name_label.text = shop_data.shop_name
	shop_gold_label.text = "Gold: %d" % shop_data.shop_gold
	
	# Populate shop inventory
	_populate_shop_inventory()
	
	# Show shop UI
	show()
	
	# Show mouse cursor for shopping
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_shop_closed():
	"""Called when shop is closed"""
	current_shop_data = null
	_clear_shop_inventory()
	hide()

func _on_shop_gold_changed(new_amount: int):
	"""Update shop gold display"""
	shop_gold_label.text = "Gold: %d" % new_amount

func _populate_shop_inventory():
	"""Fill shop slots with items from shop data"""
	if not current_shop_data:
		return
	
	var slots = shop_grid.get_children()
	var slot_index = 0
	
	# Clear all slots first
	for slot in slots:
		if slot.has_method("clear_item"):
			slot.clear_item()
	
	# Add shop items to slots
	for item in current_shop_data.shop_items:
		if slot_index >= slots.size():
			break
		
		# Check stock
		var stock = current_shop_data.get_stock(item)
		if stock <= 0:
			continue  # Skip out of stock items
		
		# Check level restrictions
		if not current_shop_data.is_item_level_valid(1):  # Shops sell level 1 items
			continue
		
		# Create item data for display
		var item_data = {
			"name": item.item_name,
			"icon": item.icon,
			"item_type": item.item_type,
			"item_subtype": item.item_subtype,
			"value": item.base_value,
			"buy_price": current_shop_data.get_buy_price(item),
			"stock": stock,
			"loot_item": item  # Store reference for purchasing
		}
		
		if slots[slot_index].has_method("set_item"):
			slots[slot_index].set_item(item_data)
		
		slot_index += 1

func _clear_shop_inventory():
	"""Clear all shop slots"""
	for slot in shop_grid.get_children():
		if slot.has_method("clear_item"):
			slot.clear_item()

func _on_item_purchased(item: LootItem, slot_index: int):
	"""Called when player buys an item"""
	var success = ShopManager.buy_item(item, Inventory)
	
	if success:
		# Refresh shop inventory to update stock
		_populate_shop_inventory()
	else:
		print("[ShopUI] Purchase failed")

func _input(event):
	"""Handle closing shop with Escape or Tab"""
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("toggle_inventory"):
		ShopManager.close_shop()
		
		# Hide mouse if inventory is also closing
		if not get_tree().get_first_node_in_group("inventory_ui").visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
