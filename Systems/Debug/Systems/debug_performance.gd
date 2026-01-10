# debug_performance.gd
# Debug subsystem for performance monitoring
extends Node

var performance_stats_panel: Node = null

func _ready():
	# Wait a frame for the scene to fully load
	await get_tree().process_frame
	_find_performance_panel()

func _find_performance_panel():
	"""Find the performance stats panel in the scene"""
	# Method 1: Try to find by group
	var canvas = get_tree().get_first_node_in_group("debug_stats_canvas")
	if canvas:
		performance_stats_panel = canvas.get_node_or_null("PanelContainer")
	
	# Method 2: Try to find directly by group
	if not performance_stats_panel:
		performance_stats_panel = get_tree().get_first_node_in_group("performance_stats")
	
	# Method 3: Search for DebugStatsCanvas by name
	if not performance_stats_panel:
		var root = get_tree().root
		performance_stats_panel = _find_node_recursive(root, "DebugStatsCanvas")
		if performance_stats_panel:
			# Get the PanelContainer child
			for child in performance_stats_panel.get_children():
				if child is PanelContainer:
					performance_stats_panel = child
					break
	
	# Method 4: Search for any PanelContainer with performance_stats_hud script
	if not performance_stats_panel:
		performance_stats_panel = _find_performance_stats_node(get_tree().root)
	
	if performance_stats_panel:
		print("✅ Performance stats panel found: %s" % performance_stats_panel.get_path())
	else:
		print("⚠️  Performance stats panel not found. Make sure DebugStatsCanvas/PanelContainer exists in your HUD scene.")

func _find_node_recursive(node: Node, node_name: String) -> Node:
	"""Recursively search for a node by name"""
	if node.name == node_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_recursive(child, node_name)
		if result:
			return result
	
	return null

func _find_performance_stats_node(node: Node) -> Node:
	"""Recursively search for the performance stats script"""
	if node is PanelContainer:
		var script = node.get_script()
		if script and ("performance_stats" in str(script.resource_path).to_lower()):
			return node
	
	for child in node.get_children():
		var result = _find_performance_stats_node(child)
		if result:
			return result
	
	return null

func toggle_performance_stats():
	"""Toggle performance stats visibility"""
	if performance_stats_panel and performance_stats_panel.has_method("toggle_visibility"):
		performance_stats_panel.toggle_visibility()
	elif performance_stats_panel:
		# Fallback: toggle visibility directly
		performance_stats_panel.visible = !performance_stats_panel.visible
		print("Performance stats: %s" % ("ON" if performance_stats_panel.visible else "OFF"))
	else:
		print("⚠️  Performance stats panel not available")

func hide_performance_stats():
	"""Hide performance stats (called when debug is disabled)"""
	if performance_stats_panel and performance_stats_panel.has_method("hide_stats"):
		performance_stats_panel.hide_stats()
	elif performance_stats_panel:
		performance_stats_panel.visible = false
