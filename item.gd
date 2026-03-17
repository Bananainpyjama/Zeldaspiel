# item.gd - Die Resource-Klasse für Item-Daten
extends Resource
class_name Item

@export var id: String = ""
@export var item_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var stackable: bool = false
@export var max_stack: int = 1
@export var item_type: String = "misc"  # misc, weapon, consumable, etc.
@export var value: int = 0

# Für Speichern/Laden
func to_dict() -> Dictionary:
	return {
		"id": id,
		"item_name": item_name,
		"description": description,
		"icon_path": icon.resource_path if icon else "",
		"stackable": stackable,
		"max_stack": max_stack,
		"item_type": item_type,
		"value": value
	}

static func from_dict(data: Dictionary) -> Item:
	var item = Item.new()
	item.id = data.get("id", "")
	item.item_name = data.get("item_name", "")
	item.description = data.get("description", "")
	if data.get("icon_path", "") != "":
		item.icon = load(data["icon_path"])
	item.stackable = data.get("stackable", false)
	item.max_stack = data.get("max_stack", 1)
	item.item_type = data.get("item_type", "misc")
	item.value = data.get("value", 0)
	return item
