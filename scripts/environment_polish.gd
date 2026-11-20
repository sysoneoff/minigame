extends Node3D
class_name EnvironmentPolish

## Yorqin osmon, quyosh nuri, suzib yuruvchi low-poly bulutlar, uzoq orolchalar
## va yulduzcha yig'ilgandagi bayramona uchqun effektlari.

var _world_env: WorldEnvironment
var _sky_mat: ProceduralSkyMaterial
var _clouds: Array[Node3D] = []
var _time: float = 0.0


func _ready() -> void:
	_setup_lighting_and_sky()
	_spawn_fluffy_clouds()
	_spawn_distant_islands()


func _setup_lighting_and_sky() -> void:
	_world_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	_sky_mat = ProceduralSkyMaterial.new()
	_sky_mat.sky_top_color = Color("36B3FF")
	_sky_mat.sky_horizon_color = Color("A8E6FF")
	_sky_mat.ground_bottom_color = Color("62C8FF")
	_sky_mat.ground_horizon_color = Color("B8ECFF")
	_sky_mat.sun_angle_max = 22.0
	sky.sky_material = _sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_world_env.environment = env
	add_child(_world_env)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color("FFF7E2")
	sun.light_energy = 1.25
	sun.rotation_degrees = Vector3(-48.0, 32.0, 0.0)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	add_child(sun)


func set_sky_theme(hex_color: String) -> void:
	if _sky_mat == null:
		return
	var base := Color(hex_color)
	_sky_mat.sky_top_color = base.darkened(0.08)
	_sky_mat.sky_horizon_color = base.lightened(0.38)
	_sky_mat.ground_bottom_color = base.lightened(0.15)
	_sky_mat.ground_horizon_color = base.lightened(0.42)


func _spawn_fluffy_clouds() -> void:
	var cloud_mat := StandardMaterial3D.new()
	cloud_mat.albedo_color = Color("FFFFFF")
	cloud_mat.roughness = 0.92

	var positions := [
		Vector3(-9.5, 4.2, -7.5),
		Vector3(9.0, 4.8, -6.5),
		Vector3(-11.0, 2.8, 3.0),
		Vector3(10.5, 3.4, 4.5),
		Vector3(0.5, 5.4, -10.5),
	]
	for p in positions:
		var cloud := Node3D.new()
		cloud.position = p
		cloud.set_meta("base_pos", p)
		cloud.set_meta("phase", randf() * TAU)
		for puff in [
			[Vector3(0.0, 0.0, 0.0), 1.1],
			[Vector3(-1.05, -0.15, 0.1), 0.78],
			[Vector3(1.05, -0.1, -0.1), 0.85],
			[Vector3(0.35, 0.45, 0.05), 0.72],
		]:
			var mi := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radial_segments = 8
			sph.rings = 5
			sph.radius = puff[1]
			sph.height = puff[1] * 1.75
			sph.material = cloud_mat
			mi.mesh = sph
			mi.position = puff[0]
			cloud.add_child(mi)
		add_child(cloud)
		_clouds.append(cloud)


func _spawn_distant_islands() -> void:
	var dirt_mat := StandardMaterial3D.new()
	dirt_mat.albedo_color = Color("D48A62")
	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_color = Color("8EE048")

	for cfg in [
		[Vector3(-13.5, -1.2, -8.0), 1.8],
		[Vector3(14.0, -0.8, -7.0), 1.5],
		[Vector3(12.5, -2.0, 6.5), 1.2],
	]:
		var isl := Node3D.new()
		isl.position = cfg[0]
		var sc: float = cfg[1]

		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 1.2 * sc
		cm.bottom_radius = 0.05
		cm.height = 1.6 * sc
		cm.radial_segments = 7
		cm.material = dirt_mat
		cone.mesh = cm
		cone.position.y = -0.8 * sc
		isl.add_child(cone)

		var top := MeshInstance3D.new()
		var tm := CylinderMesh.new()
		tm.top_radius = 1.3 * sc
		tm.bottom_radius = 1.22 * sc
		tm.height = 0.35 * sc
		tm.radial_segments = 7
		tm.material = grass_mat
		top.mesh = tm
		isl.add_child(top)
		add_child(isl)


func spawn_celebration_burst(world_pos: Vector3, tint: Color = Color("FFD23F")) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 0.9

	for i in range(10):
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.14, 0.14, 0.14)
		box.material = mat
		mi.mesh = box
		mi.position = world_pos
		add_child(mi)

		var angle := (TAU / 10.0) * i
		var target := world_pos + Vector3(cos(angle) * 1.1, randf_range(0.8, 1.5), sin(angle) * 1.1)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(mi, "position", target, 0.55).set_ease(Tween.EASE_OUT)
		tw.tween_property(mi, "rotation_degrees", Vector3(180, 270, 90), 0.55)
		tw.tween_property(mi, "scale", Vector3.ZERO, 0.55).set_ease(Tween.EASE_IN)
		tw.finished.connect(mi.queue_free)


func _process(delta: float) -> void:
	_time += delta
	for c in _clouds:
		var base: Vector3 = c.get_meta("base_pos")
		var ph: float = c.get_meta("phase")
		c.position.y = base.y + sin(_time * 0.7 + ph) * 0.35
		c.position.x = base.x + cos(_time * 0.25 + ph) * 0.65
