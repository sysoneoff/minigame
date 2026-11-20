extends Node3D
class_name GameManager

## Mantiqiy Orol 3D - Asosiy o'yin menejeri.
## Barcha .glb 3D modellarni, 100 ta darajani, fizika kollayderlarini,
## bezaklarni, ovozlarni, mobil HUD va menyularni yagona tizimda boshqaradi.

const LEVELS_JSON_PATH := "res://levels_data.json"
const SAVE_PATH := "user://save_progress.json"

const COLOR_MAP := {
	"pink": Color("F49AC2"),
	"blue": Color("89CFF0"),
	"lavender": Color("C3A6E8"),
	"mint": Color("96E0C2"),
}

var _res_island: PackedScene
var _res_kid: PackedScene
var _res_fox: PackedScene
var _res_bridge: PackedScene
var _res_tree: PackedScene
var _res_star: PackedScene

var _all_levels: Array = []
var _progress: Dictionary = {"unlocked_level": 1, "stars_by_level": {}}
var _current_level_info: Dictionary = {}
var _current_level_id: int = 1
var _plates_total: int = 0
var _plates_solved: int = 0
var _stars_collected: int = 0

var _env_polish: EnvironmentPolish
var _sfx: SoundFX
var _camera: FollowCamera
var _level_root: Node3D
var _bridge_node: Node3D
var _ui_layer: CanvasLayer
var _main_menu: MainMenuUI
var _level_select: LevelSelectUI
var _level_complete: LevelCompleteUI
var _hud: MobileHUD


func _ready() -> void:
	_load_models()
	_load_levels_json()
	_load_progress()

	_sfx = SoundFX.new()
	add_child(_sfx)

	_env_polish = EnvironmentPolish.new()
	add_child(_env_polish)

	_camera = FollowCamera.new()
	add_child(_camera)
	_camera.current = true

	_hud = MobileHUD.new()
	_hud.visible = false
	add_child(_hud)

	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 20
	add_child(_ui_layer)

	_main_menu = MainMenuUI.new()
	_main_menu.play_pressed.connect(_on_menu_play)
	_main_menu.levels_pressed.connect(_on_menu_levels)
	_ui_layer.add_child(_main_menu)

	_level_select = LevelSelectUI.new()
	_level_select.visible = false
	_level_select.level_selected.connect(_on_level_selected)
	_level_select.back_pressed.connect(func() -> void:
		_sfx.play_tap()
		_level_select.visible = false
		_main_menu.visible = true
	)
	_ui_layer.add_child(_level_select)

	_level_complete = LevelCompleteUI.new()
	_level_complete.next_level_pressed.connect(func() -> void:
		_sfx.play_tap()
		start_level(mini(_current_level_id + 1, 100))
	)
	_level_complete.replay_pressed.connect(func() -> void:
		_sfx.play_tap()
		start_level(_current_level_id)
	)
	_level_complete.map_pressed.connect(func() -> void:
		_sfx.play_tap()
		_hud.visible = false
		_camera.menu_orbit_mode = true
		_level_select.refresh()
		_level_select.visible = true
	)
	_ui_layer.add_child(_level_complete)

	# Bosh menyu fonida 1-daraja oroli jonli aylanib turadi
	_spawn_level_geometry(int(_progress.get("unlocked_level", 1)), true)


func _load_models() -> void:
	_res_island = load("res://assets/models/floating_island.glb") as PackedScene
	_res_kid = load("res://assets/models/explorer_kid.glb") as PackedScene
	_res_fox = load("res://assets/models/fox_companion.glb") as PackedScene
	_res_bridge = load("res://assets/models/wooden_bridge.glb") as PackedScene
	_res_tree = load("res://assets/models/fruit_tree.glb") as PackedScene
	_res_star = load("res://assets/models/golden_star.glb") as PackedScene


func _load_levels_json() -> void:
	if not FileAccess.file_exists(LEVELS_JSON_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(LEVELS_JSON_PATH))
	if parsed is Dictionary and parsed.has("levels"):
		_all_levels = parsed["levels"]


func _on_menu_play() -> void:
	_sfx.play_tap()
	_main_menu.visible = false
	start_level(int(_progress.get("unlocked_level", 1)))


func _on_menu_levels() -> void:
	_sfx.play_tap()
	_main_menu.visible = false
	_level_select.refresh()
	_level_select.visible = true


func _on_level_selected(lvl_id: int) -> void:
	_sfx.play_tap()
	_level_select.visible = false
	start_level(lvl_id)


func start_level(level_id: int) -> void:
	_main_menu.visible = false
	_level_select.visible = false
	_level_complete.visible = false
	_hud.visible = true
	_spawn_level_geometry(level_id, false)


func _spawn_level_geometry(level_id: int, preview_only: bool) -> void:
	if _all_levels.is_empty():
		return
	var idx := clampi(level_id - 1, 0, _all_levels.size() - 1)
	_current_level_info = _all_levels[idx]
	_current_level_id = int(_current_level_info["id"])
	_stars_collected = 0
	_plates_solved = 0
	_plates_total = _current_level_info["plates"].size()

	_env_polish.set_sky_theme(str(_current_level_info.get("sky_color", "#5CC8FF")))

	if _level_root != null:
		_level_root.queue_free()
	_level_root = Node3D.new()
	_level_root.name = "Level_%d" % _current_level_id
	add_child(_level_root)

	# 1. Suzuvchi orol va uning aniq fizika kollayderlari
	if _res_island != null:
		_level_root.add_child(_res_island.instantiate())
	_build_island_colliders(_level_root)

	# 2. Yog'och ko'prik + kollayder
	var bridge_pos := _v3(_current_level_info["bridge"]["pos"])
	var starts_open: bool = _current_level_info["bridge"]["starts_open"]
	_bridge_node = _create_bridge(bridge_pos, starts_open)
	_level_root.add_child(_bridge_node)

	# 3. Mevali daraxtlar
	if _res_tree != null:
		for t in _current_level_info["trees"]:
			var tree := _res_tree.instantiate() as Node3D
			tree.position = _v3(t["pos"])
			tree.scale = Vector3.ONE * float(t["scale"])
			tree.rotation_degrees.y = float(t["rot_y"])
			_level_root.add_child(tree)

	# 4. Rangli kublar
	for c in _current_level_info["cubes"]:
		_level_root.add_child(_create_cube(_v3(c["pos"]), str(c["color"])))

	# 5. Rangli tugmalar (pressure plates)
	for p in _current_level_info["plates"]:
		_level_root.add_child(_create_plate(_v3(p["pos"]), str(p["color"])))

	# 6. 3 ta oltin yulduzcha
	for s_pos in _current_level_info["stars"]:
		_level_root.add_child(_create_star(_v3(s_pos)))

	# 7. Qahramon va tulkicha
	var player := _create_player(_v3(_current_level_info["player_spawn"]))
	_level_root.add_child(player)

	var fox := _create_fox(_v3(_current_level_info["fox_spawn"]), player)
	_level_root.add_child(fox)

	if not preview_only:
		_camera.snap_to_target(player)
		_hud.bind_actors(player, fox, "%d-daraja" % _current_level_id)


func _build_island_colliders(parent: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "IslandColliders"
	# Chap yashil maydon (Y = 0), O'ng yashil maydon (Y = 0), 1-pog'ona (+0.42), 2-pog'ona (+0.84)
	var boxes := [
		[Vector3(-2.35, -0.21, 0.0), Vector3(5.85, 0.42, 7.60)],
		[Vector3(3.55, -0.21, 0.0), Vector3(3.45, 0.42, 7.20)],
		[Vector3(-2.45, 0.21, -1.75), Vector3(4.00, 0.42, 3.35)],
		[Vector3(-2.95, 0.63, -2.25), Vector3(2.40, 0.42, 2.20)],
	]
	for b in boxes:
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = b[1]
		col.shape = shape
		col.position = b[0]
		body.add_child(col)
	parent.add_child(body)


func _create_bridge(pos: Vector3, starts_open: bool) -> Node3D:
	var bridge := StaticBody3D.new()
	bridge.position = pos
	if _res_bridge != null:
		bridge.add_child(_res_bridge.instantiate())
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.25, 0.20, 1.10)
	col.shape = shape
	col.position = Vector3(0.0, 0.06, 0.0)
	bridge.add_child(col)
	bridge.visible = starts_open
	bridge.process_mode = Node.PROCESS_MODE_INHERIT if starts_open else Node.PROCESS_MODE_DISABLED
	return bridge


func _create_player(pos: Vector3) -> PlayerController:
	var player := PlayerController.new()
	player.position = pos + Vector3(0.0, 0.05, 0.0)
	player.sfx = _sfx
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.26
	cap.height = 1.15
	col.shape = cap
	col.position = Vector3(0.0, 0.58, 0.0)
	player.add_child(col)

	var visual := Node3D.new()
	visual.name = "Visual"
	if _res_kid != null:
		visual.add_child(_res_kid.instantiate())
	player.add_child(visual)
	return player


func _create_fox(pos: Vector3, target_player: Node3D) -> FoxCompanion:
	var fox := FoxCompanion.new()
	fox.position = pos + Vector3(0.0, 0.05, 0.0)
	fox.target = target_player
	fox.sfx = _sfx
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.22
	cap.height = 0.58
	col.shape = cap
	col.position = Vector3(0.0, 0.29, 0.0)
	fox.add_child(col)

	var visual := Node3D.new()
	visual.name = "Visual"
	if _res_fox != null:
		visual.add_child(_res_fox.instantiate())
	fox.add_child(visual)
	return fox


func _create_cube(pos: Vector3, color_key: String) -> PushableCube:
	var cube := PushableCube.new()
	cube.position = pos + Vector3(0.0, 0.36, 0.0)
	cube.set_meta("cube_color", color_key)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.68, 0.68, 0.68)
	col.shape = shape
	cube.add_child(col)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.68, 0.68, 0.68)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR_MAP.get(color_key, Color.WHITE)
	mat.roughness = 0.48
	bm.material = mat
	mi.mesh = bm
	cube.add_child(mi)
	return cube


func _create_plate(pos: Vector3, color_key: String) -> Area3D:
	var area := Area3D.new()
	area.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.76, 0.25, 0.76)
	col.shape = shape
	area.add_child(col)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.74, 0.07, 0.74)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR_MAP.get(color_key, Color.WHITE).darkened(0.12)
	mat.emission_enabled = true
	mat.emission = COLOR_MAP.get(color_key, Color.WHITE)
	mat.emission_energy_multiplier = 0.25
	bm.material = mat
	mi.mesh = bm
	area.add_child(mi)

	area.body_entered.connect(func(body: Node3D) -> void:
		if body is PushableCube and not body.is_locked:
			if body.get_meta("cube_color", "") == color_key:
				body.snap_to_position(pos + Vector3(0.0, 0.35, 0.0))
				_sfx.play_plate()
				_env_polish.spawn_celebration_burst(pos + Vector3(0.0, 0.6, 0.0), COLOR_MAP.get(color_key, Color.WHITE))
				_plates_solved += 1
				if _plates_solved >= _plates_total:
					_unlock_bridge()
	)
	return area


func _create_star(pos: Vector3) -> GoldenStar:
	var star := GoldenStar.new()
	star.position = pos
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.55
	col.shape = sph
	col.position = Vector3(0.0, 0.65, 0.0)
	star.add_child(col)
	if _res_star != null:
		star.add_child(_res_star.instantiate())
	star.star_collected.connect(_on_star_collected)
	return star


func _unlock_bridge() -> void:
	if _bridge_node == null or _bridge_node.visible:
		return
	_bridge_node.visible = true
	_bridge_node.process_mode = Node.PROCESS_MODE_INHERIT
	_bridge_node.scale = Vector3(0.1, 0.1, 0.1)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bridge_node, "scale", Vector3.ONE, 0.45)
	_sfx.play_bridge()
	_env_polish.spawn_celebration_burst(_bridge_node.global_position + Vector3(0.0, 0.6, 0.0), Color("32D4E8"))


func _on_star_collected(world_pos: Vector3) -> void:
	_stars_collected += 1
	_sfx.play_star()
	_camera.celebrate_zoom()
	_env_polish.spawn_celebration_burst(world_pos, Color("FFD23F"))
	if _stars_collected >= 3:
		_save_win(_current_level_id, _stars_collected)
		await get_tree().create_timer(0.55).timeout
		_sfx.play_win()
		_level_complete.show_celebration(
			_current_level_id,
			str(_current_level_info.get("level_name", "")),
			_stars_collected
		)


func _save_win(lvl_id: int, stars: int) -> void:
	var prev: int = int(_progress["stars_by_level"].get(str(lvl_id), 0))
	_progress["stars_by_level"][str(lvl_id)] = maxi(prev, stars)
	if lvl_id >= int(_progress.get("unlocked_level", 1)) and lvl_id < 100:
		_progress["unlocked_level"] = lvl_id + 1
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(_progress))


func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary:
		_progress = parsed


func _v3(arr: Array) -> Vector3:
	return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
