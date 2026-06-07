class_name PlayerSpawner extends MultiplayerSpawner

@export var network_player: PackedScene
var signals_connected : bool = false

func _ready() -> void:
	Global.player_spawner = self
	multiplayer.peer_connected.connect(spawn_player)

	# Here we connect to the "host_started" signal in the high_level_network_handler class.
	NetworkHandler.host_started.connect(spawn_host_player)

func spawn_player(id : int) -> void:
	var debug_health : int = (Global.main.get_player_count() + 1) * 5
	if !multiplayer.is_server(): return

	var new_player : Player = network_player.instantiate()
	# Node name is synchronized through MultiplayerSpawner, we can use this to set authority to the player.
	new_player.name = str(id)
	if (Global.main.current_level):
		new_player.global_position = Global.main.current_level.player_spawn_points.get_child(Global.main.players.size()).global_position
	else:
		new_player.global_position = Global.main.default_player_spawn_positions[Global.main.players.size()]
	Global.main.players.append(new_player)
	
	new_player.health = debug_health
	get_node(spawn_path).call_deferred("add_child", new_player)

func disconnect_and_despawn_all_players() -> void:
	if !multiplayer.is_server(): return
	var host : Player
	for player : Player in get_node(spawn_path).get_children():
		if (int(player.name) == 1):
			host = player
			continue
		NetworkHandler.peer.disconnect_peer(int(player.name))
		player.queue_free()
	NetworkHandler.peer.close()
	multiplayer.multiplayer_peer = null
	host.queue_free()
	Global.main.players.clear()

@rpc("any_peer", "call_local")
func despawn_and_delete_player(id : int) -> void:
	if !multiplayer.is_server(): return
	NetworkHandler.peer.disconnect_peer(id)
	for player : Player in Global.main.player_container.get_children():
		if (id == int(player.name)):
			Global.main.players.remove_at(Global.main.players.find(player))
			player.queue_free()
			break

# In this function, which is connected to the "host_started" signal in the high_level_network_handler
# class, we spawn the server player. Easy right?
func spawn_host_player() -> void:
	if !multiplayer.is_server(): return
	spawn_player(multiplayer.get_unique_id())
