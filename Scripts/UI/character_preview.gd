class_name CharacterPreview extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func play_animation(anim : String) -> void:
	if (%Sprite.animation == anim and %Sprite.is_playing()): return
	%Sprite.play(anim)

func toggle_identifier_label(toggled_on : bool) -> void:
	%"Identifier Label".visible = toggled_on

func set_identifier_label(identifier : String) -> void:
	%"Identifier Label".text = identifier

func reset_identifier_label_color() -> void:
	%"Identifier Label".add_theme_color_override("font_color", Global.GRAY)

func set_identifier_label_color(color : Global.PlayerColor) -> void:
	match color:
		Global.PlayerColor.GREEN:
			%"Identifier Label".add_theme_color_override("font_color", Global.GREEN)
		Global.PlayerColor.RED:
			%"Identifier Label".add_theme_color_override("font_color", Global.RED)
		Global.PlayerColor.BLUE:
			%"Identifier Label".add_theme_color_override("font_color", Global.BLUE)
		Global.PlayerColor.YELLOW:
			%"Identifier Label".add_theme_color_override("font_color", Global.YELLOW)
