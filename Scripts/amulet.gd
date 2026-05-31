class_name Amulet extends Area2D

@export var amulet_effect : Effect
enum Effect {
	INVISIBILITY,		# 25 seconds
	INVULNERABILITY,	# 15 seconds
	REPULSIVENESS,		# 20 SECONDS
	REFLECTIVE_SHOTS,	# lasts til end of level
	TEN_SUPER_SHOTS,	# after player has fired 10 times
	TRANSPORTABILITY,	# lasts til end of level
}

func _ready() -> void:
	if (not is_multiplayer_authority()): return
	amulet_effect = Effect.values().pick_random()
	%Sprite.play(Effect.keys()[amulet_effect])

func get_amulet_duration(amulet_effect : Effect) -> Variant:
	match amulet_effect:
		Effect.INVISIBILITY:
			return 25.				# Represents how long the effect will last (in seconds)
		Effect.INVULNERABILITY:
			return 15.				# Represents how long the effect will last (in seconds)
		Effect.REPULSIVENESS:
			return 20.				# Represents how long the effect will last (in seconds)
		Effect.REFLECTIVE_SHOTS:
			return "til exit"		# Represents the effect will wear off upon exiting the current level
		Effect.TEN_SUPER_SHOTS:
			return 10				# Represents how many super shots the player has left
		Effect.TRANSPORTABILITY:
			return "til exit"		# Represents the effect will wear off upon exiting the current level
		_:
			return
