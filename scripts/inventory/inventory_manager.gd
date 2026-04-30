extends Node
## 全局背包：固定槽位数，同 id 自动堆叠；供 UI 与游戏逻辑读写。

signal inventory_changed

const SLOT_COUNT := 24
const MAX_STACK := 99

## 每槽为 null 或 Dictionary: { "id": String, "name": String, "qty": int }
var _slots: Array = []

## 打开背包时由 UI 设置，供 PlayerWalk 等暂停移动输入
var player_input_blocked: bool = false


func _ready() -> void:
	_slots.resize(SLOT_COUNT)
	for i in SLOT_COUNT:
		_slots[i] = null
	_register_toggle_inventory_action()
	register_interact_action()


func _register_toggle_inventory_action() -> void:
	if InputMap.has_action(&"toggle_inventory"):
		return
	InputMap.add_action(&"toggle_inventory", 0.2)
	var ik := InputEventKey.new()
	ik.physical_keycode = KEY_I
	InputMap.action_add_event(&"toggle_inventory", ik)
	var itab := InputEventKey.new()
	itab.physical_keycode = KEY_TAB
	InputMap.action_add_event(&"toggle_inventory", itab)
	for joy in range(8):
		var b := InputEventJoypadButton.new()
		b.device = joy
		b.button_index = JOY_BUTTON_Y
		InputMap.action_add_event(&"toggle_inventory", b)


func get_slot_count() -> int:
	return SLOT_COUNT


func get_slot(index: int) -> Variant:
	if index < 0 or index >= SLOT_COUNT:
		return null
	return _slots[index]


## 添加物品；尽量合并已有同 id 槽，否则找空槽。返回未能入包的数量。
func add_item(item_id: String, display_name: String, quantity: int = 1) -> int:
	var left := quantity
	left = _merge_into_existing(item_id, left)
	while left > 0:
		var empty_i := _first_empty_slot()
		if empty_i < 0:
			break
		var take: int = mini(left, MAX_STACK)
		_slots[empty_i] = { "id": item_id, "name": display_name, "qty": take }
		left -= take
	_emit_changed()
	return left


func _merge_into_existing(item_id: String, quantity: int) -> int:
	var left := quantity
	for i in SLOT_COUNT:
		var s: Variant = _slots[i]
		if s == null:
			continue
		if s["id"] != item_id:
			continue
		var room: int = MAX_STACK - int(s["qty"])
		if room <= 0:
			continue
		var add: int = mini(left, room)
		s["qty"] = int(s["qty"]) + add
		left -= add
		if left <= 0:
			break
	return left


func _first_empty_slot() -> int:
	for i in SLOT_COUNT:
		if _slots[i] == null:
			return i
	return -1


func remove_from_slot(slot_index: int, amount: int = 1) -> int:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return 0
	var s: Variant = _slots[slot_index]
	if s == null:
		return 0
	var q: int = int(s["qty"])
	var take: int = mini(amount, q)
	s["qty"] = q - take
	if int(s["qty"]) <= 0:
		_slots[slot_index] = null
	_emit_changed()
	return take


func clear_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return
	_slots[slot_index] = null
	_emit_changed()


func _emit_changed() -> void:
	inventory_changed.emit()


func set_backpack_open(open: bool) -> void:
	player_input_blocked = open


func register_interact_action() -> void:
	if InputMap.has_action(&"interact"):
		return
	InputMap.add_action(&"interact", 0.2)
	var ek := InputEventKey.new()
	ek.physical_keycode = KEY_E
	InputMap.action_add_event(&"interact", ek)
	for joy in range(8):
		var b := InputEventJoypadButton.new()
		b.device = joy
		b.button_index = JOY_BUTTON_A
		InputMap.action_add_event(&"interact", b)


func count_item(item_id: String) -> int:
	var n := 0
	for i in SLOT_COUNT:
		var s: Variant = _slots[i]
		if s != null and s["id"] == item_id:
			n += int(s["qty"])
	return n


## 从背包扣除指定数量（跨槽合并扣）。成功返回 true
func consume_item(item_id: String, amount: int) -> bool:
	if count_item(item_id) < amount:
		return false
	var left := amount
	for i in SLOT_COUNT:
		if left <= 0:
			break
		var s: Variant = _slots[i]
		if s == null or s["id"] != item_id:
			continue
		var q: int = int(s["qty"])
		var take: int = mini(left, q)
		s["qty"] = q - take
		left -= take
		if int(s["qty"]) <= 0:
			_slots[i] = null
	_emit_changed()
	return true
