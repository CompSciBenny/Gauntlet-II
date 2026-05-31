class_name Demon extends Enemy

@export var melee_attack_range : int
@export var ranged_attack_range : int
@export var shot_speed : float
@export var attack_cooldown_timer : Timer
@export var fireball_scene : PackedScene

func _ready() -> void:
	state = State.RETREATING

func _process(delta: float) -> void:
	super._process(delta)
	if (not target): return
	
	handle_state()
	handle_behavior()
	
	#print(State.keys()[state])
	#print(can_attack)

func handle_state() -> void:
	if (global_position.distance_to(target.global_position) > ranged_attack_range):
		state = State.CHASING
	elif (global_position.distance_to(target.global_position) > melee_attack_range):
		state = State.ATTACKING
	elif (global_position.distance_to(target.global_position) <= melee_attack_range):
		if (is_touching_target()): state = State.ATTACKING
		else: state = State.CHASING
		
		
func handle_behavior() -> void:
	if (state == State.CHASING):
		#print("CHASE")
		chase_target()
	elif (state == State.ATTACKING and global_position.distance_to(target.global_position) > melee_attack_range):
		#print("RANGE")
		range_attack_player()
	elif (state == State.ATTACKING and global_position.distance_to(target.global_position) <= melee_attack_range):
		#print("MELEE")
		melee_attack_player()
	elif (state == State.RETREATING):
		retreat()
	elif (state == State.IDLE):
		move_dir = Vector2.ZERO

func range_attack_player() -> void:
	move_dir = Vector2.ZERO
	if (not attack_cooldown_timer.is_stopped()): return
	for ray_cast : RayCast2D in %"Ray Casts".get_children():
		if (not ray_cast.is_colliding()): continue
		var player : Player = ray_cast.get_collider().owner
		if (player == target and global_position.distance_to(ray_cast.get_collision_point()) <= ranged_attack_range):
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

func melee_attack_player() -> void:
	move_dir = Vector2.ZERO
	if (attack_cooldown_timer.is_stopped()):
		target._take_damage(damage)
		attack_cooldown_timer.start(1. / attack_rate)
