extends Control
class_name LevelSelectUI

## 5 ta orol dunyosi va 100 ta darajani yulduzchalari hamda qulflangan/ochiq holati bilan
## ko'rsatuvchi bolalar uchun qulay Godot 4 UI skripti.
## Control tuguniga ulang (Full Rect): barcha tugmalar va 5x4 daraja panjarasi avtomatik chiziladi.

signal level_selected(level_id: int)
signal back_pressed

@export var levels_json_path: String = "res://levels_data.json"
@export var level_loader_path: NodePath

const SAVE_PATH := "user://save_progress.json"

const WORLD_COLORS := [
	Color("6AC42E"), # 1. Yashil Orol
	Color("FF8C42"), # 2. Mevali Bog'
	Color("2BC0E4"), # 3. Sharshara Vodiysi
	Color("6FA8FF"), # 4. Bulutli Tepalik
	Color("9B72F2"), # 5. Sehrli Qal'a Oroli
]

var _worlds: Array = []
var _unlocked_level: int = 1
var _stars_by_level: Dictionary = {}
var _active_world_idx: int = 0

var _world_buttons: Array[Button] = []
var _grid: GridContainer
var _world_title_label: Label
var _total_stars_label: Label
var _level_loader: Node


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if level_loader_path != NodePath():
		_level_loader = get_node_or_null(level_loader_path)
	_load_data()
	_active_world_idx = clampi((_unlocked_level - 1) / 20, 0, 4)
	_build_ui()
	_show_world(_active_world_idx)


func refresh() -> void:
	_load_data()
	_update_total_stars()
	_show_world(_active_world_idx)


func _load_data() -> void:
	if FileAccess.file_exists(levels_json_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(levels_json_path))
		if parsed is Dictionary and parsed.has("worlds"):
			_worlds = parsed["worlds"]

	if _worlds.is_empty():
		_worlds = [
			{"world_id": 1, "name": "Yashil Orol", "level_range": [1, 20]},
			{"world_id": 2, "name": "Mevali Bog‘", "level_range": [21, 40]},
			{"world_id": 3, "name": "Sharshara Vodiysi", "level_range": [41, 60]},
			{"world_id": 4, "name": "Bulutli Tepalik", "level_range": [61, 80]},
			{"world_id": 5, "name": "Sehrli Qal’a Oroli", "level_range": [81, 100]},
		]

	_unlocked_level = 1
	_stars_by_level = {}
	if FileAccess.file_exists(SAVE_PATH):
		var save_parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if save_parsed is Dictionary:
			_unlocked_level = int(save_parsed.get("unlocked_level", 1))
			_stars_by_level = save_parsed.get("stars_by_level", {})


func _build_ui() -> void:
	# Yorqin osmon rangli fon
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("4EC3FF")
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 16)
	margin.add_child(root_vbox)

	# --- Yuqori panel: Orqaga tugmasi, dunyo nomi va umumiy yulduzchalar ---
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root_vbox.add_child(header)

	var btn_back := Button.new()
	btn_back.text = "◀"
	btn_back.custom_minimum_size = Vector2(68, 64)
	btn_back.focus_mode = Control.FOCUS_NONE
	btn_back.add_theme_font_size_override("font_size", 28)
	btn_back.add_theme_color_override("font_color", Color.WHITE)
	btn_back.add_theme_stylebox_override("normal", _make_box(Color("FF7251"), Color.WHITE, 4, 20))
	btn_back.pressed.connect(func() -> void: back_pressed.emit())
	header.add_child(btn_back)

	_world_title_label = Label.new()
	_world_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_world_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_world_title_label.add_theme_font_size_override("font_size", 36)
	_world_title_label.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(_world_title_label)

	var star_pill := PanelContainer.new()
	star_pill.add_theme_stylebox_override("panel", _make_box(Color.WHITE, Color("FFD23F"), 4, 24))
	header.add_child(star_pill)

	var sp_margin := MarginContainer.new()
	sp_margin.add_theme_constant_override("margin_left", 18)
	sp_margin.add_theme_constant_override("margin_right", 18)
	sp_margin.add_theme_constant_override("margin_top", 8)
	sp_margin.add_theme_constant_override("margin_bottom", 8)
	star_pill.add_child(sp_margin)

	_total_stars_label = Label.new()
	_total_stars_label.add_theme_font_size_override("font_size", 26)
	_total_stars_label.add_theme_color_override("font_color", Color("D98200"))
	sp_margin.add_child(_total_stars_label)
	_update_total_stars()

	# --- 5 ta Orol tanlash tugmalari ---
	var world_tabs := HBoxContainer.new()
	world_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	world_tabs.add_theme_constant_override("separation", 12)
	root_vbox.add_child(world_tabs)

	_world_buttons.clear()
	for i in range(_worlds.size()):
		var w: Dictionary = _worlds[i]
		var w_btn := Button.new()
		w_btn.text = "%d. %s" % [i + 1, w["name"]]
		w_btn.custom_minimum_size = Vector2(0, 56)
		w_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		w_btn.focus_mode = Control.FOCUS_NONE
		w_btn.add_theme_font_size_override("font_size", 20)
		w_btn.add_theme_color_override("font_color", Color.WHITE)
		var col: Color = WORLD_COLORS[i % WORLD_COLORS.size()]
		w_btn.add_theme_stylebox_override("normal", _make_box(col, Color.WHITE, 4, 18))
		var idx := i
		w_btn.pressed.connect(func() -> void: _show_world(idx))
		world_tabs.add_child(w_btn)
		_world_buttons.append(w_btn)

	# --- 20 ta daraja uchun 5x4 panjara ---
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 18)
	center.add_child(_grid)


func _show_world(world_idx: int) -> void:
	_active_world_idx = clampi(world_idx, 0, _worlds.size() - 1)
	var w: Dictionary = _worlds[_active_world_idx]
	var w_col: Color = WORLD_COLORS[_active_world_idx % WORLD_COLORS.size()]
	_world_title_label.text = "%d-OROL: %s" % [_active_world_idx + 1, str(w["name"]).to_upper()]

	# Tanlangan dunyo tugmasini ajratib ko'rsatish
	for i in range(_world_buttons.size()):
		var c: Color = WORLD_COLORS[i % WORLD_COLORS.size()]
		var border_col := Color("FFD23F") if i == _active_world_idx else Color.WHITE
		var border_w := 6 if i == _active_world_idx else 3
		_world_buttons[i].add_theme_stylebox_override("normal", _make_box(c, border_col, border_w, 18))

	for child in _grid.get_children():
		child.queue_free()

	var start_lvl: int = int(w["level_range"][0])
	var end_lvl: int = int(w["level_range"][1])

	for lvl_id in range(start_lvl, end_lvl + 1):
		_grid.add_child(_create_level_card(lvl_id, w_col))


func _create_level_card(lvl_id: int, world_color: Color) -> Button:
	var is_unlocked: bool = lvl_id <= _unlocked_level
	var is_current: bool = lvl_id == _unlocked_level
	var earned: int = int(_stars_by_level.get(str(lvl_id), 0))

	var card := Button.new()
	card.custom_minimum_size = Vector2(138, 118)
	card.focus_mode = Control.FOCUS_NONE
	card.disabled = not is_unlocked
	card.pivot_offset = Vector2(69, 59)

	if is_unlocked:
		var border_col := Color("FFD23F") if is_current else Color.WHITE
		var border_w := 6 if is_current else 4
		card.add_theme_stylebox_override("normal", _make_box(world_color, border_col, border_w, 24))
		card.add_theme_stylebox_override("hover", _make_box(world_color.lightened(0.08), border_col, border_w, 24))
		card.add_theme_stylebox_override("pressed", _make_box(world_color.darkened(0.12), border_col, border_w, 24))
	else:
		card.add_theme_stylebox_override("disabled", _make_box(Color("9AA7B8"), Color("D8E2EC"), 4, 24))

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	var num_lbl := Label.new()
	num_lbl.text = str(lvl_id)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_size_override("font_size", 36)
	num_lbl.add_theme_color_override("font_color", Color.WHITE if is_unlocked else Color("E5ECF4"))
	vbox.add_child(num_lbl)

	var sub_lbl := Label.new()
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 22)
	if is_unlocked:
		sub_lbl.text = "★".repeat(earned) + "☆".repeat(3 - earned)
		sub_lbl.add_theme_color_override("font_color", Color("FFE24A"))
	else:
		sub_lbl.text = "🔒"
	vbox.add_child(sub_lbl)

	if is_unlocked:
		card.pressed.connect(func() -> void:
			_pop_card(card)
			level_selected.emit(lvl_id)
			if _level_loader != null and _level_loader.has_method("load_level"):
				_level_loader.call("load_level", lvl_id)
				visible = false
		)

	return card


func _update_total_stars() -> void:
	var total := 0
	for k in _stars_by_level.keys():
		total += int(_stars_by_level[k])
	if _total_stars_label != null:
		_total_stars_label.text = "★ %d / 300" % total


func _make_box(bg_col: Color, border_col: Color, border_w: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.2)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	return sb


func _pop_card(card: Control) -> void:
	var tween := create_tween()
	tween.tween_property(card, "scale", Vector2(0.90, 0.90), 0.06)
	tween.tween_property(card, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
