extends CharacterBody3D
class_name PlayerController

signal star_count_changed(new_count: int)

@export var move_speed: float = 4.6
@export var rotation_speed: float = 11.0
@export var jump_velocity: float = 6.5
@export var gravity: float = 16.5
@export var coyote_time: float = 0.16
@export var push_force: float = 3.4
@export var interact_distance: float = 1.45

var spawn_position: Vector3 = Vector3(-2.5, 0.1, 2.0)
var stars_collected: int = 0
var sfx: SoundFX

var _joystick_input: Vector2 = Vector2.ZERO
var _coyote_timer: float = 0.0
var _bob_time: float = 0.0
var _visual: Node3D
var _visual_base_y: float = 0.0


func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	_visual = get_node_or_null("Visual") as Node3D
	if _visual != null:
		_visual_base_y = _visual.position.y


func _physics_process(delta: float) -> void:
	# Suvga yoki pastga tushib ketsa jazosiz qaytarib qo'yish (bolalar uchun)
	if global_position.y < -3.2:
		global_position = spawn_position + Vector3(0.0, 0.5, 0.0)
		velocity = Vector3.ZERO
		return

	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept"):
		trigger_jump()

	var input_vec: Vector2 = _joystick_input
	if input_vec.length() < 0.05:
		input_vec = Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")
		)

	var direction := Vector3(input_vec.x, 0.0, input_vec.y)
	if direction.length() > 1.0:
		direction = direction.normalized()

	if direction.length() > 0.05:
		velocity.x = lerpf(velocity.x, direction.x * move_speed, 12.0 * delta)
		velocity.z = lerpf(velocity.z, direction.z * move_speed, 12.0 * delta)
		var target_angle := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
		_animate_walk_bob(delta, true)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)
		_animate_walk_bob(delta, false)

	move_and_slide()
	_push_colliding_cubes()


func set_joystick_vector(vec: Vector2) -> void:
	_joystick_input = vec.limit_length(1.0)


func trigger_jump() -> void:
	if _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_coyote_timer = 0.0
		if sfx != null:
			sfx.play_jump()


func trigger_push() -> void:
	var forward := Vector3(sin(rotation.y), 0.0, cos(rotation.y)).normalized()
	for cube in get_tree().get_nodes_in_group("pushable_cubes"):
		if cube is PushableCube:
			var to_cube: Vector3 = cube.global_position - global_position
			to_cube.y = 0.0
			if to_cube.length() <= interact_distance and forward.dot(to_cube.normalized()) > 0.25:
				cube.push(forward, push_force * 1.8)
				if sfx != null:
					sfx.play_tap()


func add_star(amount: int = 1) -> void:
	stars_collected += amount
	star_count_changed.emit(stars_collected)


func _push_colliding_cubes() -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider is PushableCube:
			var push_dir := -col.get_normal()
			push_dir.y = 0.0
			if push_dir.length() > 0.01:
				collider.push(push_dir.normalized(), push_force)


func _animate_walk_bob(delta: float, is_moving: bool) -> void:
	if _visual == null:
		return
	if is_moving and is_on_floor():
		_bob_time += delta * 11.5
		_visual.position.y = _visual_base_y + absf(sin(_bob_time)) * 0.065
	else:
		_bob_time = 0.0
		_visual.position.y = lerpf(_visual.position.y, _visual_base_y, 10.0 * delta)
