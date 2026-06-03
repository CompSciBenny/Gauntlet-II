class_name Level extends Node2D

@export var player_spawn_points : Node2D
@onready var enemy_container : Node2D = %"Enemy Container"
@onready var ground_layer : TileMapLayer = %"Ground Layer"
@onready var solid_layer : TileMapLayer = %"Solid Layer"

const MAX_ENEMY_COUNT : int = 75

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.z_index = -1
	delete_inaccessible_floor_tiles()
	add_to_group("level")
	print("LEVEL NAME: ", name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func delete_inaccessible_floor_tiles() -> void:
	for cell : Vector2i in ground_layer.get_used_cells():
		if cell in solid_layer.get_used_cells():
			ground_layer.erase_cell(cell)
	# Delete floor tiles under enemy spawners
	for spawner in %"Enemy Spawners".get_children():
		ground_layer.erase_cell(Global.global_to_map(spawner.global_position))

@rpc("authority", "call_local")
func add_floor_tile_at_pos(pos : Vector2) -> void:
	var cell_coords : Vector2i = Global.global_to_map(pos)
	var floor_tile_source_id : int = %"Background Layer".get_cell_source_id(Vector2i.ZERO)
	var floor_tile_atlas_coords : Vector2i = %"Background Layer".get_cell_atlas_coords(Vector2i.ZERO)
	ground_layer.set_cell(cell_coords, floor_tile_source_id, floor_tile_atlas_coords)
func add_floor_tile_at_coord(coord : Vector2i) -> void:
	var floor_tile_source_id : int = %"Background Layer".get_cell_source_id(Vector2i.ZERO)
	var floor_tile_atlas_coords : Vector2i = %"Background Layer".get_cell_atlas_coords(Vector2i.ZERO)
	ground_layer.set_cell(coord, floor_tile_source_id, floor_tile_atlas_coords)

# Called by players who run into door tiles
@rpc("any_peer", "call_local")
func _unlock_door(door_tile : Vector2i) -> void:
	var doors_to_unlock : Array[Vector2i] = [door_tile]
	
	while (doors_to_unlock.size() > 0):
		# Finds and adds coords of adjacent doors to remove
		for cell in solid_layer.get_surrounding_cells(doors_to_unlock[0]):
			var data : TileData = solid_layer.get_cell_tile_data(cell)
			if (not data == null and data.get_custom_data("door") and not doors_to_unlock.has(cell)):
				doors_to_unlock.append(cell)
					
		# Deletes wall and adds floor tile for navigation
		solid_layer.erase_cell(doors_to_unlock[0])
		add_floor_tile_at_coord(doors_to_unlock[0])
			
		# Removes coords of deleted door
		doors_to_unlock.remove_at(0)

func is_tile_empty(tile_to_check : Vector2i) -> bool:
	if (solid_layer.get_used_cells().has(tile_to_check)):
		return false
	return true
func is_tile_in_play_area(tile_to_check : Vector2i) -> bool:
	if (tile_to_check.x < 0 or tile_to_check.y < 0):
		return false
	elif (tile_to_check.x >= 31 or tile_to_check.y >= 31):
		return false
	else:
		return true

func _get_transporter_destination(transporter_tile : Vector2i) -> Vector2:
	var closest_transporter : Vector2i
	var min_distance : float = 999
	for tile in solid_layer.get_used_cells():
		if (tile == transporter_tile): continue
		var tile_data : TileData = solid_layer.get_cell_tile_data(tile)
		if (tile_data.get_custom_data("transporter") and tile.distance_to(transporter_tile) < min_distance):
			closest_transporter = tile
			min_distance = tile.distance_to(transporter_tile)
	var available_destination_tiles : Array[Vector2i] = []
	for destination_tile : Vector2i in ground_layer.get_surrounding_cells(closest_transporter):
		if (is_tile_empty(destination_tile) and is_tile_in_play_area(destination_tile)):
			available_destination_tiles.append(destination_tile)
	return Global.map_to_global(available_destination_tiles.pick_random())
func _get_transportable_position(player_pos : Vector2, player_move_dir : Vector2) -> Vector2:
	var tile_to_transport_to : Vector2i = Vector2i(-1,-1)
	var distance : int = Global.TILE_SIZE
	while (tile_to_transport_to == Vector2i(-1,-1)):
		var tile_to_check : Vector2i = Global.global_to_map(player_pos + (player_move_dir * distance))
		if (not is_tile_in_play_area(tile_to_check)):
			tile_to_transport_to = Global.global_to_map(player_pos)
			break
		if (is_tile_empty(tile_to_check)):
			tile_to_transport_to = tile_to_check
			break
		distance += Global.TILE_SIZE
	return Global.map_to_global(tile_to_transport_to)
