extends Node
# PHÁT ÂM THANH AN TOÀN: thiếu file thì im lặng, không báo lỗi, game không sập.
# Cách dùng trong code (main.gd có biến audio):
#   audio.play_sfx("click")     # phát assets/audio/click.ogg (hoặc .wav / .mp3)
#   audio.play_music("nen")     # phát nhạc nền assets/audio/nen.ogg
#   audio.stop_music()
# Muốn nhạc lặp lại: chọn file trong Godot, tab Import, bật Loop rồi Reimport.

const AUDIO_DIR := "res://assets/audio/"
const EXTENSIONS := ["ogg", "wav", "mp3"]
const SFX_CHANNELS := 6

var _sfx_players: Array = []
var _music: AudioStreamPlayer
var _loop_music := false

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.volume_db = -15.0
	add_child(_music)
	_music.finished.connect(_on_music_finished)
	for i in SFX_CHANNELS:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)

func _find(sound_name: String) -> AudioStream:
	for ext in EXTENSIONS:
		var path: String = AUDIO_DIR + sound_name + "." + ext
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null

func play_sfx(sound_name: String) -> void:
	var s := _find(sound_name)
	if s == null:
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = s
			p.play()
			return

func play_music(sound_name: String) -> void:
	var s := _find(sound_name)
	if s == null:
		return
	if _music.stream == s and _music.playing:
		return
	_loop_music = true
	_music.stream = s
	_music.play()

func stop_music() -> void:
	_loop_music = false
	_music.stop()

func _on_music_finished() -> void:
	if _loop_music and _music.stream != null:
		_music.play()
