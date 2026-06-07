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
	GAME,
	PAUSE,
	GAME_OVER,
}

func _ready() -> void:
	Global.ui = self
	hide_all()
	%"Menu Music".play()
	%"Title UI".show()
	_return_to_main_menu()
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	%"Status Label".text = ""
	
func _process(delta: float) -> void:
	# Deal with pausing the game
	if (Input.is_action_just_pressed("pause") and state == State.GAME):
		%"Player Banners".hide()
		%Pause.show()
		if (Global.main.get_player_count() <= 1): get_tree().paused = true
		state = State.PAUSE
	elif (Input.is_action_just_pressed("pause") and state == State.PAUSE):
		%"Player Banners".show()
		%Pause.hide()
		get_tree().paused = false
		state = State.GAME
		
	#print(State.keys()[state])
		
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
	clear_player_banners()
	#print(Global.main.get_player_count())
	for player : Player in Global.main.player_container.get_children():
		var new_player_banner : PlayerBanner = player_banner_scene.instantiate()
		new_player_banner.player = player
		new_player_banner.set_class()
		new_player_banner.set_color()
		new_player_banner.set_score()
		new_player_banner.set_health()
		new_player_banner.set_keys()
		new_player_banner.set_potions()
		%"Player Banners".add_child(new_player_banner)
@rpc("any_peer", "call_local")
func add_character_previews() -> void:
	clear_character_previews()
	#print(Global.main.get_player_count())
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
func clear_player_banners() -> void:
	for banner in %"Player Banners".get_children():
		banner.queue_free()
func clear_character_previews() -> void:
	for preview in %"Character Previews".get_children():
		preview.queue_free()

func update_player_banners() -> void:
	if (not %"Player Banners".get_child_count() == Global.main.get_player_count()):
		add_player_banners.rpc()
		return
	for banner in %"Player Banners".get_children():
		banner.set_class()
		banner.set_color()
		banner.set_score()
		banner.set_health()
		banner.set_keys()
		banner.set_potions()
		banner.set_invulnerable_effect()
func update_character_previews() -> void:
	if (not %"Character Previews".get_child_count() == Global.main.get_player_count()):
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
	%"Menu Music".stop()
	set_level_label(level_transitioning_to)
	pick_random_tip()
	%"Title UI".hide()
	%"Level Label".show()
	%"Level Transition".show()
	%"Level Transition SFX".play()
	if (not state == State.PAUSE): state = State.GAME
func _on_level_transition_sfx_finished() -> void:
	%"Level Transition".hide()
	if (state == State.GAME or state == State.PAUSE):
		Global.main._next_level.rpc()

func set_up_game_over_screen() -> void:
	var party_score : int = 0
	for i in range(Global.PLAYER_LIMIT):
		if ((i+1) <= Global.main.get_player_count()):
			%"Player Classes and Colors".get_child(i).text = Global.main.player_container.get_child(i).get_color_and_class()
			%"Player Scores".get_child(i).text = str(Global.main.player_container.get_child(i).score)
			match Global.main.player_container.get_child(i).player_color:
				Global.PlayerColor.BLUE:
					%"Player Classes and Colors".get_child(i).add_theme_color_override("font_color", Global.BLUE)
					%"Player Scores".get_child(i).add_theme_color_override("font_color", Global.BLUE)
				Global.PlayerColor.GREEN:
					%"Player Classes and Colors".get_child(i).add_theme_color_override("font_color", Global.GREEN)
					%"Player Scores".get_child(i).add_theme_color_override("font_color", Global.GREEN)
				Global.PlayerColor.RED:
					%"Player Classes and Colors".get_child(i).add_theme_color_override("font_color", Global.RED)
					%"Player Scores".get_child(i).add_theme_color_override("font_color", Global.RED)
				Global.PlayerColor.YELLOW:
					%"Player Classes and Colors".get_child(i).add_theme_color_override("font_color", Global.YELLOW)
					%"Player Scores".get_child(i).add_theme_color_override("font_color", Global.YELLOW)
			party_score += Global.main.player_container.get_child(i).score
		else:
			%"Player Classes and Colors".get_child(i).text = ""
			%"Player Scores".get_child(i).text = ""
	%"Party Score Number Label".text = str(party_score)
func _return_to_main_menu() -> void:
	get_tree().paused = false
	if (state == State.LOBBY or state == State.PAUSE or state == State.GAME):
		if (multiplayer.is_server()):
			Global.player_spawner.disconnect_and_despawn_all_players()
		else:
			Global.player_spawner.disconnect_and_despawn_player.rpc(multiplayer.get_unique_id())
	hide_all()
	%"Title UI".show()
	%Title.show()
	clear_player_banners()
	clear_character_previews()
	if (state == State.GAME or state == State.PAUSE):
		#Global.main._spawn_lobby.rpc()
		Global.main.delete_all_enemies()
		Global.main.delete_current_level()
	state = State.TITLE
func _on_monsters_button_pressed() -> void:
	hide_all()
	%Monsters.show()
	state = State.MONSTERS
func _on_legend_button_pressed() -> void:
	hide_all()
	%Legend.show()
	state = State.LEGEND
func _on_host_button_pressed() -> void:
	Global.main.spawn_lobby()
	await get_tree().create_timer(0.1).timeout
	NetworkHandler.start_host()
	show_lobby()
	state = State.LOBBY
func _on_join_button_pressed() -> void:
	Global.main.spawn_lobby()
	hide_all()
	%Join.show()
	
	#%"IP Address Edit".text = ""
	%"Error Label".text = ""
	
	state = State.JOIN
func _on_controls_button_pressed() -> void:
	hide_all()
	%Controls.show()
	state = State.CONTROLS
func show_lobby() -> void:
	hide_all()
	%Lobby.show()
	
	if (multiplayer.is_server()):
		%"Start Game Button".show()
		%"Waiting For Host Label".hide()
	else:
		%"Start Game Button".hide()
		%"Waiting For Host Label".show()
	
	%"Player Banners".show()
	
	state = State.LOBBY
func show_game_over() -> void:
	hide_all()
	%"Game Over".show()
	state = State.GAME_OVER
func hide_all() -> void:
	%Title.hide()
	%Lobby.hide()
	%Join.hide()
	%Controls.hide()
	%Legend.hide()
	%Monsters.hide()
	%Pause.hide()
	%"Game Over".hide()
	%"Level Label".hide()
	%"Level Transition".hide()

func _attempt_to_join_host() -> void:
	var address_to_check : String = %"IP Address Edit".text
	if (address_to_check.is_valid_ip_address()):
		NetworkHandler.start_client(address_to_check)
		%"Connection Timeout Timer".start()
		%"Error Label".text = "  CONNECTING..."
		%"Error Label".add_theme_color_override("font_color", Color(0.0, 0.557, 0.0, 1.0))
		%"Join Host Button".disabled = true

func _on_start_game_button_pressed() -> void:
	for p1 in Global.main.players:
		for p2 in Global.main.players:
			if (p1 == p2): continue
			if (p1.player_color == p2.player_color):
				%"Status Label".text = "cant start! players cannot share color!"
				return
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


func _on_resume_button_pressed() -> void:
	if (state == State.PAUSE):
		%"Player Banners".show()
		%Pause.hide()
		get_tree().paused = false
		state = State.GAME

func _close_game() -> void:
	if (multiplayer.is_server()):
		Global.player_spawner.disconnect_and_despawn_all_players()
	else:
		Global.player_spawner.disconnect_and_despawn_player.rpc(multiplayer.get_unique_id())
	get_tree().quit()
func _notification(what):
	if (what == NOTIFICATION_WM_CLOSE_REQUEST):
		_close_game()
