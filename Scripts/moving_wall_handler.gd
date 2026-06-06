@tool
class_name MovingWallHandler extends TileMapLayer

const WALL_STATE_TIME : float = 1.75
var active_moving_wall_id : int = 1
var highest_moving_wall_state : int		# How many sets of moving walls there are in a level

var previous_trap_data_tiles : Array[Vector2i]
var scene_tree_timer : SceneTreeTimer

@export var simulate_moving_walls : bool:
	set(value):
		simulate_moving_walls = value
		if (Engine.is_editor_hint()):
			if (value):
				_ready()
			else:
				clear_all_moving_walls()
				if (scene_tree_timer): scene_tree_timer.disconnect("timeout", _on_wall_state_timer_timeout)

func _ready() -> void:
	if (Engine.is_editor_hint() or not Engine.is_editor_hint()):
		clear_all_moving_walls()
		active_moving_wall_id = 1
		update_highest_moving_wall_state()
		update_moving_walls()
		if (scene_tree_timer): scene_tree_timer.disconnect("timeout", _on_wall_state_timer_timeout)
		scene_tree_timer = get_tree().create_timer(WALL_STATE_TIME)
		scene_tree_timer.connect("timeout", _on_wall_state_timer_timeout)

func _process(delta: float) -> void:
	if (Engine.is_editor_hint()):
		var current_trap_data_tiles : Array[Vector2i] = %"Trap Data Layer".get_used_cells()
		if (not current_trap_data_tiles == previous_trap_data_tiles):
			update_highest_moving_wall_state()
		previous_trap_data_tiles = current_trap_data_tiles

func update_highest_moving_wall_state() -> void:
	var current_highest_move_state : int = 0
	for data_cell : Vector2i in %"Trap Data Layer".get_used_cells():
		var tile_data : TileData = %"Trap Data Layer".get_cell_tile_data(data_cell)
		var tile_move_id : int = tile_data.get_custom_data("move_id")
		if (tile_move_id == 0 or tile_move_id <= current_highest_move_state): continue
		current_highest_move_state = tile_move_id
	highest_moving_wall_state = current_highest_move_state
func update_moving_walls() -> void:
	var walls_to_add : Array[Vector2i] = []
	#var walls_to_remove : Array[Vector2i] = []
	for data_cell : Vector2i in %"Trap Data Layer".get_used_cells():
		var tile_data : TileData = %"Trap Data Layer".get_cell_tile_data(data_cell)
		var tile_move_id : int = tile_data.get_custom_data("move_id")
		if (tile_move_id == 0): continue
		if (tile_move_id == active_moving_wall_id):
			walls_to_add.append(data_cell)
			if (not Engine.is_editor_hint()): %"Ground Layer".erase_cell(data_cell)
		else:
			erase_cell(data_cell)
			if (not Engine.is_editor_hint()): Global.main.current_level.add_floor_tile_at_coord(data_cell)
	var wall_tile_data : TileData = get_cell_tile_data(Vector2i(-1,-1))
	if (not wall_tile_data): return
	set_cells_terrain_connect(walls_to_add, wall_tile_data.terrain_set, wall_tile_data.terrain)
func clear_all_moving_walls() -> void:
	for data_cell : Vector2i in %"Trap Data Layer".get_used_cells():
		var tile_data : TileData = %"Trap Data Layer".get_cell_tile_data(data_cell)
		var tile_move_id : int = tile_data.get_custom_data("move_id")
		if (tile_move_id == 0): continue
		erase_cell(data_cell)

func _on_wall_state_timer_timeout() -> void:
	#if (Engine.is_editor_hint()):
	active_moving_wall_id += 1
	if (active_moving_wall_id > highest_moving_wall_state):
		active_moving_wall_id = 1
	
	update_moving_walls()
	if (scene_tree_timer): scene_tree_timer.disconnect("timeout", _on_wall_state_timer_timeout)
	scene_tree_timer = get_tree().create_timer(WALL_STATE_TIME)
	scene_tree_timer.connect("timeout", _on_wall_state_timer_timeout)
