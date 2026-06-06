class_name Main extends Node2D

var current_level : Level
@onready var player_container : Node2D = %"Player Container"
@onready var enemy_container : Node2D = %"Enemy Container"

var current_level_num : int = 1

var players : Array[Player] = []
var default_player_spawn_positions : Array[Vector2] = [
	Vector2(56., 56.),
	Vector2(24., 56.),
	Vector2(56., 24.),
	Vector2(24., 24.),
]

signal begin_level_transition

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.main = self
	#_spawn_lobby.rpc()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_player_count() -> int:
	return player_container.get_child_count()

@rpc("any_peer", "call_local")
func _check_for_level_transition() -> void:
	for player : Player in player_container.get_children():
		if (player.state == Player.State.EXITING or player.state == Player.State.DEAD):
			continue
		return
	current_level_num += 1
	Global.ui.activate_level_transition.rpc(current_level_num)
	#if (current_level): current_level.queue_free()

@rpc("authority", "call_local")
func _next_level() -> void:
	if (not multiplayer.is_server() or not is_multiplayer_authority()): return
	var next_level_scene_file_path : String = "res://Scenes/Levels/level_" + str(current_level_num) + ".tscn"
	#var next_level_scene_file_path : String = "res://Scenes/Levels/level_2.tscn"
	
	# Adds level as a child of main (in LevelSpawner auto spawn list, spawns for all clients)
	#current_level =
	%LevelSpawner.spawn_level(next_level_scene_file_path)
func delete_current_level() -> void:
	if (current_level or is_instance_valid(current_level)):
		current_level.queue_free()
		current_level = null

#@rpc("authority", "call_local")
func spawn_lobby() -> void:
	#if (not multiplayer.is_server() or not is_multiplayer_authority()): return
	# Adds level as a child of main (in LevelSpawner auto spawn list, spawns for all clients)
	#current_level =
	%LevelSpawner.spawn_lobby()
	
@rpc("authority", "call_local")
func _spawn_enemy(enemy_scene_path : String, spawn_pos : Vector2, health = -1) -> void:
	if (not multiplayer.is_server() or not is_multiplayer_authority()): return
	%"Enemy Spawner".spawn_enemy(enemy_scene_path, spawn_pos, health)
func delete_all_enemies() -> void:
	for enemy : Enemy in %"Enemy Container".get_children():
		enemy.queue_free()

func _on_child_entered_tree(node: Node) -> void:
	# Sets the current level and positions players at their respective spawn points
	if (node.is_in_group("level")):
		if (current_level): current_level.queue_free()
		current_level = node
		for player in range(get_player_count()):
			var spawn_position : Vector2 = current_level.player_spawn_points.get_child(player).global_position
			player_container.get_child(player).enter_level(spawn_position)
