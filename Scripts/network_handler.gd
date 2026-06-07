extends Node

signal host_started()

const PORT: int = 42069 # Below 65535 (16-bit unsigned max value)

var peer: ENetMultiplayerPeer

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func start_server() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, Global.PLAYER_LIMIT - 1)
	multiplayer.multiplayer_peer = peer


func start_client(ip_address : String) -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_address, PORT)
	multiplayer.multiplayer_peer = peer


# To create a server+player, or host player, we create a new function "start_host()".
# This function then starts the server like normal, but also calls a signal "host_started".
# Since this is an autoloaded class, other functions can connect to this signal, like I did
# in the "high_level_player_spawner". More comments there.
func start_host() -> void:
	start_server()
	host_started.emit()
	
func close_multiplayer_peer() -> void:
	peer.disconnect_peer(multiplayer.get_unique_id())
	multiplayer.multiplayer_peer = null

func _on_peer_connected() -> void:
	print("Peer connected to server!")
func _on_peer_disconnected() -> void:
	print("Peer disconnected from server!")
func _on_connected_to_server() -> void:
	print("Successfully connected to server!")
func _on_connection_failed() -> void:
	close_multiplayer_peer()
	print("Connection failed!")
func _on_server_disconnected() -> void:
	close_multiplayer_peer()
	print("Disconnected from server!")
