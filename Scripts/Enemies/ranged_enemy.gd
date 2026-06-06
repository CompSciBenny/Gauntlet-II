class_name RangedEnemy extends Enemy

@export var shot_speed : float
@export var attack_range : int
@export var attack_cooldown_timer : Timer
@export var fireball_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	attack_cooldown_timer.one_shot = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
	handle_state()
	handle_base_behavior()
	handle_special_behavior()
	
func handle_state() -> void:
	if (not target): return
	if (global_position.distance_to(target.global_position) <= attack_range and can_see_target()):
		state = State.ATTACKING
	else:
		state = State.CHASING

func handle_base_behavior() -> void:
	if (state == State.CHASING):
		if (passive):
			roam()
		else:
			chase_target()
	elif (state == State.ATTACKING):
		attack()

# Meant to be overwritten by special enemies for additonal behavior logic
func handle_special_behavior() -> void:
	pass

func attack() -> void:
	move_dir = Vector2.ZERO
	if (not attack_cooldown_timer.is_stopped()): return
	for ray_cast : RayCast2D in %"Ray Casts".get_children():
		if (not ray_cast.is_colliding() or ray_cast.get_collider().is_class("TileMapLayer")): continue
		var player : Player = ray_cast.get_collider().owner
		if (player == target and global_position.distance_to(ray_cast.get_collision_point()) <= attack_range):
			shoot_fireball(ray_cast.target_position.normalized())
			attack_cooldown_timer.start(1. / attack_rate)

func shoot_fireball(direction : Vector2) -> void:
	var new_fireball : EnemyProjectile = fireball_scene.instantiate()
	new_fireball.global_position = global_position
	
	new_fireball.damage = damage
	new_fireball.speed = shot_speed
	new_fireball.set_velocity(direction)
	
	# Determines projectile sprite and collider orientation
	new_fireball.orient_projectile()

	get_parent().get_parent().add_child(new_fireball)
