class_name UI extends Control

@export var player_banner_scene : PackedScene
@export var character_preview_scene : PackedScene

var current_menu_option : int = 0

var tips : Array[String] = [
	"fight hand to hand by running into monsters",
	"stalling will cause doors to open",
	"shooting magic potions has a lesser effect",
	"save keys for closed treasure chests",
	"add more players for greater firepower",
]

var state : State = State.TITLE
enum State {
	TITLE,
	JOIN,
	LOBBY,
	CONTROLS,
	LEGEND,
	MONSTERS,
}

func _ready() -> void:
	Global.ui = self
	_return_to_main_menu()
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	%"Level Label".hide()
	%"Level Transition".hide()
	
func _process(delta: float) -> void:
	set_player_class_and_color()
	update_player_banners()
	update_character_previews()
	var address_to_check : String = %"IP Address Edit".text
	if (address_to_check == "" or not %"Connection Timeout Timer".is_stopped()):
		%"Join Host Button".disabled = true
	elif (not address_to_check.is_valid_ip_address()):
		%"Error Label".text = "  INVALID IP!"
		%"Error Label".add_theme_color_override("font_color", Global.RED)
		%"Join Host Button".disabled = true
	else:
		%"Error Label".text = "  VALID IP!"
		%"Error Label".add_theme_color_override("font_color", Global.GREEN)
		%"Join Host Button".disabled = false

@rpc("any_peer", "call_local")
func add_player_banners() -> void:
	for banner in %"Player Banners".get_children():
		banner.queue_free()
	#print(Global.main.player_container.get_child_count())
	for player : Player in Global.main.player_container.get_children():
		var new_player_banner : PlayerBanner = player_banner_scene.instantiate()
		new_player_banner.set_class(player.player_class)
		new_player_banner.set_color(player.player_color)
		new_player_banner.set_score(player.score)
		new_player_banner.set_health(player.health)
		new_player_banner.set_keys(player.key_count)
		new_player_banner.set_potions(player.potion_count)
		%"Player Banners".add_child(new_player_banner)

@rpc("any_peer", "call_local")
func add_character_previews() -> void:
	for preview in %"Character Previews".get_children():
		preview.queue_free()
	#print(Global.main.player_container.get_child_count())
	for player : Player in Global.main.player_container.get_children():
		var new_preview : CharacterPreview = character_preview_scene.instantiate()
		new_preview.play_animation(player.get_color_and_class())
		if (multiplayer.get_unique_id() == int(player.name)):
			new_preview.set_identifier_label("you")
			new_preview.set_identifier_label_color(player.player_color)
			new_preview.toggle_identifier_label(true)
		elif (int(player.name) == 1):
			new_preview.set_identifier_label("host")
			new_preview.reset_identifier_label_color()
			new_preview.toggle_identifier_label(true)
		else:
			new_preview.toggle_identifier_label(false)
		%"Character Previews".add_child(new_preview)

func update_player_banners() -> void:
	if (not %"Player Banners".get_child_count() == Global.main.player_container.get_child_count()):
		add_player_banners.rpc()
		return
	for i in range(%"Player Banners".get_child_count()):
		var banner : PlayerBanner = %"Player Banners".get_child(i)
		var player : Player = Global.main.player_container.get_child(i)
		banner.set_class(player.player_class)
		banner.set_color(player.player_color)
		banner.set_score(player.score)
		banner.set_health(player.health)
		banner.set_keys(player.key_count)
		banner.set_potions(player.potion_count)
		banner.set_invulnerable_effect(player.active_amulets.has(Amulet.Effect.INVULNERABILITY))
func update_character_previews() -> void:
	if (not %"Character Previews".get_child_count() == Global.main.player_container.get_child_count()):
		add_character_previews.rpc()
		return
	for i in range(%"Character Previews".get_child_count()):
		var preview : CharacterPreview = %"Character Previews".get_child(i)
		var player : Player = Global.main.player_container.get_child(i)
		preview.play_animation(player.get_color_and_class())
		if (multiplayer.get_unique_id() == int(player.name)):
			preview.set_identifier_label("you")
			preview.set_identifier_label_color(player.player_color)
			preview.toggle_identifier_label(true)
		elif (int(player.name) == 1):
			preview.set_identifier_label("host")
			preview.reset_identifier_label_color()
			preview.toggle_identifier_label(true)
		else:
			preview.toggle_identifier_label(false)
func set_player_class_and_color() -> void:
	for player : Player in Global.main.player_container.get_children():
		if (multiplayer.get_unique_id() == int(player.name)):
			for i in range(%"Class Buttons".get_child_count()):
				if (%"Class Buttons".get_child(i).button_pressed):
					player.player_class = Global.Class[%"Class Buttons".get_child(i).name.to_upper()]
					player.set_player_stats.rpc()
					break
			for i in range(%"Color Buttons".get_child_count()):
				if (%"Color Buttons".get_child(i).button_pressed):
					player.player_color = Global.PlayerColor[%"Color Buttons".get_child(i).name.to_upper()]
					break

# LEVEL TRANSITION FUNCTIONS
func set_level_label(level : int) -> void:
	%"Level Label".text = "  level " + str(level)
	%"Level Transition Label".text = "    LEVEL " + str(level)
func pick_random_tip() -> void:
	%"Tip Label".text = tips.pick_random()
@rpc("any_peer", "call_local")
func activate_level_transition(level_transitioning_to : int) -> void:
	set_level_label(level_transitioning_to)
	pick_random_tip()
	%"Title UI".hide()
	%"Level Label".show()
	%"Level Transition".show()
	%"Level Transition SFX".play()
func _on_level_transition_sfx_finished() -> void:
	%"Level Transition".hide()
	Global.main._next_level.rpc()


func _return_to_main_menu() -> void:
	if (state == State.LOBBY):
		if (multiplayer.is_server()):
			Global.player_spawner.disconnect_and_despawn_all_players()
		else:
			Global.player_spawner.despawn_and_despawn_player.rpc(multiplayer.get_unique_id())
	%Title.show()
	%Lobby.hide()
	%Join.hide()
	%Controls.hide()
	%Legend.hide()
	%Monsters.hide()
	state = State.TITLE
func _on_monsters_button_pressed() -> void:
	%Title.hide()
	%Lobby.hide()
	%Join.hide()
	%Controls.hide()
	%Legend.hide()
	%Monsters.show()
	state = State.MONSTERS
func _on_legend_button_pressed() -> void:
	%Title.hide()
	%Lobby.hide()
	%Join.hide()
	%Controls.hide()
	%Legend.show()
	%Monsters.hide()
	state = State.LEGEND
func _on_host_button_pressed() -> void:
	await get_tree().create_timer(0.1).timeout
	NetworkHandler.start_host()
	show_lobby()
	state = State.LOBBY
func _on_join_button_pressed() -> void:
	%Title.hide()
	%Lobby.hide()
	%Join.show()
	%Controls.hide()
	%Legend.hide()
	%Monsters.hide()
	
	#%"IP Address Edit".text = ""
	%"Error Label".text = ""
	
	state = State.JOIN
func _on_controls_button_pressed() -> void:
	%Title.hide()
	%Lobby.hide()
	%Join.hide()
	%Controls.show()
	%Legend.hide()
	%Monsters.hide()
	state = State.CONTROLS
func show_lobby() -> void:
	%Title.hide()
	%Lobby.show()
	%Join.hide()
	%Controls.hide()
	%Legend.hide()
	%Monsters.hide()
	
	if (multiplayer.is_server()):
		%"Start Game Button".show()
		%"Waiting For Host Label".hide()
	else:
		%"Start Game Button".hide()
		%"Waiting For Host Label".show()
	
	state = State.LOBBY

func _attempt_to_join_host() -> void:
	var address_to_check : String = %"IP Address Edit".text
	if (address_to_check.is_valid_ip_address()):
		NetworkHandler.start_client(address_to_check)
		%"Connection Timeout Timer".start()
		%"Error Label".text = "  CONNECTING..."
		%"Error Label".add_theme_color_override("font_color", Color(0.0, 0.557, 0.0, 1.0))
		%"Join Host Button".disabled = true

func _on_start_game_button_pressed() -> void:
	activate_level_transition.rpc(Global.main.current_level_num)

func _on_connected_to_server() -> void:
	%"Connection Timeout Timer".stop()
	show_lobby()
func _on_connection_failed() -> void:
	%"IP Address Edit".text = ""
	%"Error Label".text = "  FAILED!"
	%"Error Label".add_theme_color_override("font_color", Global.RED)
func _on_server_disconnected() -> void:
	_return_to_main_menu()
	%"Status Label".text = "host disconnected!"
	%"Error Label".add_theme_color_override("font_color", Global.RED)

func _on_connection_timeout_timer_timeout() -> void:
	NetworkHandler.close_multiplayer_peer()
	%"IP Address Edit".text = ""
	%"Error Label".text = "  TIMEOUT!"
	%"Error Label".add_theme_color_override("font_color", Global.RED)
