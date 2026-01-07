# inventory_gold.gd
# Handles gold/currency management for the inventory system
extends Node

var gold: int = 0

signal gold_changed(amount)

func add_gold(amount: int):
	"""Add gold to inventory"""
	gold += amount
	gold_changed.emit(gold)

func remove_gold(amount: int) -> bool:
	"""Remove gold from inventory. Returns true if successful."""
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

func get_gold() -> int:
	"""Get current gold amount"""
	return gold

func set_gold(amount: int):
	"""Set gold to specific amount"""
	gold = amount
	gold_changed.emit(gold)
