@tool
class_name MonsterGenerator extends StaticBody2D

@export var enemy_to_spawn : Global.EnemyType
@export var min_spawn_delay : float
@export var max_spawn_delay : float

@export_range(0, 3, 1) var health : int

@export_group("Enemies")
@export var ghost_scene : PackedScene
@export var grunt_scene : PackedScene
@export var demon_scene : PackedScene
@export var sorcerer_scene : PackedScene
@export var lobber_scene : PackedScene
@export var death_scene : PackedScene
@export var acid_puddle_scene : PackedScene
@export var super_sorcerer_scene : PackedScene
@export var dragon_scene : PackedScene
@export var it_scene : PackedScene
@export var thief_scene : PackedScene
@export var mugger_scene : PackedScene

const SPAWN_ACTIVATION_RANGE : int = 320

func _ready() -> void:
	if Engine.is_editor_hint(): return
	update_sprite()
	%"Spawn Timer".start(randf_range(min_spawn_delay, max_spawn_delay))
	for ray_cast : RayCast2D in %"Spawn Ray Casts".get_children():
		ray_cast.add_exception(self)

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): update_sprite()

func get_random_available_spawn_position() -> Vector2:
	var available_spawn_positions : Array[Vector2] = []
	for ray_cast : RayCast2D in %"Spawn Ray Casts".get_children():
		if (ray_cast.is_colliding()): continue
		available_spawn_positions.append(global_position + (ray_cast.target_position * (2./3.)))
	if (available_spawn_positions.size() > 0):
		return available_spawn_positions.pick_random()
	return Vector2.ZERO

func spawn_enemy(spawn_position : Vector2) -> void:
	if (spawn_position == Vector2.ZERO): return
	var new_enemy_scene_path : String = "res://Scenes/Enemies/" + Global.EnemyType.keys()[enemy_to_spawn].to_lower() + ".tscn"
	if (enemy_to_spawn == Global.EnemyType.GHOST):
		Global.main._spawn_enemy.rpc(new_enemy_scene_path, spawn_position, health)
	else:
		Global.main._spawn_enemy.rpc(new_enemy_scene_path, spawn_position)

func update_sprite() -> void:
	if (enemy_to_spawn == Global.EnemyType.GHOST):
		%Sprite.animation = "Ghost"
	else:
		%Sprite.animation = "Other"
	%Sprite.frame = health

func player_within_range() -> bool:
	var min_dist : float = 99999
	for player : Player in Global.main.player_container.get_children():
		var player_dist : float = global_position.distance_to(player.global_position)
		if (player_dist <= SPAWN_ACTIVATION_RANGE):
			return true
	return false

func get_enemy_scene() -> PackedScene:
	match enemy_to_spawn:
		Global.EnemyType.GHOST:
			return ghost_scene
		Global.EnemyType.GRUNT:
			return grunt_scene
		Global.EnemyType.DEMON:
			return demon_scene
		Global.EnemyType.SORCERER:
			return sorcerer_scene
		Global.EnemyType.LOBBER:
			return lobber_scene
		Global.EnemyType.DEATH:
			return death_scene
		Global.EnemyType.ACID_PUDDLE:
			return acid_puddle_scene
		Global.EnemyType.SUPER_SORCERER:
			return super_sorcerer_scene
		Global.EnemyType.DRAGON:
			return dragon_scene
		Global.EnemyType.IT:
			return it_scene
		Global.EnemyType.THIEF:
			return thief_scene
		Global.EnemyType.MUGGER:
			return mugger_scene
	return

func _on_spawn_timer_timeout() -> void:
	if (Engine.is_editor_hint()): return
	%"Spawn Timer".start(randf_range(min_spawn_delay, max_spawn_delay))
	if (Global.main.current_level.enemy_container.get_child_count() >= Global.main.current_level.MAX_ENEMY_COUNT or not player_within_range()):
		return
	spawn_enemy(get_random_available_spawn_position())

func _take_damage(damage_to_take : int) -> void:
	health -= 1
	update_sprite()
	if (health <= 0):
		Global.main.current_level.add_floor_tile_at_pos(global_position)
		hide()
		queue_free()
