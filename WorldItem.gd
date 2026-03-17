# item.gd (in der Spielwelt platzierbare Items)
extends Area2D

# WICHTIG: Hier referenzierst du die Item-Resource (.tres Datei)
@export var item_resource: Item  # Die eigentliche Item-Definition
@export var is_ship_part := false
@export var amount := 1  # Für stackbare Items

@onready var sprite = $Sprite2D

func _ready():
	add_to_group("interactable")
	add_to_group("item")
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(4, true)
	
	# Setze Sprite automatisch vom Item-Resource
	if item_resource and item_resource.icon:
		if sprite:
			sprite.texture = item_resource.icon

func pickup():
	# Pickup-Animation
	var tween = create_tween()
	tween.parallel().tween_property(self, "position", position + Vector2(0, -20), 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	queue_free()

# Optional: Zeige Item-Namen beim Hovern (für Debug)
func _to_string():
	if item_resource:
		return item_resource.item_name
	return "Unbenanntes Item"
