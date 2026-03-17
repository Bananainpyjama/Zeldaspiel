# inventory.gd
extends Node
class_name Inventory

signal inventory_changed

var items: Array[Dictionary] = []
var max_slots: int = 20

func add_item(item: Item, amount: int = 1) -> bool:
	# Prüfe ob Item stackbar ist und bereits existiert
	if item.stackable:
		for slot in items:
			if slot["item"] == item and slot["amount"] < item.max_stack:
				var space = item.max_stack - slot["amount"]
				var add_amount = min(space, amount)
				slot["amount"] += add_amount
				amount -= add_amount
				inventory_changed.emit()
				if amount <= 0:
					return true
	
	# Füge neuen Slot hinzu
	while amount > 0 and items.size() < max_slots:
		var add_amount = min(amount, item.max_stack) if item.stackable else 1
		items.append({"item": item, "amount": add_amount})
		amount -= add_amount
		inventory_changed.emit()
	
	return amount == 0

func remove_item(item: Item, amount: int = 1) -> bool:
	for i in range(items.size() - 1, -1, -1):
		if items[i]["item"] == item:
			if items[i]["amount"] > amount:
				items[i]["amount"] -= amount
				inventory_changed.emit()
				return true
			else:
				amount -= items[i]["amount"]
				items.remove_at(i)
				inventory_changed.emit()
				if amount <= 0:
					return true
	return false

func has_item(item: Item, amount: int = 1) -> bool:
	var count = 0
	for slot in items:
		if slot["item"] == item:
			count += slot["amount"]
	return count >= amount
