extends Node2D

@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("redblink")

	await get_tree().create_timer(2.0).timeout

	var dialogs = [
		{
			"text": "Fehler 09xy93... Systemfehler erkannt.",
			"speaker": "System"
		},
		{
			"text": "Antriebssystem außer Betrieb...",
			"speaker": "System"
		},
		{
			"text": "Notfallprotokoll wird aktiviert.",
			"speaker": "System"
		}
	]
