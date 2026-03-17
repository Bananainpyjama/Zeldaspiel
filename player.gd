extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var jump_area = $JumpArea2D
@onready var interaction_area = $InteractionArea2D
@onready var interaction_label = $InteractionLabel

@export var speed := 150
@export var attack_duration := 0.2
@export var jump_duration := 0.5
@export var jump_distance := 100
@export var ground_collision_layer := 1
@export var pit_collision_layer := 2
@export var enemy_collision_layer := 3

# Stats (für Speichern/Laden)
@export var health := 100
@export var max_health := 100

var is_attacking := false
var is_jumping := false
var is_invincible := false
var is_in_dialogue := false
var direction := Vector2.DOWN
var jump_start_pos := Vector2.ZERO
var jump_target_pos := Vector2.ZERO
var was_attacked_recently := false

# Interaktions-System
var interactable_objects := []
var current_interactable = null

# GEÄNDERT: Verwende jetzt das globale Inventarsystem
var inventory: Inventory  # Referenz zum globalen Inventar
var ship_parts := 0

signal item_collected(item_name: String)
signal dialogue_started(npc)
signal dialogue_ended()

func _ready():
	# Hole Referenz zum globalen Inventar
	inventory = get_node("/root/PlayerInventory")
	
	# Füge zur "player" Gruppe hinzu (wichtig für Speichersystem)
	add_to_group("player")
	
	anim.stop()
	anim.play("idledown")
	
	# Setup Jump Area
	if not jump_area:
		jump_area = Area2D.new()
		add_child(jump_area)
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 20
		collision.shape = shape
		jump_area.add_child(collision)
		jump_area.collision_layer = 0
		jump_area.collision_mask = enemy_collision_layer
	
	# Setup Interaction Area
	if not interaction_area:
		interaction_area = Area2D.new()
		add_child(interaction_area)
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 40
		collision.shape = shape
		interaction_area.add_child(collision)
		interaction_area.collision_layer = 0
		interaction_area.collision_mask = 0b1000
		
		interaction_area.area_entered.connect(_on_interaction_area_entered)
		interaction_area.area_exited.connect(_on_interaction_area_exited)
		interaction_area.body_entered.connect(_on_interaction_body_entered)
		interaction_area.body_exited.connect(_on_interaction_body_exited)
	
	# Setup Interaction Label
	if not interaction_label:
		interaction_label = Label.new()
		add_child(interaction_label)
		interaction_label.position = Vector2(-20, -50)
		interaction_label.text = "Drücke E"
		interaction_label.add_theme_color_override("font_color", Color.WHITE)
		interaction_label.add_theme_color_override("font_outline_color", Color.BLACK)
		interaction_label.add_theme_constant_override("outline_size", 2)
		interaction_label.visible = false

func _physics_process(delta):
	if is_in_dialogue:
		velocity = Vector2.ZERO
		return
	
	if is_jumping:
		handle_jump_movement(delta)
	elif not is_attacking:
		handle_movement()
	
	if is_jumping:
		set_collision_mask_value(pit_collision_layer, false)
		set_collision_mask_value(enemy_collision_layer, false)
		z_index = 10
	else:
		set_collision_mask_value(pit_collision_layer, true)
		set_collision_mask_value(enemy_collision_layer, true)
		z_index = 0
	
	if not is_jumping:
		move_and_slide()
	
	update_current_interactable()

func handle_movement():
	velocity = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
		direction = Vector2.RIGHT
		anim.flip_h = true
	elif Input.is_action_pressed("ui_left"):
		velocity.x -= 1
		direction = Vector2.LEFT
		anim.flip_h = false
	elif Input.is_action_pressed("ui_down"):
		velocity.y += 1
		direction = Vector2.DOWN
	elif Input.is_action_pressed("ui_up"):
		velocity.y -= 1
		direction = Vector2.UP
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		anim.play("walk" + direction_to_string())
	else:
		anim.play("idle" + direction_to_string())

func handle_jump_movement(delta):
	global_position = global_position.move_toward(jump_target_pos, jump_distance * delta / jump_duration)
	
	if global_position.distance_to(jump_target_pos) < 5:
		global_position = jump_target_pos
		end_jump()

func _input(event):
	if is_in_dialogue:
		return
	
	if event.is_action_pressed("ui_accept"):
		if not is_attacking and not is_jumping:
			jump()
	
	if event.is_action_pressed("ui_interact"):
		if current_interactable:
			interact_with(current_interactable)

func jump():
	is_jumping = true
	is_invincible = true
	
	jump_start_pos = global_position
	jump_target_pos = global_position + (direction * jump_distance)
	
	if direction == Vector2.UP:
		anim.play("jumpup")
	elif direction == Vector2.DOWN:
		anim.play("jumpdown")
	else:
		anim.play("jumpleft")

func end_jump():
	if not is_jumping:
		return
		
	is_jumping = false
	is_invincible = false
	check_landing()
	await get_tree().create_timer(0.1).timeout

func check_landing():
	pass

func take_damage(amount: int):
	if is_invincible:
		return
	
	health -= amount
	print("Spieler nimmt ", amount, " Schaden! HP: ", health, "/", max_health)
	
	if health <= 0:
		die()
		return
	
	was_attacked_recently = true
	velocity = -direction * 200
	modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.2).timeout
	modulate = Color.WHITE
	
	await get_tree().create_timer(3.0).timeout
	was_attacked_recently = false

func heal(amount: int):
	health = min(health + amount, max_health)
	print("Spieler geheilt! HP: ", health, "/", max_health)

func die():
	print("Spieler ist gestorben!")
	# Hier kannst du Game Over Logik hinzufügen
	# z.B. get_tree().reload_current_scene()

func attack():
	is_attacking = true
	velocity = Vector2.ZERO
	anim.play("attack_" + direction_to_string())
	
	await get_tree().create_timer(attack_duration).timeout
	is_attacking = false

func direction_to_string() -> String:
	if direction == Vector2.DOWN:
		return "down"
	elif direction == Vector2.UP:
		return "up"
	elif direction == Vector2.LEFT:
		return "left"
	elif direction == Vector2.RIGHT:
		return "left"
	return "down"

# ==================== INTERAKTIONS-SYSTEM ====================

func _on_interaction_area_entered(area: Area2D):
	if area.is_in_group("interactable"):
		interactable_objects.append(area)

func _on_interaction_area_exited(area: Area2D):
	if area in interactable_objects:
		interactable_objects.erase(area)
		if current_interactable == area:
			current_interactable = null
			interaction_label.visible = false

func _on_interaction_body_entered(body: Node2D):
	if body.is_in_group("interactable"):
		interactable_objects.append(body)

func _on_interaction_body_exited(body: Node2D):
	if body in interactable_objects:
		interactable_objects.erase(body)
		if current_interactable == body:
			current_interactable = null
			interaction_label.visible = false

func update_current_interactable():
	if interactable_objects.is_empty():
		current_interactable = null
		interaction_label.visible = false
		return
	
	var closest = null
	var closest_distance = INF
	
	for obj in interactable_objects:
		var distance = global_position.distance_to(obj.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = obj
	
	current_interactable = closest
	
	if current_interactable:
		interaction_label.visible = true
		if current_interactable.is_in_group("npc"):
			interaction_label.text = "E - Sprechen"
		elif current_interactable.is_in_group("item"):
			interaction_label.text = "E - Aufheben"
		else:
			interaction_label.text = "E - Interagieren"
	else:
		interaction_label.visible = false

func interact_with(target):
	if not target:
		return
	
	if target.is_in_group("item"):
		pickup_item(target)
	elif target.is_in_group("npc"):
		start_dialogue(target)
	elif target.has_method("interact"):
		target.interact(self)

# GEÄNDERT: Jetzt wird Item-Resource ins globale Inventar eingefügt
func pickup_item(item_node):
	# Hole die Item-Resource vom Node
	var item_resource: Item = item_node.item_resource
	
	if not item_resource:
		print("Fehler: Item hat keine item_resource!")
		return
	
	var item_name = item_resource.item_name
	var is_ship_part = item_node.get("is_ship_part") if item_node.has_method("get") else false
	
	# Füge zum globalen Inventar hinzu
	if inventory.add_item(item_resource, 1):
		print("Item aufgehoben: ", item_name)
		
		if is_ship_part:
			ship_parts += 1
			print("Schiffsteil gesammelt! (", ship_parts, "/X)")
		
		# Signal senden
		item_collected.emit(item_name)
		
		# Item aus der Welt entfernen
		if item_node.has_method("pickup"):
			item_node.pickup()
		else:
			item_node.queue_free()
		
		interactable_objects.erase(item_node)
	else:
		print("Inventar ist voll!")

func start_dialogue(npc):
	is_in_dialogue = true
	velocity = Vector2.ZERO
	
	var direction_to_npc = (npc.global_position - global_position).normalized()
	if abs(direction_to_npc.x) > abs(direction_to_npc.y):
		direction = Vector2.RIGHT if direction_to_npc.x > 0 else Vector2.LEFT
	else:
		direction = Vector2.DOWN if direction_to_npc.y > 0 else Vector2.UP
	
	anim.play("idle" + direction_to_string())
	dialogue_started.emit(npc)
	
	if npc.has_method("start_dialogue"):
		npc.start_dialogue(self)

func end_dialogue():
	is_in_dialogue = false
	dialogue_ended.emit()

func can_build_ship() -> bool:
	return ship_parts >= 5

# GEÄNDERT: Prüfe im globalen Inventar
func has_item(item_id: String) -> bool:
	for slot in inventory.items:
		if slot["item"].id == item_id:
			return true
	return false

# NEU: Verwende Item aus Inventar (z.B. Heiltrank)
func use_item(item: Item):
	if item.item_type == "consumable":
		# Beispiel: Heiltrank
		if "health" in item.item_name.to_lower() or "heal" in item.item_name.to_lower():
			heal(50)
			print("Heiltrank verwendet!")
