@tool
class_name WallShadowHandler extends TileMapLayer

var previous_wall_tiles : Array[Vector2i]

func _process(delta: float) -> void:
	if (Engine.is_editor_hint() or not Engine.is_editor_hint()):
		var current_wall_tiles : Array[Vector2i] = %"Solid Layer".get_used_cells()
		if (not current_wall_tiles == previous_wall_tiles):
			add_shadow_tiles()
		previous_wall_tiles = current_wall_tiles

func add_shadow_tiles() -> void:
	%"Shadow Layer".clear()
	for floor_tile : Vector2i in %"Ground Layer".get_used_cells():
		var potential_wall_cells : Array[Vector2i] = get_eight_neighboring_wall_cells(floor_tile)
		if (potential_wall_cells.is_empty()): continue

		var left : Vector2i = floor_tile + Vector2i.LEFT
		var bottom_left : Vector2i = floor_tile + Vector2i(-1, 1)
		var bottom_middle : Vector2i = floor_tile + Vector2i.DOWN
		
		if (potential_wall_cells.has(left) and potential_wall_cells.has(bottom_middle)):
			%"Shadow Layer".set_cell(floor_tile, 0, Vector2i(0,0))
		elif (potential_wall_cells.has(left) and potential_wall_cells.has(bottom_left)):
			%"Shadow Layer".set_cell(floor_tile, 0, Vector2i(2,0))
		elif (potential_wall_cells.has(bottom_left) and potential_wall_cells.has(bottom_middle)):
			%"Shadow Layer".set_cell(floor_tile, 0, Vector2i(4,0))
		elif (potential_wall_cells.has(left)):
			%"Shadow Layer".set_cell(floor_tile, 0, Vector2i(1,0))
		elif (potential_wall_cells.has(bottom_left)):
			%"Shadow Layer".set_cell(floor_tile, 0, Vector2i(3,0))
		elif (potential_wall_cells.has(bottom_middle)):
			%"Shadow Layer".set_cell(floor_tile, 0, Vector2i(5,0))

func get_eight_neighboring_wall_cells(cell : Vector2i) -> Array[Vector2i]:
	var neighboring_cells : Array[Vector2i] = []
	for x in range(-1, 2):
		for y in range(-1, 2):
			if ((x == 0 and y == 0) or %"Solid Layer".get_cell_source_id(cell + Vector2i(x, y)) == -1): continue
			neighboring_cells.append(cell + Vector2i(x, y))
	return neighboring_cells
