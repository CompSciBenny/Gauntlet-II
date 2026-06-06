class_name Lobber extends Enemy

@export var attack_range : int
@export var retreat_distance : int
@export var rock_scene : PackedScene

func _ready() -> void:
	super._ready()
	state = State.IDLE

func _process(delta: float) -> void:
	super._process(delta)
	if (not target or not is_instance_valid(target)): return
	
	handle_state()
	handle_behavior()

func handle_state() -> void:
	if (global_position.distance_to(target.global_position) > attack_range):
		state = State.CHASING
	elif (global_position.distance_to(target.global_position) > retreat_distance):
		state = State.ATTACKING
	else:
		state = State.RETREATING
func handle_behavior() -> void:
	if (state == State.CHASING):
		chase_target()
	elif (state == State.ATTACKING):
		attack_player()
	elif (state == State.RETREATING):
		retreat()
	elif (state == State.IDLE):
		move_dir = Vector2.ZERO

func attack_player() -> void:
	if (not %"Attack Timer".is_stopped()): return
	
	move_dir = Vector2.ZERO
	
	var new_rock : Rock = rock_scene.instantiate()
	new_rock.global_position = global_position
	new_rock.damage = damage
	new_rock.time_til_impact = 1.
	
	# Throw rock at target position if target stationary
	if (target.move_dir == Vector2.ZERO):
		new_rock.impact_position = target.global_position
		Global.main.current_level.add_child(new_rock)
	# Throw rock at future target position if target moving
	else:
		new_rock.impact_position = target.global_position + (target.velocity * new_rock.time_til_impact)
		Global.main.current_level.add_child(new_rock)
	
	%"Attack Timer".start(1. / attack_rate)
