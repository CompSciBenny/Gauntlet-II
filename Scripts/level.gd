class_name Level extends Node2D

@export var player_spawn_points : Node2D
@onready var enemy_container : Node2D = %"Enemy Container"
@onready var ground_layer : TileMapLayer = %"Ground Layer"
@onready var solid_layer : TileMapLayer = %"Solid Layer"
@onready var trap_layer : TileMapLayer = %"Trap Layer"

const MAX_ENEMY_COUNT : int = 30
const STUN_TILE_EFFECT_TIME : float = 1.5

const FORCE_FIELD_DAMAGE : int = 5
const FORCE_FIELD_DAMAGE_RATE : int = 7

var spawn_time : float = 0
var elapsed_time : float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_time = Time.get_ticks_msec() / 1000.0
	self.z_index = -1
	add_to_group("level")
	%"Trap Data Layer".hide()

	#if (not is_multiplayer_authority()): return
	choose_random_exit()				# If multiple exits exist, choose one
	spawn_existing_enemies()
	delete_inaccessible_floor_tiles()
	print("LEVEL NAME: ", name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	elapsed_time = (Time.get_ticks_msec() / 1000.0) - spawn_time

func force_field_tiles_active(cell : Vector2i) -> bool:
	var source_id = trap_layer.get_cell_source_id(cell)
	if source_id == -1: return false
	var source = trap_layer.tile_set.get_source(source_id)
	if source is TileSetAtlasSource:
		var atlas_source: TileSetAtlasSource = source
		var cycle_length : float = 0
		var frame_count : int = atlas_source.get_tile_animation_frames_count(Vector2i(0,2))

		for i in frame_count:
			var frame_duration : float = atlas_source.get_tile_animation_frame_duration(Vector2i(0,2), i)
			cycle_length += frame_duration
		
		print(fmod(elapsed_time, cycle_length) <= 1.)
		return fmod(elapsed_time, cycle_length) <= 1.
	else:
		return false

func choose_random_exit() -> void:
	var exit_tiles : Array[Vector2i] = []
	for tile : Vector2i in ground_layer.get_used_cells():
		var tile_data : TileData = ground_layer.get_cell_tile_data(tile)
		if (tile_data and tile_data.get_custom_data("exit")):
			exit_tiles.append(tile)
	if (exit_tiles.is_empty()): return
	var exit_tile_to_keep : Vector2i = exit_tiles.pick_random()
	for exit_tile in exit_tiles:
		if (exit_tile == exit_tile_to_keep): continue
		ground_layer.erase_cell(exit_tile)
		add_floor_tile_at_coord(exit_tile)
func delete_inaccessible_floor_tiles() -> void:
	for cell : Vector2i in ground_layer.get_used_cells():
		if cell in solid_layer.get_used_cells():
			ground_layer.erase_cell(cell)
	# Delete floor tiles under enemy spawners
	for spawner in %"Monster Generators".get_children():
		ground_layer.erase_cell(Global.global_to_map(spawner.global_position))
	# Delete floor tiles under trap tiles
	for trap_tile in Global.main.current_level.trap_layer.get_used_cells():
		if (not trap_layer.get_cell_tile_data(trap_tile).get_custom_data("enemy") == ""): continue
		ground_layer.erase_cell(trap_tile)

func spawn_existing_enemies() -> void:
	for cell in trap_layer.get_used_cells():
		var cell_tile_data : TileData = trap_layer.get_cell_tile_data(cell)
		var enemy : String = cell_tile_data.get_custom_data("enemy")
		if (enemy == ""): continue
		var enemy_scene_file_path : String = "res://Scenes/Enemies/" + enemy + ".tscn"
		Global.main._spawn_enemy.rpc(enemy_scene_file_path, Global.map_to_global(cell))
		trap_layer.erase_cell(cell)

@rpc("authority", "call_local")
func add_floor_tile_at_pos(pos : Vector2) -> void:
	var cell_coords : Vector2i = Global.global_to_map(pos)
	var floor_tile_source_id : int = %"Background Layer".get_cell_source_id(Vector2i.ZERO)
	var floor_tile_atlas_coords : Vector2i = %"Background Layer".get_cell_atlas_coords(Vector2i.ZERO)
	ground_layer.set_cell(cell_coords, floor_tile_source_id, floor_tile_atlas_coords)
func add_floor_tile_at_coord(coord : Vector2i) -> void:
	if (not ground_layer): return
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
		
	%"Door SFX".play()

# Called by players who step on trap tiles
@rpc("any_peer", "call_local")
func _activate_trap(trap_type : String, trap_tile : Vector2i) -> void:
	if (trap_type == "trap"):
		var floor_trap_tile_data : TileData = %"Trap Data Layer".get_cell_tile_data(trap_tile)
		var floor_trap_id : int = floor_trap_tile_data.get_custom_data("trap_id")
		for trap_data_tile : Vector2i in %"Trap Data Layer".get_used_cells():
			var wall_trap_tile_data : TileData = %"Trap Data Layer".get_cell_tile_data(trap_data_tile)
			var wall_trap_id : int = wall_trap_tile_data.get_custom_data("trap_id")
			if (not floor_trap_id == wall_trap_id): continue
			solid_layer.erase_cell(trap_data_tile)
			trap_layer.erase_cell(trap_data_tile)
			add_floor_tile_at_coord(trap_data_tile)
		%"Trap SFX".play()
	elif (trap_type == "stun"):
		trap_layer.erase_cell(trap_tile)
		add_floor_tile_at_coord(trap_tile)
		%"Stun SFX".play()

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
