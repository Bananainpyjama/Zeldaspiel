# inventory_ui.gd
extends Control

@onready var grid_container = $Panel/MarginContainer/VBoxContainer/GridContainer
var inventory: Inventory
const SLOT_SCENE = preload("res://scenes/ui/inventory_slot.tscn")

func _ready():
	inventory = get_node("/root/PlayerInventory") # Autoload
	inventory.inventory_changed.connect(_on_inventory_changed)
	_update_ui()
	hide()

func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		visible = !visible

func _update_ui():
	# Lösche alte Slots
	for child in grid_container.get_children():
		child.queue_free()
	
	# Erstelle Slots für alle Items
	for slot_data in inventory.items:
		var slot = SLOT_SCENE.instantiate()
		grid_container.add_child(slot)
		slot.set_item(slot_data["item"], slot_data["amount"])
	
	# Füge leere Slots hinzu
	for i in range(inventory.max_slots - inventory.items.size()):
		var slot = SLOT_SCENE.instantiate()
		grid_container.add_child(slot)

func _on_inventory_changed():
	_update_ui()
