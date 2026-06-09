extends Node

# SoundManager hahahaha

const BGM_VILLAGE = "res://art/8_bit_iced_village_lofi.mp3"
const SFX_AXE = "res://art/axe.ogg"
const SFX_BLOCK = "res://art/block.ogg"
const SFX_ENEMY_ATTACK = "res://art/enemy_attack.ogg"
const SFX_ENEMY_BLOCK = "res://art/enemy_block.ogg"

#warrior sfx
const SFX_SLASHES = [
	"res://audio/SFX/Attacks/Sword Attacks Hits and Blocks/Sword Attack 1.ogg",
	"res://audio/SFX/Attacks/Sword Attacks Hits and Blocks/Sword Attack 2.ogg",
	"res://audio/SFX/Attacks/Sword Attacks Hits and Blocks/Sword Attack 3.ogg"
]
const SFX_HIT = [
	"res://audio/SFX/Attacks/Sword Attacks Hits and Blocks/Sword Impact Hit 1.ogg",
	"res://audio/SFX/Attacks/Sword Attacks Hits and Blocks/Sword Impact Hit 2.ogg",
	"res://audio/SFX/Attacks/Sword Attacks Hits and Blocks/Sword Impact Hit 3.ogg"
]
const SFX_DEATH = "res://audio/UI/JDSherbert - Ultimate UI SFX Pack - Cancel - 2.ogg"

#boss1 sfx
const SFX_E1SLASH = "res://audio/SFX/Spells/Ice Freeze 2.ogg"
const SFX_E1HIT = "res://audio/SFX/Spells/Spell Impact 2.ogg"
const SFX_E1DEATH = "res://audio/SFX/Spells/Ice Wall 2.ogg"

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_count: int = 12

func _ready() -> void:
	# Initialize BGM player
	bgm_player = AudioStreamPlayer.new()
	# Check if Music bus exists, otherwise use Master
	bgm_player.bus = _get_valid_bus("Music")
	add_child(bgm_player)
	
	# Pre-allocate SFX players
	for i in range(max_sfx_count):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = _get_valid_bus("SFX")
		add_child(p)
		sfx_players.append(p)

func _get_valid_bus(bus_name: String) -> String:
	if AudioServer.get_bus_index(bus_name) != -1:
		return bus_name
	return "Master"

## Plays a background music track. 
## [param stream] can be an AudioStream or a resource path string.
func play_bgm(stream: Variant, volume_db: float = 0.0, fade_duration: float = 1.0) -> void:
	var audio_stream: AudioStream = _get_stream(stream)
	if not audio_stream:
		return
		
	if bgm_player.stream == audio_stream and bgm_player.playing:
		return
		
	if fade_duration > 0 and bgm_player.playing:
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration)
		tween.tween_callback(func(): _start_bgm(audio_stream, volume_db, fade_duration))
	else:
		_start_bgm(audio_stream, volume_db, fade_duration)

func _start_bgm(audio_stream: AudioStream, volume_db: float, fade_duration: float) -> void:
	bgm_player.stream = audio_stream
	bgm_player.volume_db = -80.0 if fade_duration > 0 else volume_db
	bgm_player.play()
	if fade_duration > 0:
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", volume_db, fade_duration)

## Stops the current background music with optional fade.
func stop_bgm(fade_duration: float = 1.0) -> void:
	if fade_duration > 0 and bgm_player.playing:
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration)
		tween.tween_callback(bgm_player.stop)
	else:
		bgm_player.stop()

## Plays a sound effect.
## [param stream] can be an AudioStream or a resource path string.
func play_sfx(stream: Variant, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var audio_stream: AudioStream = _get_stream(stream)
	if not audio_stream:
		return
		
	var player: AudioStreamPlayer = _get_available_sfx_player()
	player.stream = audio_stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func _get_stream(stream: Variant) -> AudioStream:
	if stream is AudioStream:
		return stream
	if stream is String:
		if FileAccess.file_exists(stream):
			return load(stream) as AudioStream
		else:
			push_error("SoundManager: Audio file not found at " + stream)
	return null

func _get_available_sfx_player() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	# If all are busy, reuse the first one
	return sfx_players[0]

## Plays a random sound effect from a list.
## [param streams] an Array of AudioStreams or resource path strings.
func play_random_sfx(streams: Array, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if streams.is_empty():
		return
	play_sfx(streams.pick_random(), volume_db, pitch_scale)
