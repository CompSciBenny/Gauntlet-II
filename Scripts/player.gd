class_name Player extends CharacterBody2D

@export var player_class : Global.Class
@export var player_color : Global.PlayerColor
@export var health : int = 500
@export var score : int = 0
@export var key_count : int = 0
@export var potion_count : int = 0
@export var post_shot_time : float
@export var projectile_scene : PackedScene

# Player stats decided by player class
@export var shot_power : float
@export var shot_speed : float
@export var speed : float
@export var armor : float
@export var fight_power : float
@export var magic_power : float

var look_dir : Vector2
var move_dir : Vector2
var last_nonzero_move_dir : Vector2
var transport_pos : Vector2
var force_field_damage_timer : SceneTreeTimer

@export var active_amulets : Array[Amulet.Effect] = []
@export var amulet_durations : Array[Variant] = []

@export var state : State	# Set as export so it can be synced across clients. Makes sure the level knows if all players have EXITING state. Bad solution...
enum State {
	IDLE,
	MOVING,
	STARTING_SHOT,
	SHOOTING,
	EXITING,
	TRANSPORTING,
	FROZEN,			# Player can turn around and shoot
	STUNNED,		# Player can't do anything
	DEAD,
}

var in_lobby : bool = true
var player_spectating : Player = self
signal exited_level

func _ready() -> void:
	Global.ui.add_player_banners.rpc()
	Global.ui.add_character_previews.rpc()
	exited_level.connect(Global.main._check_for_level_transition.rpc)

	if (not is_multiplayer_authority()):
		#%Sprite.modulate = Color.INDIAN_RED
		%Camera.enabled = false
		return

	player_class = Global.Class.values().pick_random()
	player_color = Global.PlayerColor.values().pick_random()
	set_player_stats.rpc()

	move_dir = Vector2.RIGHT
	last_nonzero_move_dir = move_dir
	handle_sprite()
	move_dir = Vector2.ZERO

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _process(delta: float) -> void:
	update_debug_panel()
	if (not is_multiplayer_authority() or state == State.EXITING or state == State.TRANSPORTING or state == State.STUNNED): return
	
	# Spectate a player if dead
	if (state == State.DEAD and is_instance_valid(player_spectating)):
		if (player_spectating.state == State.DEAD): choose_random_player_to_spectate()
		%Camera.global_position = player_spectating.global_position
		return
	
	if (Input.is_action_just_released("shoot")):
		shoot.rpc(look_dir)
	if (Input.is_action_just_pressed("bomb_potion")):
		use_bomb_potion.rpc()

	handle_state()
	calculate_look_dir()	# Must be called before handle_sprite()
	handle_sprite()
	handle_amulets(delta)	# Takes delta to keep track of time
	if (is_on_trap_tile()):
		Global.main.current_level._activate_trap.rpc("trap", Global.global_to_map(global_position))
	if (is_on_stun_tile()):
		Global.main.current_level._activate_trap.rpc("stun", Global.global_to_map(global_position))
		%Sprite.stop()
		state = State.STUNNED
		get_tree().create_timer(Global.main.current_level.STUN_TILE_EFFECT_TIME).connect("timeout", func (): state = State.IDLE)
	if (is_on_force_field_tile() and not force_field_damage_timer and Global.main.current_level.force_field_tiles_active(Global.global_to_map(global_position))):
		_take_damage(Global.main.current_level.FORCE_FIELD_DAMAGE)
		force_field_damage_timer = get_tree().create_timer(1. / Global.main.current_level.FORCE_FIELD_DAMAGE_RATE)
		force_field_damage_timer.connect("timeout", func (): force_field_damage_timer = null)
	
	# Treat collectibles as solid walls if item limit reached
	set_collision_mask_value(6, key_count + potion_count >= Global.ITEM_LIMIT)
		
func _physics_process(delta: float) -> void:
	if (not is_multiplayer_authority() or state == State.EXITING or state == State.TRANSPORTING): return
	
	if (not move_dir == Vector2.ZERO): last_nonzero_move_dir = move_dir
	if (state == State.STARTING_SHOT or state == State.SHOOTING or state == State.FROZEN or state == State.STUNNED or state == State.DEAD):
		move_dir = Vector2.ZERO
	else:
		move_dir = Input.get_vector("left", "right", "up", "down")
		
	#velocity = move_dir * (speed * delta)
	#move_and_collide(velocity)
	
	velocity = move_dir * speed
	move_and_slide()

@rpc("authority", "call_local")
func set_player_stats() -> void:
	var player_class_stats : Dictionary = Global.player_class_stats.get(Global.Class.keys()[player_class].to_lower())
	shot_power = player_class_stats.get("shot_power")
	shot_speed = player_class_stats.get("shot_speed")
	speed = player_class_stats.get("speed")
	armor = player_class_stats.get("armor")
	fight_power = player_class_stats.get("fight_power")
	magic_power = player_class_stats.get("magic_power")

@rpc("call_local")
func shoot(bullet_move_dir : Vector2) -> void:
	var new_projectile : Projectile = projectile_scene.instantiate()
	new_projectile.global_position = global_position
	
	new_projectile.player_color_and_class_string = get_color_and_class()
	new_projectile.damage = shot_power
	new_projectile.speed = shot_speed
	if (active_amulets.has(Amulet.Effect.REFLECTIVE_SHOTS)): new_projectile.is_reflective = true
	if (active_amulets.has(Amulet.Effect.TEN_SUPER_SHOTS)):
		new_projectile.is_super = true
		var effect_index : int = active_amulets.find(Amulet.Effect.TEN_SUPER_SHOTS)
		amulet_durations[effect_index] -= 1
	new_projectile.set_velocity(bullet_move_dir)
	
	new_projectile.owner_id = name.to_int()
	get_parent().get_parent().add_child(new_projectile)
	%"Post Shot Timer".start(post_shot_time)
	%"Shoot SFX".play()
@rpc("call_local")
func use_bomb_potion() -> void:
	if (potion_count <= 0): return
	for area : Area2D in %"Potion Hurtbox Area".get_overlapping_areas():
		var enemy = area.owner
		enemy.hide()
		enemy.queue_free()
	potion_count -= 1
	Global.ui._activate_bomb_potion_flash()
	%"Bomb Potion SFX".play()

func handle_state() -> void:
	if (state == State.TRANSPORTING or state == State.FROZEN): return
	if (is_on_exit_tile() and not state == State.EXITING):
		state = State.EXITING
		exit_level()
	elif (move_dir == Vector2.ZERO and not Input.is_action_pressed("shoot") and %"Post Shot Timer".is_stopped()):
		state = State.IDLE
	elif (not move_dir == Vector2.ZERO and not Input.is_action_pressed("shoot") and %"Post Shot Timer".is_stopped()):
		state = State.MOVING
	elif (Input.is_action_pressed("shoot")):
		state = State.STARTING_SHOT
	elif (not Input.is_action_pressed("shoot") and not %"Post Shot Timer".is_stopped()):
		state = State.SHOOTING
	#print(State.keys()[state])
func handle_sprite() -> void:
	var anim_name : String = ""
	anim_name += get_color_and_class() + " "
	if (state == State.IDLE or state == State.FROZEN or state == State.STUNNED):
		anim_name += Global.get_direction_name(look_dir)
		%Sprite.animation = anim_name
		%Sprite.stop()
		return
	elif (state == State.MOVING):
		anim_name += Global.get_direction_name(move_dir)
	elif (state == State.STARTING_SHOT):
		anim_name += Global.get_direction_name(look_dir)
		%Sprite.animation = anim_name
		%Sprite.frame = 1
		%Sprite.stop()
		return
	elif (state == State.SHOOTING):
		%Sprite.frame = 3
		return
	if (not %Sprite.animation == anim_name):
		%Sprite.play(anim_name)
	elif (not %Sprite.is_playing()):
		%Sprite.play(anim_name)
func calculate_look_dir() -> void:
	var angle_to_mouse : float = rad_to_deg(self.get_angle_to(get_global_mouse_position()))
	if (angle_to_mouse > 0):
		angle_to_mouse -= 360
	angle_to_mouse *= -1
	
	if (angle_to_mouse < (45./2.) or angle_to_mouse > 360-(45./2.)):
		look_dir = Vector2(1,0)
	elif (angle_to_mouse < 45 + (45./2.) and angle_to_mouse > (45./2.)):
		look_dir = Vector2(1,-1).normalized()
	elif (angle_to_mouse < 90 + (45./2.) and angle_to_mouse > 45 + (45./2.)):
		look_dir = Vector2(0,-1)
	elif (angle_to_mouse < 135 + (45./2.) and angle_to_mouse > 90 + (45./2.)):
		look_dir = Vector2(-1,-1).normalized()
	elif (angle_to_mouse < 180 + (45./2.) and angle_to_mouse > 135 + (45./2.)):
		look_dir = Vector2(-1,0)
	elif (angle_to_mouse < 225 + (45./2.) and angle_to_mouse > 180 + (45./2.)):
		look_dir = Vector2(-1,1).normalized()
	elif (angle_to_mouse < 270 + (45./2.) and angle_to_mouse > 225 + (45./2.)):
		look_dir = Vector2(0,1)
	elif (angle_to_mouse < 315 + (45./2.) and angle_to_mouse > 270 + (45./2.)):
		look_dir = Vector2(1,1).normalized()

# Called by enemies sometimes
func _take_damage(damage_to_take : int) -> void:
	if (not is_multiplayer_authority() or state == State.DEAD): return
	health -= damage_to_take
	if (health <= 0):
		health = 0
		die.rpc()

# STEPPING ON TRAP TILES
func is_on_trap_tile() -> bool:
	if (not is_instance_valid(Global.main.current_level)): return false
	var current_tile_data : TileData = Global.main.current_level.trap_layer.get_cell_tile_data(Global.global_to_map(global_position))
	if (current_tile_data == null): return false
	return current_tile_data.get_custom_data("trap_type") == "trap"
func is_on_stun_tile() -> bool:
	if (not is_instance_valid(Global.main.current_level)): return false
	var current_tile_data : TileData = Global.main.current_level.trap_layer.get_cell_tile_data(Global.global_to_map(global_position))
	if (current_tile_data == null): return false
	return current_tile_data.get_custom_data("trap_type") == "stun"
func is_on_force_field_tile() -> bool:
	if (not is_instance_valid(Global.main.current_level)): return false
	var current_tile_data : TileData = Global.main.current_level.trap_layer.get_cell_tile_data(Global.global_to_map(global_position))
	if (current_tile_data == null): return false
	return current_tile_data.get_custom_data("trap_type") == "force_field"

# ENTERING AND EXITING LEVELS
func is_on_exit_tile() -> bool:
	if (not is_instance_valid(Global.main.current_level)): return false
	var current_tile_data : TileData = Global.main.current_level.ground_layer.get_cell_tile_data(Global.global_to_map(global_position))
	if (current_tile_data == null): return false
	#print(current_tile_data.get_custom_data("exit"))
	return current_tile_data.get_custom_data("exit")
func exit_level() -> void:
	var player_exit_pos : Vector2 = Global.map_to_global(Global.global_to_map(global_position))
	var camera_exit_pos : Vector2 = global_position - player_exit_pos
	global_position = player_exit_pos
	
	# Prevents the camera from snapping to the exit position (because it's jarring)
	%Camera.position = camera_exit_pos
	
	set_colliders(false)
	%"Exit SFX".play()
	%Sprite.play(get_color_and_class() + " Exit")
func enter_level(spawn_position : Vector2) -> void:
	global_position = spawn_position
	
	# Centers the camera back on the player
	%Camera.position = Vector2.ZERO
	
	in_lobby = false
	set_colliders(true)
	state = State.IDLE
func set_colliders(enabled : bool) -> void:
	%Collider.disabled = not enabled
	%"Hurtbox Collider".disabled = not enabled

# HURTBOX INTERFERENCE LOGIC
func _on_hurtbox_body_entered(body: Node2D) -> void:
	if (not is_multiplayer_authority() or not body.is_class("TileMapLayer") or not is_instance_valid(Global.main.current_level)): return
	print(body)
	var layer : TileMapLayer = body
	var solid_tile_coords : Array[Vector2i] = layer.get_surrounding_cells(Global.global_to_map(global_position))
	for tile_coords in solid_tile_coords:
		var data : TileData = layer.get_cell_tile_data(tile_coords)
		if (not data == null and data.get_custom_data("door")):
			if (active_amulets.has(Amulet.Effect.TRANSPORTABILITY)):
				transport(Global.main.current_level._get_transportable_position(global_position, move_dir))
			elif (key_count > 0):
				key_count -= 1
				Global.main.current_level._unlock_door.rpc(tile_coords)
				return
		elif (not data == null and data.get_custom_data("transporter")):
			transport(Global.main.current_level._get_transporter_destination(tile_coords))
			return
		elif (active_amulets.has(Amulet.Effect.TRANSPORTABILITY)):
			transport(Global.main.current_level._get_transportable_position(global_position, move_dir))
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if (key_count + potion_count >= Global.ITEM_LIMIT or not is_instance_valid(Global.main.current_level)): return
	if (area.is_in_group("key")):
		area.owner.queue_free()
		if (not is_multiplayer_authority()): return
		key_count += 1
		score += 100
		Global.main.current_level.add_floor_tile_at_pos.rpc(area.owner.global_position)
		%"Key SFX".play()
		print("Collected key!")
	elif (area.is_in_group("potion")):
		area.owner.queue_free()
		if (not is_multiplayer_authority()): return
		potion_count += 1
		Global.main.current_level.add_floor_tile_at_pos.rpc(area.owner.global_position)
		%"Collect SFX".play()
		print("Collected potion!")
	elif (area.is_in_group("treasure")):
		area.queue_free()
		if (not is_multiplayer_authority()): return
		score += 100
		Global.main.current_level.add_floor_tile_at_pos.rpc(area.global_position)
		%"Collect SFX".play()
		print("Collected treasure!")
	elif (area.is_in_group("food")):
		area.queue_free()
		if (not is_multiplayer_authority()): return
		health += 100
		score += 100
		Global.main.current_level.add_floor_tile_at_pos.rpc(area.global_position)
		%"Food SFX".play()
		print("Collected food!")
	elif (area.is_in_group("amulet")):
		var amulet : Amulet = area
		var amulet_effect : Amulet.Effect = amulet.amulet_effect
		var amulet_duration : Variant = amulet.get_amulet_duration(amulet_effect)
		area.queue_free()
		if (not is_multiplayer_authority()): return
		Global.main.current_level.add_floor_tile_at_pos.rpc(area.global_position)
		collect_amulet(amulet_effect, amulet_duration)
		#%"Food SFX".play()
		print("Collected amulet!")

# AMULET HANDLING
func collect_amulet(amulet_effect : Amulet.Effect, amulet_duration : Variant) -> void:
	if (not active_amulets.has(amulet_effect)):
		active_amulets.append(amulet_effect)
		amulet_durations.append(amulet_duration)
	else:
		amulet_durations[active_amulets.find(amulet_effect)] = amulet_duration
func handle_amulets(delta : float) -> void:
	var amulets_to_remove : Array[int] = []
	
	if (state == State.EXITING):
		active_amulets.clear()
		amulet_durations.clear()
	
	# INVISIBILITY
	if (active_amulets.has(Amulet.Effect.INVISIBILITY)):
		var index : int = active_amulets.find(Amulet.Effect.INVISIBILITY)
		if (amulet_durations[index] <= 0):
			amulets_to_remove.append(index)
		else:
			if (%"Invis Blink Timer".is_stopped()): %"Invis Blink Timer".start()
			amulet_durations[index] -= delta
	else:
		%"Invis Blink Timer".stop()
		%Sprite.show()
		
	# INVULNERABILITY
	if (active_amulets.has(Amulet.Effect.INVULNERABILITY)):
		var index : int = active_amulets.find(Amulet.Effect.INVULNERABILITY)
		if (amulet_durations[index] <= 0):
			amulets_to_remove.append(index)
		elif (not %"Health Timer".wait_time == 1./15. or %"Health Timer".is_stopped()):
			%"Health Timer".start(1./15.)
		else:
			amulet_durations[index] -= delta
	elif (not %"Health Timer".wait_time == 1. or %"Health Timer".is_stopped()):
		%"Health Timer".start(1.)
	
	# REPULSIVENESS
	if (active_amulets.has(Amulet.Effect.REPULSIVENESS)):
		var index : int = active_amulets.find(Amulet.Effect.REPULSIVENESS)
		if (amulet_durations[index] <= 0):
			amulets_to_remove.append(index)
		else:
			amulet_durations[index] -= delta
			
	# REFLECTIVE_SHOTS
	pass
	
	# TEN_SUPER_SHOTS
	if (active_amulets.has(Amulet.Effect.TEN_SUPER_SHOTS)):
		var index : int = active_amulets.find(Amulet.Effect.TEN_SUPER_SHOTS)
		if (amulet_durations[index] <= 0):
			amulets_to_remove.append(index)
	
	# TRANSPORTABILITY
	pass
	
	for amulet_index : int in amulets_to_remove:
		active_amulets.remove_at(amulet_index)
		amulet_durations.remove_at(amulet_index)

func transport(new_transport_pos : Vector2) -> void:
	state = State.TRANSPORTING
	transport_pos = new_transport_pos
	set_colliders(false)
	%"Teleport SFX".play()
	%Sprite.play("Transport")

func update_debug_panel() -> void:
	%"Health Label".text = "Health: " + str(health)
	%"Keys Label".text = "Keys: " + str(key_count)

# Called by enemies that stun the player (Death, Acid Puddle, etc.)
func _set_frozen(is_frozen : bool) -> void:
	if (is_frozen):
		state = State.FROZEN
	else:
		state = State.IDLE

func _on_sprite_animation_finished() -> void:
	if (not is_multiplayer_authority()): return
	if (%Sprite.animation == get_color_and_class() + " Exit" and state == State.EXITING):
		exited_level.emit()
	elif (%Sprite.animation == "Transport" and state == State.TRANSPORTING):
		if (not transport_pos == Vector2(-1,-1)):
			global_position = transport_pos
			transport_pos = Vector2(-1,-1)
			%Sprite.play("Transport")
		else:
			set_colliders(true)
			state = State.IDLE

func get_color_and_class() -> String:
	var player_color_string : String = Global.PlayerColor.keys()[player_color].to_lower().capitalize()
	var player_class_string : String = Global.Class.keys()[player_class].to_lower().capitalize()
	return player_color_string + " " + player_class_string

@rpc("call_local")
func die() -> void:
	set_colliders(false)
	hide()
	choose_random_player_to_spectate()
	state = State.DEAD
func choose_random_player_to_spectate() -> void:
	for player : Player in Global.main.player_container.get_children():
		if (player == self or player.state == State.DEAD): continue
		player_spectating = player
		break

# TIMER TIMEOUTS
func _on_health_timer_timeout() -> void:
	if (not is_multiplayer_authority() or state == State.EXITING or in_lobby): return
	_take_damage(1)
func _on_invis_timer_timeout() -> void:
	%Sprite.visible = not %Sprite.visible
