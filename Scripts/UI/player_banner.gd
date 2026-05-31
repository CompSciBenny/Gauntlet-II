class_name PlayerBanner extends Control

@export var warrior_title_texture : CompressedTexture2D
@export var elf_title_texture : CompressedTexture2D
@export var valkyrie_title_texture : CompressedTexture2D
@export var wizard_title_texture : CompressedTexture2D
@export var key_icon_texture : CompressedTexture2D
@export var potion_icon_texture : CompressedTexture2D

var player_color : Global.PlayerColor
var player_class : Global.Class

const ITEM_LIMIT : int = 12

var invulnerable : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	handle_invulnerable_effect()
		

func add_keys(amount : int) -> void:
	for i in range(amount):
		if (at_item_limit()): return
		var new_key_icon : TextureRect = TextureRect.new()
		new_key_icon.texture = key_icon_texture
		new_key_icon.custom_minimum_size = Vector2i(16, 16)
		%"Key Slots Container".add_child(new_key_icon)
func add_potions(amount : int) -> void:
	for i in range(amount):
		if (at_item_limit()): return
		var new_potion_icon : TextureRect = TextureRect.new()
		new_potion_icon.texture = potion_icon_texture
		new_potion_icon.custom_minimum_size = Vector2i(16, 16)
		%"Key Slots Container".add_child(new_potion_icon)
func set_keys(amount : int) -> void:
	clear_keys()
	add_keys(amount)
func set_potions(amount : int) -> void:
	clear_potions()
	add_potions(amount)
func clear_keys() -> void:
	for key_icon in %"Key Slots Container".get_children():
		key_icon.queue_free()
func clear_potions() -> void:
	for potion_icon in %"Potion Slots Container".get_children():
		potion_icon.queue_free()
	
func reset() -> void:
	set_score(0)
	set_health(0)

func at_item_limit() -> bool:
	var items_counted : int = 0
	items_counted += %"Key Slots Container".get_child_count()
	items_counted += %"Potion Slots Container".get_child_count()
	if (items_counted >= ITEM_LIMIT):
		return true
	else:
		return false

func set_class(class_to_set_to : Global.Class) -> void:
	match class_to_set_to:
		Global.Class.ELF:
			%"Class Title".texture = elf_title_texture
		Global.Class.WARRIOR:
			%"Class Title".texture = warrior_title_texture
		Global.Class.VALKYRIE:
			%"Class Title".texture = valkyrie_title_texture
		Global.Class.WIZARD:
			%"Class Title".texture = wizard_title_texture
func set_color(color_to_set_to : Global.PlayerColor) -> void:
	match color_to_set_to:
		Global.PlayerColor.BLUE:
			%"Player Banner".self_modulate = Global.BLUE
			%"Score Label".modulate = Global.BLUE
			if (not invulnerable): %"Health Label".modulate = Global.BLUE
			%"Class Title".modulate = Global.BLUE
		Global.PlayerColor.GREEN:
			%"Player Banner".self_modulate = Global.GREEN
			%"Score Label".modulate = Global.GREEN
			if (not invulnerable): %"Health Label".modulate = Global.GREEN
			%"Class Title".modulate = Global.GREEN
		Global.PlayerColor.RED:
			%"Player Banner".self_modulate = Global.RED
			%"Score Label".modulate = Global.RED
			if (not invulnerable): %"Health Label".modulate = Global.RED
			%"Class Title".modulate = Global.RED
		Global.PlayerColor.YELLOW:
			%"Player Banner".self_modulate = Global.YELLOW
			%"Score Label".modulate = Global.YELLOW
			if (not invulnerable): %"Health Label".modulate = Global.YELLOW
			%"Class Title".modulate = Global.YELLOW
func set_score(new_score : int) -> void:
	%"Score Label".text = str(new_score)
func set_health(new_health : int) -> void:
	%"Health Label".text = str(new_health)

func set_invulnerable_effect(is_invulnerable : bool) -> void:
	invulnerable = is_invulnerable
func handle_invulnerable_effect() -> void:
	if (invulnerable and %"Invulnerable Blink Effect Timer".is_stopped()):
		%"Health Label".modulate = Color.WHITE
		%"Invulnerable Blink Effect Timer".start()
	elif (not invulnerable):
		%"Health Label".show()
		%"Invulnerable Blink Effect Timer".stop()

func _on_invulnerable_blink_effect_timer_timeout() -> void:
	%"Health Label".visible = not %"Health Label".visible
