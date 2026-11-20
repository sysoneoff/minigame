extends Area3D
class_name GoldenStar

signal star_collected(world_pos: Vector3)

@export var spin_speed: float = 2.0
@export var bob_height: float = 0.11
@export var bob_speed: float = 2.8

var _star_node: Node3D
var _base_y: float = 0.0
var _time: float = 0.0
var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_star_node = find_child("Star", true, false) as Node3D
	if _star_node != null:
		_base_y = _star_node.position.y


func _process(delta: float) -> void:
	if _collected or _star_node == null:
		return
	_time += delta
	_star_node.rotate_y(spin_speed * delta)
	_star_node.position.y = _base_y + sin(_time * bob_speed) * bob_height


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	if body.has_method("add_star"):
		body.add_star(1)
	star_collected.emit(global_position + Vector3(0.0, 0.7, 0.0))

	if _star_node != null:
		var tween := create_tween().set_parallel(true)
		tween.tween_property(_star_node, "position:y", _base_y + 0.7, 0.35).set_ease(Tween.EASE_OUT)
		tween.tween_property(_star_node, "scale", Vector3.ZERO, 0.35).set_ease(Tween.EASE_IN)
		await tween.finished
		_star_node.visible = false
	set_deferred("monitoring", false)
