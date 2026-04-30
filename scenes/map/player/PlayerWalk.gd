extends CharacterBody2D
## 仅行走：四向 Sprout Lands 角色帧（无工具动画）

const SPEED := 220.0
const WALK_FPS := 9.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_build_sprite_frames()
	_sprite.play(&"down")
	_sprite.stop()
	y_sort_enabled = true


func _build_sprite_frames() -> void:
	var fr := SpriteFrames.new()
	var dirs := { "down": 4, "left": 4, "right": 4, "up": 2 }
	for anim: String in dirs:
		var count: int = dirs[anim]
		fr.add_animation(anim)
		fr.set_animation_speed(anim, WALK_FPS)
		fr.set_animation_loop(anim, true)
		for i in count:
			var path := "res://assets/sprout-lands/graphics/character/%s/%d.png" % [anim, i]
			var img := Image.new()
			if img.load(path) != OK:
				push_error("PlayerWalk: missing %s" % path)
				continue
			var tex := ImageTexture.create_from_image(img)
			fr.add_frame(anim, tex)
	_sprite.sprite_frames = fr
	_sprite.animation = &"down"


func _physics_process(_delta: float) -> void:
	var dir := _read_move_vector()
	if dir.length_squared() > 0.0001:
		velocity = dir.normalized() * SPEED
		_set_facing_anim(dir)
		if not _sprite.is_playing():
			_sprite.play()
	else:
		velocity = Vector2.ZERO
		_sprite.stop()
		_sprite.frame = 0

	move_and_slide()
	var map_root := get_parent().get_parent()
	if map_root.has_method(&"clamp_player_world_position"):
		global_position = map_root.clamp_player_world_position(global_position)


func _read_move_vector() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_action_pressed(&"ui_left") or Input.is_physical_key_pressed(KEY_A):
		v.x -= 1
	if Input.is_action_pressed(&"ui_right") or Input.is_physical_key_pressed(KEY_D):
		v.x += 1
	if Input.is_action_pressed(&"ui_up") or Input.is_physical_key_pressed(KEY_W):
		v.y -= 1
	if Input.is_action_pressed(&"ui_down") or Input.is_physical_key_pressed(KEY_S):
		v.y += 1
	return v


func _set_facing_anim(dir: Vector2) -> void:
	var anim: StringName
	if absf(dir.x) >= absf(dir.y):
		anim = &"right" if dir.x > 0 else &"left"
		_sprite.flip_h = false
	else:
		anim = &"down" if dir.y > 0 else &"up"
	if _sprite.animation != anim:
		_sprite.animation = anim
		_sprite.frame = 0
