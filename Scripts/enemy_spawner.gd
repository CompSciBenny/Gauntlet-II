class_name EnemySpawner extends MultiplayerSpawner

func _ready() -> void:
	clear_spawnable_scenes()
	add_enemies_to_spawn_list()

func add_enemies_to_spawn_list() -> void:
	var dir = DirAccess.open("res://Scenes/Enemies/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory in enemy folder: " + file_name)
			else:
				add_spawnable_scene("res://Scenes/Enemies/" + file_name)
				#print("Found file in enemy folder: " + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the enemy folder path.")

func spawn_enemy(enemy_scene_path : String, spawn_position : Vector2, health = -1) -> Enemy:
	if (not multiplayer.is_server()): return
	var new_enemy : Enemy = load(enemy_scene_path).instantiate()
	new_enemy.global_position = spawn_position
	if (health > 0): new_enemy.health = health
	get_node(spawn_path).call_deferred("add_child", new_enemy, true)
	return new_enemy
