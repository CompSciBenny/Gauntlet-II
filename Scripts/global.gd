extends Node

var main : Main
var ui : UI
var level_spawner : LevelSpawner
var player_spawner : PlayerSpawner

const TILE_SIZE : int = 32
const PLAYER_LIMIT : int = 4
const ITEM_LIMIT : int = 12

const GREEN : Color = Color(0.0, 0.659, 0.0, 1.0)
const RED : Color = Color(0.659, 0.0, 0.11, 1.0)
const BLUE : Color = Color(0.0, 0.329, 0.769, 1.0)
const YELLOW : Color = Color(0.769, 0.769, 0.0, 1.0)
const GRAY : Color = Color(0.663, 0.663, 0.663, 1.0)

var client_id : int

enum Class {
	ELF,
	WARRIOR,
	VALKYRIE,
	WIZARD,
}

enum PlayerColor {
	GREEN,
	RED,
	BLUE,
	YELLOW,
}

enum EnemyType {
	GHOST,
	GRUNT,
	DEMON,
	SORCERER,
	LOBBER,
	DEATH,
	ACID_PUDDLE,
	SUPER_SORCERER,
	DRAGON,
	IT,
	THIEF,
	MUGGER,
}

func global_to_map(global_pos : Vector2) -> Vector2i:
	var cell : Vector2i = Vector2(ceili(global_pos.x) / 32, ceili(global_pos.y) / 32)
	#print(cell)
	return cell

func map_to_global(cell : Vector2i) -> Vector2:
	var pos : Vector2 = Vector2i((cell.x * 32) + 16, (cell.y * 32) + 16)
	#print(pos)
	return pos

func get_eight_neighboring_cells(cell : Vector2i, level : Level) -> Array[Vector2i]:
	var neighboring_cells : Array[Vector2i] = []
	for x in range(-1, 2):
		for y in range(-1, 2):
			if ((x == 0 and y == 0) or level.ground_layer.get_cell_source_id(cell + Vector2i(x, y)) == -1): continue
			neighboring_cells.append(cell + Vector2i(x, y))
	return neighboring_cells

func get_direction_name(direction : Vector2) -> String:
	direction = direction.snappedf(1.)
	var direction_name : String = ""
	if (direction.y < 0):
		direction_name += "Up"
		if (not direction.x == 0): direction_name += " "
	elif (direction.y > 0):
		direction_name += "Down"
		if (not direction.x == 0): direction_name += " "
	if (direction.x < 0):
		direction_name += "Left"
	elif (direction.x > 0):
		direction_name += "Right"
	return direction_name

# Returns a list of surrounding tiles in the 8 cardinal directions within a certain range
func get_cardinal_tiles(tile : Vector2i, range : int) -> Array[Vector2i]:
	var cardinal_tiles : Array[Vector2i]
	for i in range(1, range + 1):
		cardinal_tiles.append(tile + Vector2i(0, -i))	# UP
		cardinal_tiles.append(tile + Vector2i(0, i))	# DOWN
		cardinal_tiles.append(tile + Vector2i(-i, 0))	# LEFT
		cardinal_tiles.append(tile + Vector2i(i, 0))	# RIGHT
		cardinal_tiles.append(tile + Vector2i(i, -i))	# UP RIGHT
		cardinal_tiles.append(tile + Vector2i(-i, -i))	# UP LEFT
		cardinal_tiles.append(tile + Vector2i(i, i))	# DOWN RIGHT
		cardinal_tiles.append(tile + Vector2i(-i, i))	# DOWN LEFT
	return cardinal_tiles

func get_random_floor_tile_pos() -> Vector2:
	var rand_floor_tile : Vector2i = Global.main.current_level.ground_layer.get_used_cells().pick_random()
	return map_to_global(rand_floor_tile)

func get_closest_tile(global_position : Vector2, tiles : Array[Vector2i]) -> Vector2i:
	var tile_coord : Vector2i = global_to_map(global_position)
	var closest_tile : Vector2i = tiles[0]
	var min_distance : float = tile_coord.distance_to(tiles[0])
	for tile in tiles:
		var distance : float = tile_coord.distance_to(tile)
		if (distance < min_distance):
			closest_tile = tile
			min_distance = distance
	return closest_tile

var player_class_stats = {
	"elf": {
		"shot_power": 1,
		"shot_speed": 750,
		"speed": 175,
		"armor": 0.1,
		"fight_power": 0,
		"magic_power": 0,
	},
	"warrior": {
		"shot_power": 3,
		"shot_speed": 250,
		"speed": 125,
		"armor": 0.2,
		"fight_power": 0,
		"magic_power": 0,
	},
	"valkyrie": {
		"shot_power": 1,
		"shot_speed": 500,
		"speed": 150,
		"armor": 0.3,
		"fight_power": 0,
		"magic_power": 0,
	},
	"wizard": {
		"shot_power": 2,
		"shot_speed": 750,
		"speed": 125,
		"armor": 0.,
		"fight_power": 0,
		"magic_power": 0,
	},
}
