extends CharacterBody2D
## 仅行走：四向 Sprout Lands 角色帧（无工具动画）
## 输入：键盘 WASD / 方向键；手柄左摇杆 + 十字键（已连接的手柄）

const SPEED := 220.0
const WALK_FPS := 9.0
const STICK_DEADZONE := 0.25

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_ensure_move_actions()
	_build_sprite_frames()
	_sprite.play(&"down")
	_sprite.stop()
	y_sort_enabled = true


func _ensure_move_actions() -> void:
	if InputMap.has_action(&"move_left"):
		return
	for a: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		InputMap.add_action(a, 0.2)

	var ev := func(k: Key) -> InputEventKey:
		var e := InputEventKey.new()
		e.physical_keycode = k
		return e

	InputMap.action_add_event(&"move_left", ev.call(KEY_A))
	InputMap.action_add_event(&"move_left", ev.call(KEY_LEFT))
	InputMap.action_add_event(&"move_right", ev.call(KEY_D))
	InputMap.action_add_event(&"move_right", ev.call(KEY_RIGHT))
	InputMap.action_add_event(&"move_up", ev.call(KEY_W))
	InputMap.action_add_event(&"move_up", ev.call(KEY_UP))
	InputMap.action_add_event(&"move_down", ev.call(KEY_S))
	InputMap.action_add_event(&"move_down", ev.call(KEY_DOWN))

	for joy in range(8):
		var jl := InputEventJoypadButton.new()
		jl.device = joy
		jl.button_index = JOY_BUTTON_DPAD_LEFT
		InputMap.action_add_event(&"move_left", jl)
		var jr := InputEventJoypadButton.new()
		jr.device = joy
		jr.button_index = JOY_BUTTON_DPAD_RIGHT
		InputMap.action_add_event(&"move_right", jr)
		var ju := InputEventJoypadButton.new()
		ju.device = joy
		ju.button_index = JOY_BUTTON_DPAD_UP
		InputMap.action_add_event(&"move_up", ju)
		var jd := InputEventJoypadButton.new()
		jd.device = joy
		jd.button_index = JOY_BUTTON_DPAD_DOWN
		InputMap.action_add_event(&"move_down", jd)

		var ax_neg := InputEventJoypadMotion.new()
		ax_neg.device = joy
		ax_neg.axis = JOY_AXIS_LEFT_X
		ax_neg.axis_value = -1.0
		InputMap.action_add_event(&"move_left", ax_neg)
		var ax_pos := InputEventJoypadMotion.new()
		ax_pos.device = joy
		ax_pos.axis = JOY_AXIS_LEFT_X
		ax_pos.axis_value = 1.0
		InputMap.action_add_event(&"move_right", ax_pos)
		var ay_neg := InputEventJoypadMotion.new()
		ay_neg.device = joy
		ay_neg.axis = JOY_AXIS_LEFT_Y
		ay_neg.axis_value = -1.0
		InputMap.action_add_event(&"move_up", ay_neg)
		var ay_pos := InputEventJoypadMotion.new()
		ay_pos.device = joy
		ay_pos.axis = JOY_AXIS_LEFT_Y
		ay_pos.axis_value = 1.0
		InputMap.action_add_event(&"move_down", ay_pos)


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
	if InventoryManager.player_input_blocked:
		velocity = Vector2.ZERO
		_sprite.stop()
		_sprite.frame = 0
		move_and_slide()
		var map_root := get_parent().get_parent()
		if map_root.has_method(&"clamp_player_world_position"):
			global_position = map_root.clamp_player_world_position(global_position)
		return

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
	var v := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if v.length_squared() > STICK_DEADZONE * STICK_DEADZONE:
		return v.limit_length(1.0)

	var kb := Vector2.ZERO
	if Input.is_action_pressed(&"ui_left") or Input.is_physical_key_pressed(KEY_A):
		kb.x -= 1.0
	if Input.is_action_pressed(&"ui_right") or Input.is_physical_key_pressed(KEY_D):
		kb.x += 1.0
	if Input.is_action_pressed(&"ui_up") or Input.is_physical_key_pressed(KEY_W):
		kb.y -= 1.0
	if Input.is_action_pressed(&"ui_down") or Input.is_physical_key_pressed(KEY_S):
		kb.y += 1.0

	for joy_id in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(joy_id, JOY_BUTTON_DPAD_LEFT):
			kb.x -= 1.0
		if Input.is_joy_button_pressed(joy_id, JOY_BUTTON_DPAD_RIGHT):
			kb.x += 1.0
		if Input.is_joy_button_pressed(joy_id, JOY_BUTTON_DPAD_UP):
			kb.y -= 1.0
		if Input.is_joy_button_pressed(joy_id, JOY_BUTTON_DPAD_DOWN):
			kb.y += 1.0

	kb.x = clampf(kb.x, -1.0, 1.0)
	kb.y = clampf(kb.y, -1.0, 1.0)

	var best_stick := Vector2.ZERO
	for joy_id in Input.get_connected_joypads():
		var s := Vector2(
			Input.get_joy_axis(joy_id, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(joy_id, JOY_AXIS_LEFT_Y),
		)
		if s.length() > best_stick.length():
			best_stick = s

	if best_stick.length() >= STICK_DEADZONE:
		return best_stick.limit_length(1.0)
	if kb.length_squared() > 0.0001:
		return kb.normalized()
	return Vector2.ZERO


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
