# stat_requirement_checker.gd
# Utility for checking if player meets item stat requirements
class_name StatRequirementChecker
extends RefCounted

static func can_equip(item_data: Dictionary, player: Node) -> Dictionary:
	"""
	Check if player meets stat requirements to equip item
	Returns: {can_equip: bool, reason: String}
	"""
	if not player:
		return {"can_equip": false, "reason": "No player found"}
	
	# Check strength requirement
	var req_str = item_data.get("required_strength", 0)
	if req_str > 0:
		var player_str = player.get("strength")
		if player_str == null:
			return {"can_equip": false, "reason": "Player missing strength stat"}
		if player_str < req_str:
			return {
				"can_equip": false,
				"reason": "Requires %d Strength (you have %d)" % [req_str, player_str]
			}
	
	# Check dexterity requirement
	var req_dex = item_data.get("required_dexterity", 0)
	if req_dex > 0:
		var player_dex = player.get("dexterity")
		if player_dex == null:
			return {"can_equip": false, "reason": "Player missing dexterity stat"}
		if player_dex < req_dex:
			return {
				"can_equip": false,
				"reason": "Requires %d Dexterity (you have %d)" % [req_dex, player_dex]
			}
	
	# All requirements met
	return {"can_equip": true, "reason": ""}

static func get_requirement_text(item_data: Dictionary) -> String:
	"""Get formatted requirement text for tooltip"""
	var reqs = []
	
	var req_str = item_data.get("required_strength", 0)
	if req_str > 0:
		reqs.append("Str: %d" % req_str)
	
	var req_dex = item_data.get("required_dexterity", 0)
	if req_dex > 0:
		reqs.append("Dex: %d" % req_dex)
	
	if reqs.size() > 0:
		return "Requires: " + ", ".join(reqs)
	return ""
