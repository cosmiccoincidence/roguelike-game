# player_inventory.gd
# Handles item pickup and inventory interactions
extends Node

# Reference to main player
var player: CharacterBody3D
var camera: Camera3D

func initialize(player_node: CharacterBody3D, cam: Camera3D):
	"""Called by main player script to set references"""
	player = player_node
	camera = cam
	
	# Register player with Inventory singleton
	Inventory.set_player(player)
	print("Player registered with Inventory system")

func handle_pickup_input():
	"""Handle pickup key press"""
	if player.is_dying:
		return
	
	_try_pickup_item()

func _try_pickup_item():
	"""Attempt to pick up item at mouse position"""
	var mouse_pos = player.get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var space = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(query)
	
	if result and result.collider:
		var hit_node = result.collider
		
		# Try parent first (typical item structure)
		if hit_node.get_parent() and hit_node.get_parent().has_method("pickup"):
			hit_node.get_parent().pickup()
		# Then try the node itself
		elif hit_node.has_method("pickup"):
			hit_node.pickup()
