extends CanvasLayer
## 背包 UI：网格槽位、打开/关闭、与 InventoryManager 同步

const COLS := 6

@onready var _dim: ColorRect = $Root/Dim
@onready var _panel: PanelContainer = $Root/Panel
@onready var _grid: GridContainer = $Root/Panel/Margin/VBox/Grid


func _ready() -> void:
	layer = 20
	visible = false
	_build_grid()
	InventoryManager.inventory_changed.connect(_refresh_slots)
	_refresh_slots()
	_dim.gui_input.connect(_on_dim_gui_input)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_inventory"):
		_set_open(not visible)
		get_viewport().set_input_as_handled()


func _on_dim_gui_input(event: InputEvent) -> void:
	if visible and event is InputEventMouseButton and event.pressed:
		_set_open(false)


func _set_open(open: bool) -> void:
	visible = open
	InventoryManager.set_backpack_open(open)
	if open:
		_refresh_slots()


func _build_grid() -> void:
	for i in InventoryManager.SLOT_COUNT:
		var b := Button.new()
		b.custom_minimum_size = Vector2(72, 56)
		b.name = "Slot_%d" % i
		b.pressed.connect(_on_slot_pressed.bind(i))
		_grid.add_child(b)
	_refresh_slots()


func _refresh_slots() -> void:
	for i in InventoryManager.SLOT_COUNT:
		var b: Button = _grid.get_node_or_null("Slot_%d" % i) as Button
		if b == null:
			continue
		var s: Variant = InventoryManager.get_slot(i)
		if s == null:
			b.text = "—"
			b.tooltip_text = "空"
		else:
			var nm: String = str(s.get("name", s["id"]))
			var q: int = int(s["qty"])
			var id: String = str(s["id"])
			if id == "hoe" or id == "watering_can" or id == "axe":
				var max_d := InventoryManager.get_default_tool_durability()
				var dur: int = int(s.get("durability", max_d))
				b.text = "%s %d/%d" % [nm, dur, max_d]
				b.tooltip_text = "%s\n叠放: %d\n耐久: %d" % [id, q, dur]
			else:
				b.text = nm if q <= 1 else "%s x%d" % [nm, q]
				b.tooltip_text = "%s\n数量: %d" % [id, q]


func _on_slot_pressed(slot_index: int) -> void:
	var s: Variant = InventoryManager.get_slot(slot_index)
	if s == null:
		return
	print("[背包] 槽 %d: %s x%d（演示：未消耗）" % [slot_index, s["name"], int(s["qty"])])
