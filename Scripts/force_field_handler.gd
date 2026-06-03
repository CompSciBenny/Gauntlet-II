@tool
class_name ForceFieldHandler extends TileMapLayer

var previous_solid_tiles : Array[Vector2i]

func _process(delta: float) -> void:
	if (Engine.is_editor_hint()):
		var current_solid_tiles : Array[Vector2i] = %"Solid Layer".get_used_cells()
		if (not current_solid_tiles == previous_solid_tiles):
			add_force_field_floor_tiles()
		previous_solid_tiles = current_solid_tiles

func erase_all_force_field_floor_tiles() -> void:
	for cell : Vector2i in get_used_cells():
		var cell_tile_data : TileData = get_cell_tile_data(cell)
		if (not cell_tile_data.get_custom_data("trap_type") == "force_field"): continue
		erase_cell(cell)
func add_force_field_floor_tiles() -> void:
	erase_all_force_field_floor_tiles()
	for cell : Vector2i in %"Solid Layer".get_used_cells():
		if (not is_cell_force_field(cell)): continue
		var force_field_cell : Vector2i = cell
		var between_tiles : Array[Vector2i] = []
		
		var above_tile : Vector2i = force_field_cell + Vector2i.UP
		while (is_tile_in_play_area(above_tile)):
			if (is_cell_force_field(above_tile)):
				for tile : Vector2i in between_tiles:
					set_cell(tile, 0, Vector2i(0,2))
				break
			else:
				between_tiles.append(above_tile)
				above_tile += Vector2i.UP
		between_tiles.clear()
				
		var right_tile : Vector2i = force_field_cell + Vector2i.RIGHT
		while (is_tile_in_play_area(right_tile)):
			if (is_cell_force_field(right_tile)):
				for tile : Vector2i in between_tiles:
					set_cell(tile, 0, Vector2i(0,2))
				break
			else:
				between_tiles.append(right_tile)
				right_tile += Vector2i.RIGHT
		between_tiles.clear()
				
		var below_tile : Vector2i = force_field_cell + Vector2i.DOWN
		while (is_tile_in_play_area(below_tile)):
			if (is_cell_force_field(below_tile)):
				for tile : Vector2i in between_tiles:
					set_cell(tile, 0, Vector2i(0,2))
				break
			else:
				between_tiles.append(below_tile)
				below_tile += Vector2i.DOWN
		between_tiles.clear()
				
		var left_tile : Vector2i = force_field_cell + Vector2i.LEFT
		while (is_tile_in_play_area(left_tile)):
			if (is_cell_force_field(left_tile)):
				for tile : Vector2i in between_tiles:
					set_cell(tile, 0, Vector2i(0,2))
				break
			else:
				between_tiles.append(left_tile)
				left_tile += Vector2i.LEFT
		between_tiles.clear()

func is_cell_force_field(cell : Vector2i) -> bool:
	var cell_tile_data : TileData = %"Solid Layer".get_cell_tile_data(cell)
	return cell_tile_data.get_custom_data("force_field")

func is_tile_in_play_area(tile_to_check : Vector2i) -> bool:
	if (tile_to_check.x < 0 or tile_to_check.y < 0):
		return false
	elif (tile_to_check.x >= 31 or tile_to_check.y >= 31):
		return false
	else:
		return true
