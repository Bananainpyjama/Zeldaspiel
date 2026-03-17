# inventory_slot.gd
extends Panel

@onready var icon_rect = $TextureRect
@onready var amount_label = $AmountLabel

var item: Item = null
var amount: int = 0

func set_item(new_item: Item, new_amount: int):
	item = new_item
	amount = new_amount
	
	if item:
		icon_rect.texture = item.icon
		icon_rect.show()
		
		if item.stackable and amount > 1:
			amount_label.text = str(amount)
			amount_label.show()
		else:
			amount_label.hide()
	else:
		icon_rect.hide()
		amount_label.hide()
