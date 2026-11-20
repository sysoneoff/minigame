extends Camera3D
class_name FollowCamera

@export var offset: Vector3 = Vector3(0.0, 6.2, 7.2)
@export var look_at_height: float = 0.75
@export var smooth_speed: float = 6.5
@export var look_ahead_distance: float = 0.75
@export var clamp_to_island: bool = true
@export var bounds_min: Vector2 = Vector2(-4.5, -3.5)
@export var bounds_max: Vector2 = Vector2(4.5, 3.5)

var target: Node3D
var menu_orbit_mode: bool = true
var _orbit_angle: float = 0.0
var _look_ahead_offset: Vector3 = Vector3.ZERO
var _zoom_factor: float = 1.0


func _physics_process(delta: float) -> void:
	if menu_orbit_mode:
		_orbit_angle += delta * 0.22
		global_position = Vector3(sin(_orbit_angle) * 10.5, 6.0, cos(_orbit_angle) * 10.5)
		look_at(Vector3(0.0, 0.5, 0.0), Vector3.UP)
		return

	if target == null or not is_instance_valid(target):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0] as Node3D
		return

	var focus_pos: Vector3 = target.global_position
	var desired_ahead := Vector3.ZERO
	if target is CharacterBody3D:
		var vel: Vector3 = (target as CharacterBody3D).velocity
		var flat_vel := Vector3(vel.x, 0.0, vel.z)
		if flat_vel.length() > 0.25:
			desired_ahead = flat_vel.normalized() * look_ahead_distance

	var weight := 1.0 - exp(-smooth_speed * delta)
	_look_ahead_offset = _look_ahead_offset.lerp(desired_ahead, weight * 0.65)
	var desired_pos := _compute_desired_position(focus_pos + _look_ahead_offset)
	global_position = global_position.lerp(desired_pos, weight)
	look_at(focus_pos + _look_ahead_offset * 0.5 + Vector3(0.0, look_at_height, 0.0), Vector3.UP)


func snap_to_target(new_target: Node3D) -> void:
	target = new_target
	menu_orbit_mode = false
	if target != null:
		global_position = _compute_desired_position(target.global_position)
		look_at(target.global_position + Vector3(0.0, look_at_height, 0.0), Vector3.UP)


func celebrate_zoom() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_zoom_factor", 0.88, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_zoom_factor", 1.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _compute_desired_position(base_pos: Vector3) -> Vector3:
	var clamped := base_pos
	if clamp_to_island:
		clamped.x = clampf(clamped.x, bounds_min.x, bounds_max.x)
		clamped.z = clampf(clamped.z, bounds_min.y, bounds_max.y)
	return clamped + offset * _zoom_factor
