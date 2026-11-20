extends CanvasLayer
class_name MobileHUD

## Bolalar uchun yirik tugmali mobil UI/HUD va multi-touch virtual joystik skripti (Godot 4).
## CanvasLayer tuguniga ulang: barcha tugmalar va joystik avtomatik chiziladi va
## PlayerController / FoxCompanion skriptlariga o'zi ulanadi.

@export var player_path: NodePath
@export var fox_path: NodePath
@export var total_stars: int = 3
@export var joystick_radius: float = 82.0
@export var knob_radius: float = 38.0

var _player: PlayerController
var _fox: FoxCompanion

var _joystick_touch_idx: int = -1
var _joystick_center: Vector2 = Vector2.ZERO
var _joystick_base: Control
var _joystick_knob: Control
var _star_label: Label
var _is_muted: bool = false


func _ready() -> void:
	layer = 10
	_resolve_targets()
	_build_hud()


func _resolve_targets() -> void:
	if player_path != NodePath():
		_player = get_node_or_null(player_path) as PlayerController
	if _player == null:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0 and players[0] is PlayerController:
			_player = players[0] as PlayerController

	if fox_path != NodePath():
		_fox = get_node_or_null(fox_path) as FoxCompanion
	if _fox == null:
		var root := get_tree().current_scene
		if root != null:
			for child in root.find_children("*", "FoxCompanion", true, false):
				_fox = child as FoxCompanion
				break

	if _player != null and not _player.star_count_changed.is_connected(_on_star_count_changed):
		_player.star_count_changed.connect(_on_star_count_changed)


func _build_hud() -> void:
	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_ctrl)

	# --- Yuqori chap: Yulduzchalar hisoblagichi ---
	var star_panel := PanelContainer.new()
	star_panel.position = Vector2(28, 24)
	star_panel.add_theme_stylebox_override("panel", _make_pill_style(Color("FFFFFFEE"), Color("FFD23F"), 5, 28))
	root_ctrl.add_child(star_panel)

	var star_margin := MarginContainer.new()
	star_margin.add_theme_constant_override("margin_left", 20)
	star_margin.add_theme_constant_override("margin_right", 20)
	star_margin.add_theme_constant_override("margin_top", 10)
	star_margin.add_theme_constant_override("margin_bottom", 10)
	star_panel.add_child(star_margin)

	_star_label = Label.new()
	_star_label.text = "★ 0 / %d" % total_stars
	_star_label.add_theme_font_size_override("font_size", 32)
	_star_label.add_theme_color_override("font_color", Color("D98200"))
	star_margin.add_child(_star_label)

	# --- Yuqori o'ng: Ovoz va Pauza tugmalari ---
	var top_right := HBoxContainer.new()
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.offset_left = -196
	top_right.offset_top = 24
	top_right.offset_right = -24
	top_right.offset_bottom = 104
	top_right.add_theme_constant_override("separation", 16)
	root_ctrl.add_child(top_right)

	var btn_sound := _make_round_button("🔊", 76, Color("FFD23F"), Color("FFFFFF"), 24)
	btn_sound.pressed.connect(func() -> void:
		_pop_button(btn_sound)
		_is_muted = not _is_muted
		AudioServer.set_bus_mute(0, _is_muted)
		btn_sound.text = "🔇" if _is_muted else "🔊"
	)
	top_right.add_child(btn_sound)

	var btn_pause := _make_round_button("❚❚", 76, Color("00C4B4"), Color("FFFFFF"), 24)
	btn_pause.process_mode = Node.PROCESS_MODE_ALWAYS
	btn_pause.pressed.connect(func() -> void:
		_pop_button(btn_pause)
		get_tree().paused = not get_tree().paused
		btn_pause.text = "▶" if get_tree().paused else "❚❚"
	)
	top_right.add_child(btn_pause)

	# --- Pastki chap: Sensorli virtual joystik ---
	var base_size := joystick_radius * 2.0
	_joystick_base = Panel.new()
	_joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_joystick_base.offset_left = 44
	_joystick_base.offset_top = -(44 + base_size)
	_joystick_base.offset_right = 44 + base_size
	_joystick_base.offset_bottom = -44
	_joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joystick_base.add_theme_stylebox_override("panel", _make_pill_style(Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.75), 4, int(joystick_radius)))
	root_ctrl.add_child(_joystick_base)

	var knob_size := knob_radius * 2.0
	_joystick_knob = Panel.new()
	_joystick_knob.custom_minimum_size = Vector2(knob_size, knob_size)
	_joystick_knob.size = Vector2(knob_size, knob_size)
	_joystick_knob.position = Vector2(joystick_radius - knob_radius, joystick_radius - knob_radius)
	_joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joystick_knob.add_theme_stylebox_override("panel", _make_pill_style(Color("FF7251"), Color("FFFFFF"), 4, int(knob_radius)))
	_joystick_base.add_child(_joystick_knob)

	# --- Pastki o'ng: Sakrash, Kub surish va Tulkichani chaqirish tugmalari ---
	var btn_jump := _make_round_button("▲", 118, Color("38C938"), Color("FFFFFF"), 59)
	btn_jump.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_jump.offset_left = -154
	btn_jump.offset_top = -154
	btn_jump.offset_right = -36
	btn_jump.offset_bottom = -36
	btn_jump.button_down.connect(func() -> void:
		_pop_button(btn_jump)
		if _player != null:
			_player.trigger_jump()
	)
	root_ctrl.add_child(btn_jump)

	var btn_push := _make_round_button("✋", 96, Color("FF7251"), Color("FFFFFF"), 48)
	btn_push.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_push.offset_left = -268
	btn_push.offset_top = -132
	btn_push.offset_right = -172
	btn_push.offset_bottom = -36
	btn_push.button_down.connect(func() -> void:
		_pop_button(btn_push)
		if _player != null:
			_player.trigger_push()
	)
	root_ctrl.add_child(btn_push)

	var btn_fox := _make_round_button("🐾", 88, Color("FFD23F"), Color("FFFFFF"), 44)
	btn_fox.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_fox.offset_left = -139
	btn_fox.offset_top = -264
	btn_fox.offset_right = -51
	btn_fox.offset_bottom = -176
	btn_fox.button_down.connect(func() -> void:
		_pop_button(btn_fox)
		if _fox != null:
			_fox.call_to_player()
	)
	root_ctrl.add_child(btn_fox)


func _input(event: InputEvent) -> void:
	if _joystick_base == null:
		return

	# Multi-touch sensorli boshqaruv (Android / iOS)
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var center := _joystick_base.global_position + _joystick_base.size * 0.5
		if touch.pressed:
			if _joystick_touch_idx == -1 and touch.position.distance_to(center) <= joystick_radius * 1.45:
				_joystick_touch_idx = touch.index
				_joystick_center = center
				_update_joystick(touch.position)
		elif touch.index == _joystick_touch_idx:
			_reset_joystick()

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _joystick_touch_idx:
			_update_joystick(drag.position)

	# Kompyuterda sichqoncha bilan sinab ko'rish uchun zaxira
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var center := _joystick_base.global_position + _joystick_base.size * 0.5
			if mb.pressed and mb.position.distance_to(center) <= joystick_radius * 1.45:
				_joystick_touch_idx = 999
				_joystick_center = center
				_update_joystick(mb.position)
			elif not mb.pressed and _joystick_touch_idx == 999:
				_reset_joystick()

	elif event is InputEventMouseMotion and _joystick_touch_idx == 999:
		_update_joystick((event as InputEventMouseMotion).position)


func _update_joystick(touch_pos: Vector2) -> void:
	var offset := touch_pos - _joystick_center
	var max_dist := joystick_radius - knob_radius * 0.45
	if offset.length() > max_dist:
		offset = offset.normalized() * max_dist

	_joystick_knob.position = Vector2(joystick_radius - knob_radius, joystick_radius - knob_radius) + offset
	if _player != null:
		_player.set_joystick_vector(offset / max_dist)


func _reset_joystick() -> void:
	_joystick_touch_idx = -1
	_joystick_knob.position = Vector2(joystick_radius - knob_radius, joystick_radius - knob_radius)
	if _player != null:
		_player.set_joystick_vector(Vector2.ZERO)


func _on_star_count_changed(new_count: int) -> void:
	if _star_label != null:
		_star_label.text = "★ %d / %d" % [new_count, total_stars]


func _make_round_button(icon_text: String, diameter: int, bg_col: Color, border_col: Color, radius: int) -> Button:
	var btn := Button.new()
	btn.text = icon_text
	btn.custom_minimum_size = Vector2(diameter, diameter)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", int(diameter * 0.42))
	btn.add_theme_color_override("font_color", Color("FFFFFF"))
	btn.add_theme_stylebox_override("normal", _make_pill_style(bg_col, border_col, 6, radius))
	btn.add_theme_stylebox_override("hover", _make_pill_style(bg_col.lightened(0.08), border_col, 6, radius))
	btn.add_theme_stylebox_override("pressed", _make_pill_style(bg_col.darkened(0.12), border_col, 6, radius))
	btn.pivot_offset = Vector2(diameter * 0.5, diameter * 0.5)
	return btn


func _make_pill_style(bg_col: Color, border_col: Color, border_w: int, corner_r: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(corner_r)
	sb.shadow_color = Color(0, 0, 0, 0.22)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	return sb


func _pop_button(btn: Control) -> void:
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(0.88, 0.88), 0.06)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func bind_actors(player: PlayerController, fox: FoxCompanion, level_title: String = "") -> void:
	_player = player
	_fox = fox
	if _player != null and not _player.star_count_changed.is_connected(_on_star_count_changed):
		_player.star_count_changed.connect(_on_star_count_changed)
	_on_star_count_changed(0)
	if _star_label != null and level_title != "":
		_star_label.text = "★ 0 / %d  •  %s" % [total_stars, level_title]
