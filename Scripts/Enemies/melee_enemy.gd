class_name MeleeEnemy extends Enemy

@export var attack_cooldown_timer : Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	attack_cooldown_timer.one_shot = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
	handle_state()
	handle_behavior()
	
func handle_state() -> void:
	if (is_touching_target()):
		state = State.ATTACKING
	else:
		state = State.CHASING

func handle_behavior() -> void:
	if (state == State.CHASING):
		if (passive):
			roam()
		else:
			chase_target()
	elif (state == State.ATTACKING):
		attack()

func attack() -> void:
	if (attack_cooldown_timer.is_stopped()):
		if (stun_on_attack): target._set_stunned(true)
		target._take_damage(damage)
		attack_cooldown_timer.start(1. / attack_rate)
		total_damage_dealt += damage
