extends Node
class_name SoundFX

## Tashqi audio faylsiz ishlaydigan quvnoq ovoz effektlari sintezatori (Godot 4).
## Sakrash, yulduzcha, kub qulflanishi, ko'prik ochilishi va g'alaba ohanglarini yaratadi.

var _sample_rate: float = 22050.0


func play_jump() -> void:
	_play_tone_sequence([
		{"f0": 320.0, "f1": 620.0, "dur": 0.14, "vol": 0.22},
	])


func play_star() -> void:
	_play_tone_sequence([
		{"f0": 587.3, "f1": 587.3, "dur": 0.08, "vol": 0.22},
		{"f0": 784.0, "f1": 784.0, "dur": 0.08, "vol": 0.24},
		{"f0": 1046.5, "f1": 1174.6, "dur": 0.16, "vol": 0.25},
	])


func play_plate() -> void:
	_play_tone_sequence([
		{"f0": 440.0, "f1": 440.0, "dur": 0.07, "vol": 0.20},
		{"f0": 659.2, "f1": 659.2, "dur": 0.14, "vol": 0.24},
	])


func play_bridge() -> void:
	_play_tone_sequence([
		{"f0": 392.0, "f1": 392.0, "dur": 0.08, "vol": 0.20},
		{"f0": 493.9, "f1": 493.9, "dur": 0.08, "vol": 0.22},
		{"f0": 587.3, "f1": 587.3, "dur": 0.08, "vol": 0.24},
		{"f0": 784.0, "f1": 784.0, "dur": 0.22, "vol": 0.26},
	])


func play_fox() -> void:
	_play_tone_sequence([
		{"f0": 700.0, "f1": 980.0, "dur": 0.07, "vol": 0.20},
		{"f0": 760.0, "f1": 1080.0, "dur": 0.09, "vol": 0.22},
	])


func play_win() -> void:
	_play_tone_sequence([
		{"f0": 523.2, "f1": 523.2, "dur": 0.10, "vol": 0.22},
		{"f0": 659.2, "f1": 659.2, "dur": 0.10, "vol": 0.22},
		{"f0": 784.0, "f1": 784.0, "dur": 0.10, "vol": 0.24},
		{"f0": 1046.5, "f1": 1046.5, "dur": 0.30, "vol": 0.28},
	])


func play_tap() -> void:
	_play_tone_sequence([
		{"f0": 520.0, "f1": 640.0, "dur": 0.05, "vol": 0.15},
	])


func _play_tone_sequence(notes: Array) -> void:
	var total_samples := 0
	for n in notes:
		total_samples += int(float(n["dur"]) * _sample_rate)
	if total_samples <= 0:
		return

	var data := PackedByteArray()
	data.resize(total_samples * 2)
	var write_idx := 0
	var phase := 0.0

	for n in notes:
		var count := int(float(n["dur"]) * _sample_rate)
		var f0: float = float(n["f0"])
		var f1: float = float(n["f1"])
		var vol: float = float(n["vol"])
		for i in range(count):
			var t := float(i) / float(maxi(count, 1))
			var freq := lerpf(f0, f1, t)
			# Yumshoq kirish va chiqish (bolalar qulog'iga yoqimli)
			var env := minf(t * 14.0, 1.0) * (1.0 - t * 0.85)
			phase += TAU * freq / _sample_rate
			var sample := sin(phase) * 0.8 + sin(phase * 2.0) * 0.2
			var pcm := int(clampf(sample * vol * env, -1.0, 1.0) * 32767.0)
			data[write_idx] = pcm & 0xFF
			data[write_idx + 1] = (pcm >> 8) & 0xFF
			write_idx += 2

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(_sample_rate)
	wav.stereo = false
	wav.data = data

	var player := AudioStreamPlayer.new()
	player.stream = wav
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
