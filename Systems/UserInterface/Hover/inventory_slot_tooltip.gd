extends Control
class_name InventorySlotTooltip

## Tooltip that appears when hovering over inventory slots
## Shows item name, level, quality, value, type, subtype, and mass

var tooltip_panel: PanelContainer = null
var item_label: RichTextLabel = null
var current_slot: Control = null  # Which slot we're showing tooltip for

func _ready():
	# Try to find existing nodes
	tooltip_panel = get_node_or_null("TooltipPanel")
	if tooltip_panel:
		var existing_label = tooltip_panel.get_node_or_null("ItemLabel")
		# Check if it's the right type
		if existing_label and existing_label is RichTextLabel:
			item_label = existing_label
		elif existing_label:
			# Old Label exists, need to replace it with RichTextLabel
			existing_label.queue_free()
			item_label = null
	
	# If nodes don't exist or need recreation, create them
	if not tooltip_panel or not item_label:
		if not tooltip_panel:
			_create_tooltip_ui()
		else:
			_create_label()
	
	# Start hidden
	if tooltip_panel:
		tooltip_panel.visible = false

func _create_label():
	"""Create just the RichTextLabel"""
	item_label = RichTextLabel.new()
	item_label.name = "ItemLabel"
	item_label.bbcode_enabled = true
	item_label.fit_content = true  # This makes it resize to content
	item_label.scroll_active = false
	item_label.custom_minimum_size = Vector2(220, 0)  # Minimum width increased to prevent wrapping
	item_label.add_theme_font_size_override("normal_font_size", 14)
	item_label.add_theme_color_override("default_color", Color.WHITE)
	tooltip_panel.add_child(item_label)

func _create_tooltip_ui():
	"""Create the tooltip UI programmatically"""
	# Create panel
	tooltip_panel = PanelContainer.new()
	tooltip_panel.name = "TooltipPanel"
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN  # Allow panel to shrink to content
	add_child(tooltip_panel)
	
	# Create RichTextLabel for BBCode support
	item_label = RichTextLabel.new()
	item_label.name = "ItemLabel"
	item_label.bbcode_enabled = true
	item_label.fit_content = true  # Auto-resize to content
	item_label.scroll_active = false
	item_label.custom_minimum_size = Vector2(220, 0)  # Minimum width increased to prevent wrapping
	item_label.add_theme_font_size_override("normal_font_size", 14)
	item_label.add_theme_color_override("default_color", Color.WHITE)
	tooltip_panel.add_child(item_label)
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.9)
	style.border_color = Color(1, 1, 1, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	tooltip_panel.add_theme_stylebox_override("panel", style)

func _process(_delta):
	"""Position tooltip near mouse cursor every frame when visible"""
	if not tooltip_panel:
		return
		
	if tooltip_panel.visible and current_slot:
		# Get mouse position
		var mouse_pos = get_viewport().get_mouse_position()
		
		# Offset tooltip so it doesn't cover the mouse
		var offset = Vector2(15, 15)
		tooltip_panel.global_position = mouse_pos + offset
		
		# Keep tooltip on screen
		var viewport_size = get_viewport_rect().size
		var tooltip_size = tooltip_panel.size
		
		# Check right edge
		if tooltip_panel.global_position.x + tooltip_size.x > viewport_size.x:
			tooltip_panel.global_position.x = mouse_pos.x - tooltip_size.x - 5
		
		# Check bottom edge  
		if tooltip_panel.global_position.y + tooltip_size.y > viewport_size.y:
			tooltip_panel.global_position.y = mouse_pos.y - tooltip_size.y - 5

func show_tooltip(slot: Control, item_data: Dictionary):
	"""Show tooltip for an inventory slot"""
	if not tooltip_panel or not item_label:
		return
		
	current_slot = slot
	
	# Build tooltip text with BBCode formatting
	var lines = []
	
	# Get item quality and its color
	var item_quality = item_data.get("item_quality", ItemQuality.Quality.NORMAL)
	var quality_color = ItemQuality.get_quality_color(item_quality)
	var quality_hex = quality_color.to_html(false)  # Get hex color without alpha
	
	# Item name with quality prefix (skip "Normal" quality)
	# Format: "Quality Item Name" or just "Item Name" if Normal
	var quality_name = ItemQuality.get_quality_name(item_quality)
	var name_text = item_data.get("name", "Unknown Item")
	if item_data.get("stackable", false) and item_data.get("stack_count", 1) > 1:
		name_text = "%s (x%d)" % [name_text, item_data.get("stack_count", 1)]
	
	# Add quality prefix only if not Normal
	if item_quality != ItemQuality.Quality.NORMAL:
		name_text = "%s %s" % [quality_name, name_text]
	
	lines.append("[center][font_size=22][color=#%s]%s[/color][/font_size][/center]" % [quality_hex, name_text])
	
	# BREAK 1: After item name
	lines.append("")
	
	# Subtype with weapon_hand (if applicable)
	# Format: "Subtype Hand" or just "Subtype"
	var item_subtype = item_data.get("item_subtype", "")
	if item_subtype != "":
		var subtype_text = item_subtype.capitalize()
		
		# Add weapon_hand if it exists and is a weapon
		if item_data.has("weapon_hand") and item_data.get("weapon_damage", 0) > 0:
			var weapon_hand = item_data.weapon_hand
			var hand_text = ""
			match weapon_hand:
				1:  # PRIMARY
					hand_text = "Primary"
				2:  # OFFHAND
					hand_text = "Offhand"
				3:  # TWOHAND
					hand_text = "Two-Handed"
				_:  # ANY (0)
					hand_text = "Any Hand"
			subtype_text = "%s (%s)" % [subtype_text, hand_text]
		
		lines.append("[center][color=darkgray]%s[/color][/center]" % subtype_text)
	
	# Weapon class combined with attack speed (only for weapons)
	# Format: "Slash - 1.2x (Fast)" or "Blunt" (if speed is 1.0)
	if item_data.has("weapon_class") and item_data.weapon_class != "" and item_data.get("weapon_damage", 0) > 0:
		var class_text = item_data.weapon_class.capitalize()
		
		# Add speed if available and not 1.0 (normal)
		if item_data.has("weapon_speed"):
			var speed = item_data.weapon_speed
			if speed != 1.0:  # Only show if not normal speed
				var speed_descriptor = ""
				if speed >= 1.5:
					speed_descriptor = "Very Fast"
				elif speed >= 1.2:
					speed_descriptor = "Fast"
				elif speed >= 1.0:
					speed_descriptor = "Normal"
				elif speed >= 0.8:
					speed_descriptor = "Slow"
				else:
					speed_descriptor = "Very Slow"
				
				class_text = "%s - %.1fx (%s)" % [class_text, speed, speed_descriptor]
		
		lines.append("[center][color=#bb88ff]%s[/color][/center]" % class_text)
	
	# Armor class - cyan color (only for armor)
	if item_data.has("armor_class") and item_data.armor_class != "":
		lines.append("[center][color=#88ddff]%s[/color][/center]" % item_data.armor_class.capitalize())
	
	# BREAK 2: After class info
	if (item_data.has("weapon_class") and item_data.weapon_class != "" and item_data.get("weapon_damage", 0) > 0) or (item_data.has("armor_class") and item_data.armor_class != ""):
		lines.append("")
	
	# Stat requirements - red, underlined (only show if requirements exist)
	var req_str = item_data.get("required_strength", 0)
	var req_dex = item_data.get("required_dexterity", 0)
	if req_str > 0 or req_dex > 0:
		var req_parts = []
		if req_str > 0:
			req_parts.append("Str: %d" % req_str)
		if req_dex > 0:
			req_parts.append("Dex: %d" % req_dex)
		lines.append("[center][u][color=#ff6b6b]Requires: %s[/color][/u][/center]" % ", ".join(req_parts))
	
	# Weapon damage - red color (only for weapons)
	if item_data.has("weapon_damage") and item_data.weapon_damage > 0:
		lines.append("[center][color=#ff6b6b]Damage: %d[/color][/center]" % item_data.weapon_damage)
	
	# Weapon range - orange color (only for weapons with range)
	if item_data.has("weapon_range") and item_data.get("weapon_damage", 0) > 0:
		lines.append("[center][color=#ffaa55]Range: %.1f[/color][/center]" % item_data.weapon_range)
	
	# Weapon block window - cyan color (only for weapons with block window)
	if item_data.has("weapon_block_rating") and item_data.get("weapon_damage", 0) > 0 and item_data.weapon_block_rating > 0.0:
		lines.append("[center][color=#77ffff]Block Rating: %.0f%%[/color][/center]" % (item_data.weapon_block_rating * 100))
	
	# Weapon parry window - light green color (only for weapons with parry window)
	if item_data.has("weapon_parry_window") and item_data.get("weapon_damage", 0) > 0 and item_data.weapon_parry_window > 0.0:
		lines.append("[center][color=#77ff77]Parry Window: %.1fs[/color][/center]" % item_data.weapon_parry_window)
	
	# Weapon crit chance - pink color (only for weapons with crit chance)
	if item_data.has("weapon_crit_chance") and item_data.get("weapon_damage", 0) > 0 and item_data.weapon_crit_chance > 0.0:
		var crit_pct = item_data.weapon_crit_chance * 100
		lines.append("[center][color=#ff77ff]Crit Chance: %.0f%%[/color][/center]" % crit_pct)
	
	# Weapon crit multiplier - magenta color (only for weapons with crit multiplier > 1)
	if item_data.has("weapon_crit_multiplier") and item_data.get("weapon_damage", 0) > 0 and item_data.weapon_crit_multiplier > 1.0:
		lines.append("[center][color=#ff55ff]Crit Multiplier: %.1fx[/color][/center]" % item_data.weapon_crit_multiplier)
	
	# Armor defense - blue color (only for armor)
	if item_data.has("armor_rating") and item_data.armor_rating > 0:
		lines.append("[center][color=#6bb6ff]Defense: %d[/color][/center]" % item_data.armor_rating)
	
	# BREAK 3: Before value/physical properties
	lines.append("")
	
	# Value (left) and Durability (right) - combined line
	var value = item_data.get("value", 0)
	var value_dur_line = "[color=gold]Value: %d[/color]" % value
	
	# Add durability on same line if applicable
	if item_data.has("durability") and not item_data.get("stackable", false):
		var durability_val = item_data.get("durability", 100)
		var durability_color = Color.GREEN
		if durability_val < 75:
			durability_color = Color.YELLOW
		if durability_val < 50:
			durability_color = Color.ORANGE
		if durability_val < 25:
			durability_color = Color.RED
		var durability_hex = durability_color.to_html(false)
		# Use fill_to to add padding between value and durability
		var padding = "          "  # Fixed spacing
		value_dur_line += "%s[color=#%s]Dur: %d/100[/color]" % [padding, durability_hex, durability_val]
	
	lines.append("[center]%s[/center]" % value_dur_line)
	
	# Mass (left) and Level (right) - combined line
	var mass = item_data.get("mass", 0.0)
	var item_level = item_data.get("item_level", 1)
	var padding2 = "          "  # Fixed spacing
	var mass_level_line = "[color=gray]Mass: %.1f[/color]%sLevel: %d" % [mass, padding2, item_level]
	lines.append("[center]%s[/center]" % mass_level_line)
	
	# Join lines with newlines
	var tooltip_text = "\n".join(lines)
	
	item_label.text = tooltip_text
	
	# Force the label to recalculate its size
	item_label.reset_size()
	
	# Wait one frame for RichTextLabel to calculate content size
	await get_tree().process_frame
	
	# Force panel to update to new label size
	tooltip_panel.reset_size()
	
	tooltip_panel.visible = true

func hide_tooltip():
	"""Hide the tooltip"""
	if tooltip_panel:
		tooltip_panel.visible = false
	current_slot = null
