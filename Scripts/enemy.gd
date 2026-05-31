class_name Enemy extends CharacterBody2D

@export var health : int
@export var damage : int
@export var attack_rate : float
@export var speed : float

@export var passive : bool = false			# Passive enemies do not chase players, but roam randomly
@export var stun_on_attack : bool = false
@export var invulnerable : bool = false

@export var hurtbox_area : Area2D

var target : Player
var roam_target_pos : Vector2
var prev_target : Player
var move_dir : Vector2 = Vector2.ZERO
var look_dir : Vector2
var total_damage_dealt : int = 0

var state : State = State.IDLE
enum State {
	IDLE,
	CHASING,
	ATTACKING,
	RETREATING,
}

func _process(delta: float) -> void:
	if (target): prev_target = target
	target = get_closest_player()
	handle_sprite()
	if (prev_target and not target == prev_target): prev_target._set_stunned(false)	# Prevents players from being stunned indefinitely
	if (check_alternative_death_condition()): die()

func _physics_process(delta: float) -> void:
	velocity = move_dir * (speed * delta)
	move_and_collide(velocity)

func get_closest_player() -> Player:
	if (Global.main.player_container.get_child_count() <= 0): return
	var closest_player : Player = Global.main.player_container.get_child(0)
	for p : Player in Global.main.player_container.get_children():
		if (global_position.distance_to(p.global_position) < global_position.distance_to(closest_player.global_position)):
			closest_player = p
	return closest_player

func roam() -> void:
	if (not roam_target_pos): _on_roam_timer_timeout()
	%"Nav Agent".target_position = roam_target_pos
	if (not %"Nav Agent".is_target_reached()):
		move_dir = global_position.direction_to(%"Nav Agent".get_next_path_position())
	else:
		move_dir = Vector2.ZERO
func chase_target() -> void:
	%"Nav Agent".target_position = target.global_position
	if (not %"Nav Agent".is_target_reached()):
		move_dir = global_position.direction_to(%"Nav Agent".get_next_path_position())
	else:
		move_dir = Vector2.ZERO
func go_to_tile(tile_to_go_to : Vector2i) -> void:
	%"Nav Agent".target_position = Global.map_to_global(tile_to_go_to)
	if (not %"Nav Agent".is_target_reached()):
		move_dir = global_position.direction_to(%"Nav Agent".get_next_path_position())
	else:
		move_dir = Vector2.ZERO
func retreat() -> void:
	if (not target): return
	# Find retreat cell to pathfind to
	var neighbor_cells : Array[Vector2i] = Global.get_eight_neighboring_cells(Global.global_to_map(global_position), Global.main.current_level)
	var retreat_cell : Vector2i = neighbor_cells[0]
	for cell : Vector2i in neighbor_cells:
		if Global.map_to_global(cell).distance_to(target.global_position) > Global.map_to_global(retreat_cell).distance_to(target.global_position):
			retreat_cell = cell
	
	# Pathfind to current retreat cell
	go_to_tile(retreat_cell)

func handle_sprite() -> void:
	var anim_name : String = ""
	if (target and (state == State.IDLE or state == State.ATTACKING)):
		anim_name += Global.get_direction_name(global_position.direction_to(target.global_position))
	else:
		anim_name += Global.get_direction_name(move_dir)
	if (not %Sprite.animation == anim_name):
		%Sprite.play(anim_name)
	elif (not %Sprite.is_playing()):
		%Sprite.play(anim_name)

func is_touching_target() -> bool:
	for overlapping_area : Area2D in hurtbox_area.get_overlapping_areas():
		# Checks if overlapping area is on "Player" collision layer
		# If so, checks if that player is the current target
		if (overlapping_area.get_collision_layer_value(2) and overlapping_area.owner == target):
			return true
	return false

func check_alternative_death_condition() -> bool:
	return false

func die() -> void:
	target._set_stunned(false)
	hide()
	queue_free()
func _take_damage(damage_to_take : int) -> void:
	if (invulnerable): return
	health -= damage_to_take
	if (health <= 0):
		die()

func _on_roam_timer_timeout() -> void:
	roam_target_pos = Global.get_random_floor_tile_pos()
	get_tree().create_timer(randf_range(1., 2.5)).timeout.connect(_on_roam_timer_timeout)
