extends CharacterBody3D
class_name FoxCompanion

@export var follow_speed: float = 4.3
@export var dash_speed: float = 6.8
@export var follow_distance: float = 1.55
@export var stop_distance: float = 1.1
@export var gravity: float = 16.5

var target: Node3D
var sfx: SoundFX
var _visual: Node3D
var _visual_base_y: float = 0.0
var _hop_time: float = 0.0
var _is_dashing: bool = false


func _ready() -> void:
	_visual = get_node_or_null("Visual") as Node3D
	if _visual != null:
		_visual_base_y = _visual.position.y


func _physics_process(delta: float) -> void:
	if target == null:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0] as Node3D

	if global_position.y < -3.2 and target != null:
		global_position = target.global_position + Vector3(-0.8, 0.4, -0.4)
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if target == null:
		move_and_slide()
		return

	var to_target: Vector3 = target.global_position - global_position
	var flat_vec := Vector3(to_target.x, 0.0, to_target.z)
	var dist := flat_vec.length()

	var desired_dist := stop_distance if _is_dashing else follow_distance
	if dist > desired_dist:
		var dir := flat_vec.normalized()
		var speed := dash_speed if _is_dashing else follow_speed
		velocity.x = lerpf(velocity.x, dir.x * speed, 8.0 * delta)
		velocity.z = lerpf(velocity.z, dir.z * speed, 8.0 * delta)
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 9.0 * delta)
		_animate_hop(delta, true)
	else:
		_is_dashing = false
		velocity.x = move_toward(velocity.x, 0.0, follow_speed * 6.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, follow_speed * 6.0 * delta)
		_animate_hop(delta, false)

	move_and_slide()


func call_to_player() -> void:
	_is_dashing = true
	if is_on_floor():
		velocity.y = 4.8
	if sfx != null:
		sfx.play_fox()


func _animate_hop(delta: float, is_moving: bool) -> void:
	if _visual == null:
		return
	if is_moving and is_on_floor():
		_hop_time += delta * 12.5
		_visual.position.y = _visual_base_y + absf(sin(_hop_time)) * 0.12
	else:
		_hop_time = 0.0
		_visual.position.y = lerpf(_visual.position.y, _visual_base_y, 10.0 * delta)
