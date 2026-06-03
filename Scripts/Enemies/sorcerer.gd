class_name Sorcerer extends RangedEnemy

@export var min_invis_time : float
@export var max_invis_time : float

var invis_timer : SceneTreeTimer

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)

func handle_special_behavior() -> void:
	if (invis_timer): return
	invis_timer = get_tree().create_timer(randf_range(min_invis_time, max_invis_time))
	invis_timer.connect("timeout", _on_invis_timer_timeout)

func _on_invis_timer_timeout() -> void:
	if (invulnerable):
		invulnerable = false
		%Sprite.show()
	else:
		invulnerable = true
		%Sprite.hide()
	invis_timer = null
