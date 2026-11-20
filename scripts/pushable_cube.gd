extends RigidBody3D
class_name PushableCube

signal placed_on_target(cube: PushableCube)

@export var max_slide_speed: float = 3.5
@export var linear_friction_damp: float = 6.5

var spawn_position: Vector3 = Vector3.ZERO
var is_locked: bool = false


func _ready() -> void:
	add_to_group("pushable_cubes")
	spawn_position = global_position
	lock_rotation = true
	linear_damp = linear_friction_damp
	mass = 2.4


func _physics_process(_delta: float) -> void:
	if not is_locked and global_position.y < -3.0:
		global_position = spawn_position + Vector3(0.0, 0.4, 0.0)
		linear_velocity = Vector3.ZERO


func push(direction: Vector3, strength: float) -> void:
	if is_locked:
		return
	var flat_dir := Vector3(direction.x, 0.0, direction.z).normalized()
	apply_central_impulse(flat_dir * strength * 0.28)
	var horiz := Vector2(linear_velocity.x, linear_velocity.z)
	if horiz.length() > max_slide_speed:
		horiz = horiz.normalized() * max_slide_speed
		linear_velocity.x = horiz.x
		linear_velocity.z = horiz.y


func snap_to_position(target_pos: Vector3) -> void:
	if is_locked:
		return
	is_locked = true
	freeze = true
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "global_position", target_pos, 0.25)
	placed_on_target.emit(self)
