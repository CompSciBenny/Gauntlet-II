@tool
class_name EnemySpawner extends StaticBody2D

@export var enemy_to_spawn : Global.EnemyType
@export var spawn_delay : float

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
@export var robber_scene : PackedScene
@export var mugger_scene : PackedScene

func _ready() -> void:
	update_sprite()
	%"Spawn Timer".wait_time = spawn_delay

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): update_sprite()

func get_random_available_spawn_position() -> Vector2:
	var available_spawn_areas : Array[Area2D] = []
	for area : Area2D in %"Spawn Areas".get_children():
		if area.get_overlapping_bodies().size() <= 0:
			available_spawn_areas.append(area)
	if (available_spawn_areas.size() > 0):
		var spawn_area : Area2D = available_spawn_areas.pick_random()
		return spawn_area.global_position
	return Vector2.ZERO

func spawn_enemy(spawn_position : Vector2) -> void:
	if (spawn_position == Vector2.ZERO): return
	var new_enemy : Enemy = get_enemy_scene().instantiate()
	new_enemy.global_position = spawn_position
	new_enemy.target = get_closest_player()
	Global.main.current_level.enemy_container.add_child(new_enemy)

func update_sprite() -> void:
	if (enemy_to_spawn == Global.EnemyType.GHOST):
		%Sprite.animation = "Ghost"
	else:
		%Sprite.animation = "Other"
	%Sprite.frame = health

func get_closest_player() -> Player:
	var min_dist : float = 99999
	var closest_player : Player
	for player : Player in Global.main.players:
		var player_dist : float = global_position.distance_to(player.global_position)
		if (player_dist < min_dist):
			min_dist = player_dist
			closest_player = player
	return closest_player

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
		Global.EnemyType.ROBBER:
			return robber_scene
		Global.EnemyType.MUGGER:
			return mugger_scene
	return

func _on_spawn_timer_timeout() -> void:
	spawn_enemy(get_random_available_spawn_position())

func _on_hurtbox_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
