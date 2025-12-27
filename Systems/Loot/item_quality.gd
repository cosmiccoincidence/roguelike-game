# res://systems/item_quality.gd
extends Node
class_name ItemQuality

enum Quality {
	DAMAGED,
	NORMAL,
	FINE
}

# Quality properties
const QUALITY_DATA = {
	Quality.DAMAGED: {
		"name": "Damaged",
		"color": Color(0.6, 0.6, 0.6),  # Grey
		"value_mod": 0.5
	},
	Quality.NORMAL: {
		"name": "Normal",
		"color": Color(1.0, 1.0, 1.0),  # White
		"value_mod": 1.0
	},
	Quality.FINE: {
		"name": "Fine",
		"color": Color(1.0, 0.6, 0.0),  # Orange
		"value_mod": 1.5
	}
}

# Roll item quality based on player luck
static func roll_quality(player_luck: float) -> Quality:
	# Base probabilities (luck = 0)
	# Damaged: 20%, Normal: 60%, Fine: 20%
	
	# Luck shifts probabilities:
	# Each point of luck shifts 2% from adjacent qualities
	
	var damaged_chance = 20.0
	var normal_chance = 60.0
	var fine_chance = 20.0
	
	# Apply luck modifier (each point = 2% shift)
	var luck_shift = player_luck * 2.0
	
	if luck_shift > 0:
		# Positive luck: shift from damaged->normal->fine
		var shift_from_damaged = min(luck_shift, damaged_chance)
		damaged_chance -= shift_from_damaged
		normal_chance += shift_from_damaged
		
		var remaining_shift = luck_shift - shift_from_damaged
		var shift_from_normal = min(remaining_shift, normal_chance * 0.5)  # Take up to half of normal
		normal_chance -= shift_from_normal
		fine_chance += shift_from_normal
	elif luck_shift < 0:
		# Negative luck: shift from fine->normal->damaged
		var shift_from_fine = min(abs(luck_shift), fine_chance)
		fine_chance -= shift_from_fine
		normal_chance += shift_from_fine
		
		var remaining_shift = abs(luck_shift) - shift_from_fine
		var shift_from_normal = min(remaining_shift, normal_chance * 0.5)
		normal_chance -= shift_from_normal
		damaged_chance += shift_from_normal
	
	# Ensure values are clamped
	damaged_chance = clamp(damaged_chance, 0.0, 100.0)
	normal_chance = clamp(normal_chance, 0.0, 100.0)
	fine_chance = clamp(fine_chance, 0.0, 100.0)
	
	# Roll
	var roll = randf() * 100.0
	
	if roll < damaged_chance:
		return Quality.DAMAGED
	elif roll < damaged_chance + normal_chance:
		return Quality.NORMAL
	else:
		return Quality.FINE

static func get_quality_name(quality: Quality) -> String:
	return QUALITY_DATA[quality]["name"]

static func get_quality_color(quality: Quality) -> Color:
	return QUALITY_DATA[quality]["color"]

static func get_value_modifier(quality: Quality) -> float:
	return QUALITY_DATA[quality]["value_mod"]
