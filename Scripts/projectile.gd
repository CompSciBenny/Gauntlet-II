class_name Projectile extends Area2D

# Projectile stats decided by owner
var player_color_and_class_string : String
var speed : float
var damage : float
var is_reflective : bool = false
var is_super : bool = false

var velocity : Vector2
var sprite_name : String
var owner_id : int
var bounces : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if (velocity == Vector2.ZERO):
		hide()
		queue_free()
	orient_projectile()
	show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	position += velocity * delta

func set_velocity(move_dir : Vector2) -> void:
	velocity = move_dir * speed

func orient_projectile() -> void:
	# Changes sprite based on orientation and player class
	sprite_name = player_color_and_class_string
	if (not sprite_name.contains("Warrior")): sprite_name += " " + Global.get_direction_name(velocity)
	%Sprite.play(sprite_name)
	
	# Orients projectile collider
	%"Hitbox Collider".rotation_degrees = 0
	match Global.get_direction_name(velocity):
		"Up":
			%"Hitbox Collider".rotate(deg_to_rad(-90))
		"Down":
			%"Hitbox Collider".rotate(deg_to_rad(90))
		"Left":
			%"Hitbox Collider".rotate(deg_to_rad(0))
		"Right":
			%"Hitbox Collider".rotate(deg_to_rad(0))
		"Up Right":
			%"Hitbox Collider".rotate(deg_to_rad(-45))
		"Down Right":
			%"Hitbox Collider".rotate(deg_to_rad(45))
		"Up Left":
			%"Hitbox Collider".rotate(deg_to_rad(-135))
		"Down Left":
			%"Hitbox Collider".rotate(deg_to_rad(135))


func _on_area_entered(area: Area2D) -> void:
	# prevents hitting the player who shot the projectile
	if (area.owner.name.to_int() == owner_id): return
	# checks if area is on enemy layer
	if (area.get_collision_layer_value(3)):
		if (not is_super):
			area.owner._take_damage(damage)
		else:
			area.owner.hide()
			area.owner.queue_free()
	if (not is_super):
		hide()
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# prevents hitting the player who shot the projectile
	if (body.name.to_int() == owner_id): return
	
	if (body.is_class("TileMapLayer") and is_reflective and bounces < 8):
		handle_reflection(body)
		return
		
	# makes sure to only hit enemy hurtboxes (areas, not bodies)
	if (not body.is_class("TileMapLayer") and body.get_collision_layer_value(3)):
		return
	
	impact()

# Calculates reflective shots
func handle_reflection(layer : TileMapLayer) -> void:
	var solid_tile_coords : Array[Vector2i] = layer.get_surrounding_cells(Global.global_to_map(global_position))
	var closest_solid_tile : Vector2i
	var min_distance : float = 999
	
	# Determines the tile to reflect off of by finding the closest one
	for tile_coords in solid_tile_coords:
		if (layer.get_cell_atlas_coords(tile_coords) == Vector2i(-1,-1)): continue
		var current_tile_distance : float = global_position.distance_to(Global.map_to_global(tile_coords))
		if (current_tile_distance < min_distance):
			closest_solid_tile = tile_coords
			min_distance = current_tile_distance
	var closest_tile_pos : Vector2 = Global.map_to_global(closest_solid_tile)
	
	# If the tile to reflect off of is more above/below, change vertical direction
	# Else, change horizontal direction
	if (abs(closest_tile_pos.x - global_position.x) >= abs(closest_tile_pos.y - global_position.y)):
		velocity.x *= -1
	else:
		velocity.y *= -1

	# Update the orientation of the projectile, including the collider
	orient_projectile()
	
	bounces += 1
	
	# Play reflect sound
	%"Reflect SFX".pitch_scale = randf_range(0.9, 1.1)
	%"Reflect SFX".play()

func impact() -> void:
	set_velocity(Vector2.ZERO)
	%"Hitbox Collider".disabled = true
	%Sprite.speed_scale = 1.
	%Sprite.play("Impact")

func _on_sprite_animation_finished() -> void:
	if (not %Sprite.animation == "Impact"): return
	hide()
	queue_free()
