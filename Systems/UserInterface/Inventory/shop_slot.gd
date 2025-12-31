# shop_slot.gd
# Individual slot in the shop inventory grid
extends Panel

@onready var icon_rect: TextureRect = $TextureRect
@onready var stock_label: Label = $Label

var item_data: Dictionary = {}
var slot_index: int = 0
var tooltip_manager: Control = null

signal item_purchased(item: LootItem, slot_index: int)

func _ready():
	# Setup
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Create UI elements if they don't exist
	if not icon_rect:
		_create_icon()
	if not stock_label:
		_create_stock_label()
	
	clear_item()

func _create_icon():
	"""Create icon texture rect"""
	icon_rect = TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.anchor_right = 1.0
	icon_rect.anchor_bottom = 1.0
	add_child(icon_rect)

func _create_stock_label():
	"""Create stock count label"""
	stock_label = Label.new()
	stock_label.name = "StockLabel"
	stock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stock_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	stock_label.anchor_right = 1.0
	stock_label.anchor_bottom = 1.0
	stock_label.offset_left = -25
	stock_label.offset_top = -20
	stock_label.add_theme_font_size_override("font_size", 12)
	stock_label.add_theme_color_override("font_color", Color.YELLOW)
	stock_label.add_theme_color_override("font_outline_color", Color.BLACK)
	stock_label.add_theme_constant_override("outline_size", 2)
	add_child(stock_label)

func set_item(data: Dictionary):
	"""Set item data and display it"""
	item_data = data
	
	# Set icon
	if data.has("icon") and data.icon:
		icon_rect.texture = data.icon
		icon_rect.visible = true
	else:
		icon_rect.visible = false
	
	# Set stock count
	if data.has("stock"):
		stock_label.text = "x%d" % data.stock
		stock_label.visible = true
	else:
		stock_label.visible = false

func clear_item():
	"""Clear the slot"""
	item_data = {}
	icon_rect.texture = null
	icon_rect.visible = false
	stock_label.visible = false

func set_tooltip_manager(manager: Control):
	"""Set the tooltip manager"""
	tooltip_manager = manager

func _on_mouse_entered():
	"""Show tooltip when hovering"""
	if tooltip_manager and not item_data.is_empty():
		# Build tooltip data with buy price
		var tooltip_data = item_data.duplicate()
		tooltip_data["is_shop_item"] = true  # Flag for tooltip to show buy price
		
		if tooltip_manager.has_method("show_tooltip"):
			tooltip_manager.show_tooltip(self, tooltip_data)

func _on_mouse_exited():
	"""Hide tooltip when not hovering"""
	if tooltip_manager and tooltip_manager.has_method("hide_tooltip"):
		tooltip_manager.hide_tooltip()

func _gui_input(event):
	"""Handle buying with click or CTRL+click"""
	if item_data.is_empty():
		return
	
	# Left click to buy
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Check for CTRL modifier (optional for now)
			var is_ctrl_held = event.ctrl_pressed
			
			# Attempt purchase
			if item_data.has("loot_item"):
				item_purchased.emit(item_data.loot_item, slot_index)


func _on_gui_input(event: InputEvent) -> void:
	pass # Replace with function body.
