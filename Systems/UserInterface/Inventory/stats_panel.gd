# stats_panel.gd
# Displays player stats in the inventory UI
extends PanelContainer

# Node references
@onready var hero_name_label: Label = $"../HeroNameLabel"  # Sibling label node

# Player reference
var player_ref: CharacterBody3D = null
var stats_container: VBoxContainer = null

func _ready():
	# Setup panel styling
	_setup_panel_style()
	_setup_stats_panel()
	
	# Setup hero name label styling
	if hero_name_label:
		hero_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hero_name_label.add_theme_font_size_override("font_size", 18)
		hero_name_label.add_theme_color_override("font_color", Color.GOLD)

func set_player_reference(player: CharacterBody3D):
	"""Set the player reference and update display"""
	player_ref = player
	if player_ref:
		_update_hero_name()
		_update_stats_display()
		
		# Connect to stats updated signal
		var stats = player_ref.get_node_or_null("PlayerStats")
		if stats and stats.has_signal("stats_updated"):
			if not stats.stats_updated.is_connected(_on_stats_updated):
				stats.stats_updated.connect(_on_stats_updated)

func _on_stats_updated():
	"""Called when player stats are recalculated"""
	_update_stats_display()

func _update_hero_name():
	"""Update hero name from player"""
	if not player_ref or not hero_name_label:
		return
	
	var hero_name = "Hero"  # Default
	if "hero_name" in player_ref:
		hero_name = player_ref.hero_name
	
	hero_name_label.text = hero_name

func _setup_panel_style():
	"""Setup panel background and border"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.border_color = Color(0.5, 0.5, 0.5, 1.0)  # Grey border
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style)

func _setup_stats_panel():
	"""Create labels in the stats panel"""
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	# Create container
	stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	add_child(stats_container)
	
	# Core Stats Section (6-stat system)
	_create_section_label(stats_container, "Core Stats")
	_create_stat_label(stats_container, "StrengthLabel", "Strength: 0", 16, Color.ORANGE_RED)
	_create_stat_label(stats_container, "DexterityLabel", "Dexterity: 0", 16, Color.YELLOW)
	_create_stat_label(stats_container, "FortitudeLabel", "Fortitude: 0", 16, Color.SLATE_GRAY)
	_create_stat_label(stats_container, "VitalityLabel", "Vitality: 0", 16, Color.INDIAN_RED)
	_create_stat_label(stats_container, "AgilityLabel", "Agility: 0", 16, Color.LIGHT_GREEN)
	_create_stat_label(stats_container, "ArcaneLabel", "Arcane: 0", 16, Color.MEDIUM_PURPLE)
	_create_stat_label(stats_container, "LuckLabel", "Luck: 0", 16, Color(0.5, 1.0, 0.5))
	
	_create_spacer(stats_container, 10)
	
	# Resources Section
	_create_section_label(stats_container, "Resources")
	_create_stat_label(stats_container, "MaxHealthLabel", "Max Health: 0", 14)
	_create_stat_label(stats_container, "HealthRegenLabel", "HP Regen: 0 / 0s", 14)
	_create_stat_label(stats_container, "MaxStaminaLabel", "Max Stamina: 0", 14)
	_create_stat_label(stats_container, "StaminaRegenLabel", "Stamina Regen: 0 / 0s", 14)
	_create_stat_label(stats_container, "MaxManaLabel", "Max Mana: 0", 14)
	_create_stat_label(stats_container, "ManaRegenLabel", "Mana Regen: 0 / 0s", 14)
	
	_create_spacer(stats_container, 10)
	
	# Defense Section
	_create_section_label(stats_container, "Defense")
	_create_stat_label(stats_container, "ArmorLabel", "Armor: 0", 14)
	_create_stat_label(stats_container, "FireResLabel", "Fire Resist: 0%", 14)
	_create_stat_label(stats_container, "FrostResLabel", "Frost Resist: 0%", 14)
	_create_stat_label(stats_container, "StaticResLabel", "Static Resist: 0%", 14)
	_create_stat_label(stats_container, "PoisonResLabel", "Poison Resist: 0%", 14)
	
	_create_spacer(stats_container, 10)
	
	# Combat Stats Section (Weapon-based)
	_create_section_label(stats_container, "Combat")
	_create_stat_label(stats_container, "WeaponDamageLabel", "Damage: --", 14, Color("#ff6b6b"))
	_create_stat_label(stats_container, "DamageTypeLabel", "Type: Physical", 14, Color("#ffaa55"))
	_create_stat_label(stats_container, "AttackSpeedLabel", "Attack Speed: 1.0x", 14, Color("#77ff77"))
	_create_stat_label(stats_container, "AttackRangeLabel", "Range: --", 14, Color("#77ffff"))
	_create_stat_label(stats_container, "CritChanceLabel", "Crit Chance: 0%", 14, Color("#ff77ff"))
	_create_stat_label(stats_container, "CritDamageLabel", "Crit Damage: 1.5x", 14, Color("#ff55ff"))
	_create_stat_label(stats_container, "BlockRatingLabel", "Block Rating: 0%", 14, Color("#5599ff"))
	_create_stat_label(stats_container, "ParryWindowLabel", "Parry Window: 0.0s", 14, Color("#5599ff"))

func _create_section_label(parent: VBoxContainer, text: String):
	"""Create a centered section header label"""
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.ORANGE)
	parent.add_child(label)

func _create_stat_label(parent: VBoxContainer, label_name: String, text: String, font_size: int = 14, color: Color = Color.WHITE):
	"""Create a stat label"""
	var label = Label.new()
	label.name = label_name
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _create_spacer(parent: VBoxContainer, height: int):
	"""Create vertical spacer"""
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	parent.add_child(spacer)

func _update_stats_display():
	"""Update the stats panel with current player stats"""
	if not player_ref or not stats_container:
		return
	
	# Get the stats component
	var stats = player_ref.get_node_or_null("PlayerStats")
	
	if not stats:
		# Fallback - try to display what we can from old structure
		_update_label("StrengthLabel", "Strength: %d" % player_ref.get("strength"))
		_update_label("DexterityLabel", "Dexterity: %d" % player_ref.get("dexterity"))
		_update_label("FortitudeLabel", "Fortitude: N/A")
		_update_label("VitalityLabel", "Vitality: N/A")
		_update_label("AgilityLabel", "Agility: N/A")
		_update_label("ArcaneLabel", "Arcane: N/A")
		_update_luck_label_fallback()
		return
	
	# Core Stats (6-stat system)
	_update_label("StrengthLabel", "Strength: %d" % stats.strength)
	_update_label("DexterityLabel", "Dexterity: %d" % stats.dexterity)
	_update_label("FortitudeLabel", "Fortitude: %d" % stats.fortitude)
	_update_label("VitalityLabel", "Vitality: %d" % stats.vitality)
	_update_label("AgilityLabel", "Agility: %d" % stats.agility)
	_update_label("ArcaneLabel", "Arcane: %d" % stats.arcane)
	_update_luck_label(stats)
	
	# Resources
	_update_label("MaxHealthLabel", "Max Health: %d" % stats.max_health)
	_update_label("HealthRegenLabel", "HP Regen: %.1f / %.0fs" % [stats.health_regen_rate, stats.health_regen_interval])
	_update_label("MaxStaminaLabel", "Max Stamina: %d" % int(stats.max_stamina))
	_update_label("StaminaRegenLabel", "Stamina Regen: %.1f / %.1fs" % [stats.stamina_regen_rate, stats.stamina_regen_interval])
	_update_label("MaxManaLabel", "Max Mana: %d" % int(stats.max_mana))
	_update_label("ManaRegenLabel", "Mana Regen: %.1f / %.1fs" % [stats.mana_regen_rate, stats.mana_regen_interval])
	
	# Defense
	_update_label("ArmorLabel", "Armor: %d" % stats.armor)
	_update_label("FireResLabel", "Fire Resist: %.0f%%" % (stats.fire_resistance * 100))
	_update_label("FrostResLabel", "Frost Resist: %.0f%%" % (stats.frost_resistance * 100))
	_update_label("StaticResLabel", "Static Resist: %.0f%%" % (stats.static_resistance * 100))
	_update_label("PoisonResLabel", "Poison Resist: %.0f%%" % (stats.poison_resistance * 100))
	
	# Combat (from equipped weapon)
	_update_combat_stats()

func _update_label(label_name: String, text: String):
	"""Helper to update a label's text"""
	if not stats_container:
		return
	var label = stats_container.get_node_or_null(label_name)
	if label:
		label.text = text

func _update_combat_stats():
	"""Update combat stats from equipped weapon"""
	if not player_ref:
		return
	
	# Get equipment stat applier from player
	var stat_applier = player_ref.get_node_or_null("EquipmentStatApplier")
	if not stat_applier:
		_update_label("WeaponDamageLabel", "Damage: --")
		_update_label("DamageTypeLabel", "Type: --")
		_update_label("AttackSpeedLabel", "Attack Speed: --")
		_update_label("AttackRangeLabel", "Range: --")
		_update_label("CritChanceLabel", "Crit Chance: --")
		_update_label("CritDamageLabel", "Crit Damage: --")
		_update_label("BlockRatingLabel", "Block Rating: --")
		_update_label("ParryWindowLabel", "Parry Window: --")
		return
	
	# Get current weapon stats
	var weapon_stats = stat_applier.get_current_weapon_stats()
	
	if not weapon_stats.has_weapon:
		_update_label("WeaponDamageLabel", "Damage: No Weapon")
		_update_label("DamageTypeLabel", "Type: --")
		_update_label("AttackSpeedLabel", "Attack Speed: --")
		_update_label("AttackRangeLabel", "Range: --")
		_update_label("CritChanceLabel", "Crit Chance: --")
		_update_label("CritDamageLabel", "Crit Damage: --")
		_update_label("BlockRatingLabel", "Block Rating: --")
		_update_label("ParryWindowLabel", "Parry Window: --")
		return
	
	# Get player stats for bonuses
	var stats = player_ref.get_node_or_null("PlayerStats")
	
	# Damage
	_update_label("WeaponDamageLabel", "Damage: %d" % weapon_stats.damage)
	
	# Damage type with color
	var damage_type = weapon_stats.damage_type.capitalize()
	_update_label("DamageTypeLabel", "Type: %s" % damage_type)
	
	# Attack speed (weapon speed × speed bonuses)
	_update_label("AttackSpeedLabel", "Attack Speed: %.2fx" % weapon_stats.speed)
	
	# Range
	_update_label("AttackRangeLabel", "Range: %.1f" % weapon_stats.range)
	
	# Crit chance (weapon + dexterity + gear bonuses)
	var total_crit = weapon_stats.crit_chance
	if total_crit > 0 and stats:
		total_crit += stats.dexterity * 0.01  # 1% per dex
	
	if total_crit > 0:
		_update_label("CritChanceLabel", "Crit Chance: %.1f%%" % (total_crit * 100))
	else:
		_update_label("CritChanceLabel", "Crit Chance: --")
	
	# Crit damage (weapon multiplier + dexterity + gear bonuses)
	var total_crit_mult = weapon_stats.crit_multiplier
	if total_crit_mult > 0 and stats:
		total_crit_mult += stats.dexterity * 0.02  # 2% per dex
	
	if total_crit_mult > 0:
		_update_label("CritDamageLabel", "Crit Damage: %.2fx" % total_crit_mult)
	else:
		_update_label("CritDamageLabel", "Crit Damage: --")
	
	# Block rating
	if weapon_stats.block_rating > 0:
		_update_label("BlockRatingLabel", "Block Rating: %.0f%%" % (weapon_stats.block_rating * 100))
	else:
		_update_label("BlockRatingLabel", "Block Rating: --")
	
	# Parry window
	if weapon_stats.parry_window > 0:
		_update_label("ParryWindowLabel", "Parry Window: %.2fs" % weapon_stats.parry_window)
	else:
		_update_label("ParryWindowLabel", "Parry Window: --")

func _update_luck_label(stats: Node):
	"""Update luck label with color based on value"""
	if not stats_container:
		return
	var luck_label = stats_container.get_node_or_null("LuckLabel")
	if not luck_label:
		return
	
	var luck_value = stats.luck
	
	# Color based on positive/negative luck
	if luck_value > 0:
		luck_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))  # Green
	elif luck_value < 0:
		luck_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))  # Red
	else:
		luck_label.add_theme_color_override("font_color", Color.WHITE)  # White
	
	luck_label.text = "Luck: %.1f" % luck_value

func _update_luck_label_fallback():
	"""Update luck label for old structure"""
	if not stats_container:
		return
	var luck_label = stats_container.get_node_or_null("LuckLabel")
	if not luck_label or not player_ref:
		return
	
	var luck_value = player_ref.get("luck")
	if luck_value == null:
		luck_value = 0.0
	
	# Color based on positive/negative luck
	if luck_value > 0:
		luck_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	elif luck_value < 0:
		luck_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	else:
		luck_label.add_theme_color_override("font_color", Color.WHITE)
	
	luck_label.text = "Luck: %.1f" % luck_value

func _process(_delta):
	"""Update stats every frame"""
	# Only update if we have a valid player reference
	if player_ref and is_instance_valid(player_ref) and visible:
		# Check if player is dying (might not exist on all player versions)
		var is_dying = player_ref.get("is_dying")
		if is_dying == null or not is_dying:
			_update_stats_display()
	
	# Update hero name position to stay centered above panel
	_update_hero_name_position()

func _update_hero_name_position():
	"""Position hero name label centered above the stats panel"""
	if not hero_name_label:
		return
	
	# Get panel position and size
	var panel_pos = global_position
	var panel_size = size
	
	# Calculate centered position above panel
	var label_x = panel_pos.x + (panel_size.x / 2) - (hero_name_label.size.x / 2)
	var label_y = panel_pos.y - hero_name_label.size.y - 5  # 5px gap above panel
	
	hero_name_label.global_position = Vector2(label_x, label_y)
