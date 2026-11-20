extends Control
class_name LevelCompleteUI

signal next_level_pressed
signal replay_pressed
signal map_pressed

var _title_lbl: Label
var _stars_lbl: Label
var _card: PanelContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_ui()


func show_celebration(level_id: int, level_name: String, stars: int) -> void:
	_title_lbl.text = "BARAKALLA! %d-DARAJA O‘TILDI!" % level_id
	_stars_lbl.text = "★".repeat(clampi(stars, 1, 3)) + "
" + level_name
	visible = true
	_card.scale = Vector2(0.4, 0.4)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.4)


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.14, 0.28, 0.52)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(540, 340)
	_card.pivot_offset = Vector2(270, 170)
	_card.add_theme_stylebox_override("panel", _make_box(Color("FFFFFF"), Color("FFD23F"), 8, 36))
	center.add_child(_card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 32)
	m.add_theme_constant_override("margin_right", 32)
	m.add_theme_constant_override("margin_top", 28)
	m.add_theme_constant_override("margin_bottom", 28)
	_card.add_child(m)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	m.add_child(vbox)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 30)
	_title_lbl.add_theme_color_override("font_color", Color("FF7251"))
	vbox.add_child(_title_lbl)

	_stars_lbl = Label.new()
	_stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stars_lbl.add_theme_font_size_override("font_size", 42)
	_stars_lbl.add_theme_color_override("font_color", Color("FFB800"))
	vbox.add_child(_stars_lbl)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 18)
	vbox.add_child(hbox)

	var btn_map := _make_btn("🗺", 84, Color("00C4B4"))
	btn_map.pressed.connect(func() -> void:
		visible = false
		map_pressed.emit()
	)
	hbox.add_child(btn_map)

	var btn_replay := _make_btn("↻", 84, Color("FF7251"))
	btn_replay.pressed.connect(func() -> void:
		visible = false
		replay_pressed.emit()
	)
	hbox.add_child(btn_replay)

	var btn_next := _make_btn("KEYINGI ▶", 210, Color("38C938"))
	btn_next.pressed.connect(func() -> void:
		visible = false
		next_level_pressed.emit()
	)
	hbox.add_child(btn_next)


func _make_btn(txt: String, w: int, col: Color) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(w, 74)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _make_box(col, Color.WHITE, 5, 24))
	return b


func _make_box(bg_col: Color, border_col: Color, border_w: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.22)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	return sb
