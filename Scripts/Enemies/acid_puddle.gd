class_name AcidPuddle extends MeleeEnemy

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)

func check_alternative_death_condition() -> bool:
	if (total_damage_dealt >= 75):
		return true
	return false
