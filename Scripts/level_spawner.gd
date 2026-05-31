class_name LevelSpawner extends MultiplayerSpawner

func _ready() -> void:
	clear_spawnable_scenes()
	add_lobby_to_spawn_list()
	add_levels_to_spawn_list()

func add_lobby_to_spawn_list() -> void:
	var level_scene_path : String = "res://Scenes/Levels/lobby.tscn"
	add_spawnable_scene(level_scene_path)

func add_levels_to_spawn_list() -> void:
	var potential_level : int = 1
	var file_path_exists : bool = true
	while (file_path_exists):
		var level_scene_path : String = "res://Scenes/Levels/level_" + str(potential_level) + ".tscn"
		var level_scene_resource : Resource = load(level_scene_path)
		if (level_scene_resource == null):
			file_path_exists = false
			print("Could not find a level ", potential_level)
			continue
		add_spawnable_scene(level_scene_path)
		print("Added level ", potential_level, " to spawn list")
		potential_level += 1

func spawn_level(level_scene_path : String) -> Level:
	if (not multiplayer.is_server()): return

	var new_level : Level = load(level_scene_path).instantiate()
	# Node name is synchronized through MultiplayerSpawner, we can use this to set authority to the player.
	#new_level.name = str(id)
	get_node(spawn_path).call_deferred("add_child", new_level)
	#print("NEW LEVEL: ", new_level)
	#Global.main.current_level = new_level
	return new_level

func spawn_lobby() -> Level:
	if (not multiplayer.is_server()): return

	var new_lobby : Level = load("res://Scenes/Levels/lobby.tscn").instantiate()
	get_node(spawn_path).call_deferred("add_child", new_lobby)
	return new_lobby
