extends Control
class_name MainMenuUI

signal play_pressed
signal levels_pressed

var _play_btn: Button
var _pulse_time: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _process(delta: float) -> void:
	if visible and _play_btn != null:
		_pulse_time += delta * 3.0
		var s := 1.0 + sin(_pulse_time) * 0.04
		_play_btn.scale = Vector2(s, s)


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)

	# Yorqin sarlavha kartochkasi
	var title_card := PanelContainer.new()
	title_card.add_theme_stylebox_override("panel", _make_box(Color("FFFFFFF0"), Color("FFD23F"), 7, 36))
	vbox.add_child(title_card)

	var tm := MarginContainer.new()
	tm.add_theme_constant_override("margin_left", 42)
	tm.add_theme_constant_override("margin_right", 42)
	tm.add_theme_constant_override("margin_top", 20)
	tm.add_theme_constant_override("margin_bottom", 20)
	title_card.add_child(tm)

	var title_lbl := Label.new()
	title_lbl.text = "★ MANTIQIY OROL 3D ★"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 46)
	title_lbl.add_theme_color_override("font_color", Color("FF7251"))
	tm.add_child(title_lbl)

	# Yirik yashil O'YNASH tugmasi
	var play_wrap := CenterContainer.new()
	vbox.add_child(play_wrap)

	_play_btn = Button.new()
	_play_btn.text = "▶  O‘YNASH"
	_play_btn.custom_minimum_size = Vector2(310, 96)
	_play_btn.pivot_offset = Vector2(155, 48)
	_play_btn.focus_mode = Control.FOCUS_NONE
	_play_btn.add_theme_font_size_override("font_size", 36)
	_play_btn.add_theme_color_override("font_color", Color.WHITE)
	_play_btn.add_theme_stylebox_override("normal", _make_box(Color("38C938"), Color.WHITE, 6, 48))
	_play_btn.add_theme_stylebox_override("hover", _make_box(Color("4AD94A"), Color.WHITE, 6, 48))
	_play_btn.add_theme_stylebox_override("pressed", _make_box(Color("2AA82A"), Color.WHITE, 6, 48))
	_play_btn.pressed.connect(func() -> void: play_pressed.emit())
	play_wrap.add_child(_play_btn)

	# 100 ta daraja xaritasi tugmasi
	var lvl_wrap := CenterContainer.new()
	vbox.add_child(lvl_wrap)

	var lvl_btn := Button.new()
	lvl_btn.text = "🗺  100 TA DARAJA"
	lvl_btn.custom_minimum_size = Vector2(270, 74)
	lvl_btn.focus_mode = Control.FOCUS_NONE
	lvl_btn.add_theme_font_size_override("font_size", 26)
	lvl_btn.add_theme_color_override("font_color", Color.WHITE)
	lvl_btn.add_theme_stylebox_override("normal", _make_box(Color("00C4B4"), Color.WHITE, 5, 36))
	lvl_btn.add_theme_stylebox_override("hover", _make_box(Color("16D6C6"), Color.WHITE, 5, 36))
	lvl_btn.pressed.connect(func() -> void: levels_pressed.emit())
	lvl_wrap.add_child(lvl_btn)


func _make_box(bg_col: Color, border_col: Color, border_w: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 5)
	return sb
