class_name Main extends Node2D

var current_level : Level
@onready var player_container : Node2D = %"Player Container"

var current_level_num : int = 1

var players : Array[Player] = []

signal begin_level_transition

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.main = self
	_spawn_lobby.rpc()
	#Global.ui.activate_level_transition(current_level_num)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@rpc("any_peer", "call_local")
func _check_for_level_transition() -> void:
	for player : Player in %"Player Container".get_children():
		if (not player.state == Player.State.EXITING):
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

@rpc("authority", "call_local")
func _spawn_lobby() -> void:
	if (not multiplayer.is_server() or not is_multiplayer_authority()): return
	# Adds level as a child of main (in LevelSpawner auto spawn list, spawns for all clients)
	#current_level =
	%LevelSpawner.spawn_lobby()
	
func _on_child_entered_tree(node: Node) -> void:
	# Sets the current level and positions players at their respective spawn points
	if (node.is_in_group("level")):
		if (current_level): current_level.queue_free()
		current_level = node
		for player in range(%"Player Container".get_child_count()):
			var spawn_position : Vector2 = current_level.player_spawn_points.get_child(player).global_position
			%"Player Container".get_child(player).enter_level(spawn_position)
