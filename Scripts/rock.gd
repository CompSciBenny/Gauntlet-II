class_name Rock extends Area2D

var damage : int
var impact_position : Vector2
var time_til_impact : float

var impact_distance : float

func _ready() -> void:
	print("Im a rock!")
	%Sprite.speed_scale = (%Sprite.sprite_frames.get_frame_count("Rock") / time_til_impact) / %Sprite.sprite_frames.get_animation_speed("Rock")
	%Sprite.play("Rock")
	
	%"Lob SFX".play()
	%"Hurtbox Collider".disabled = true
	
	impact_distance = global_position.distance_to(impact_position)
	
	# Move rock to impact position
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", impact_position, time_til_impact)
	tween.tween_callback(impact)

func impact() -> void:
	%"Hurtbox Collider".disabled = false
	%Sprite.speed_scale = 1.
	%Sprite.play("Impact")

func _on_sprite_animation_finished() -> void:
	if (not %Sprite.animation == "Impact"): return
	hide()
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	var target : Player = area.owner
	target._take_damage(damage)
