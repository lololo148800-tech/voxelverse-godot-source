extends Node

const SAMPLE_RATE: int = 22050
const POOL_SIZE: int = 8

var players: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var event_counts: Dictionary = {}
var played_counts: Dictionary = {}
var last_play_msec: Dictionary = {}
var cooldowns: Dictionary = {
    "ui_click": 0.06,
    "footstep": 0.18,
    "block_break_start": 0.08,
    "block_break": 0.06,
    "block_place": 0.08,
    "weapon_swing": 0.08,
    "weapon_hit": 0.06,
    "player_hurt": 0.06,
    "player_death": 0.2,
    "mob_attack": 0.12,
    "mob_hit": 0.06,
    "mob_death": 0.12,
    "bird": 2.0,
}
var cursor: int = 0
var audio_ready: bool = false

func _ready() -> void:
    _build_streams()
    if DisplayServer.get_name() == "headless":
        return
    for index in range(POOL_SIZE):
        var player := AudioStreamPlayer.new()
        player.name = "SfxPool_%d" % index
        player.volume_db = -7.0
        add_child(player)
        players.append(player)
    audio_ready = true

func _exit_tree() -> void:
    for player in players:
        if is_instance_valid(player):
            player.stop()
    players.clear()
    streams.clear()

func _build_streams() -> void:
    streams["ui_click"] = _make_stream(690.0, 0.055, 0.20, 0.0, 0.0)
    streams["footstep"] = _make_stream(86.0, 0.095, 0.24, 0.0, 0.0)
    streams["block_break_start"] = _make_stream(118.0, 0.07, 0.16, 0.0, 0.0)
    streams["block_break"] = _make_stream(104.0, 0.13, 0.30, 0.0, 0.0)
    streams["block_place"] = _make_stream(230.0, 0.10, 0.17, 0.0, 0.0)
    streams["weapon_swing"] = _make_stream(330.0, 0.12, 0.16, 250.0, -150.0)
    streams["weapon_hit"] = _make_stream(148.0, 0.12, 0.27, 0.0, 0.0)
    streams["player_hurt"] = _make_stream(180.0, 0.10, 0.22, 0.0, 0.0)
    streams["player_death"] = _make_stream(230.0, 0.62, 0.25, -160.0, 0.0)
    streams["mob_attack"] = _make_stream(112.0, 0.16, 0.22, 0.0, 0.0)
    streams["mob_hit"] = _make_stream(175.0, 0.10, 0.19, 0.0, 0.0)
    streams["mob_death"] = _make_stream(74.0, 0.32, 0.23, -25.0, 0.0)
    streams["bird"] = _make_stream(820.0, 0.34, 0.12, 360.0, 0.0)

func _make_stream(start_frequency: float, duration: float, volume: float, frequency_delta: float, _unused: float) -> AudioStreamWAV:
    var sample_count := int(float(SAMPLE_RATE) * duration)
    var data := PackedByteArray()
    data.resize(sample_count * 2)
    for index in range(sample_count):
        var t := float(index) / float(SAMPLE_RATE)
        var progress := clampf(t / maxf(duration, 0.001), 0.0, 1.0)
        var frequency := maxf(35.0, start_frequency + frequency_delta * progress)
        var envelope := pow(maxf(0.0, 1.0 - progress), 1.65)
        var sample := sin(TAU * frequency * t) * volume * envelope
        sample += sin(TAU * frequency * 0.5 * t) * volume * 0.18 * envelope
        var pcm := clampi(int(sample * 30000.0), -32768, 32767)
        var offset := index * 2
        data[offset] = pcm & 0xff
        data[offset + 1] = (pcm >> 8) & 0xff
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false
    stream.data = data
    return stream

func play_event(event_name: String, intensity: float = 1.0) -> bool:
    event_counts[event_name] = int(event_counts.get(event_name, 0)) + 1
    var now := Time.get_ticks_msec()
    var cooldown := float(cooldowns.get(event_name, 0.0))
    var last := int(last_play_msec.get(event_name, -1000000))
    if now - last < int(cooldown * 1000.0):
        return false
    last_play_msec[event_name] = now
    played_counts[event_name] = int(played_counts.get(event_name, 0)) + 1
    if not audio_ready or players.is_empty():
        return true
    var player := players[cursor % players.size()]
    cursor = (cursor + 1) % players.size()
    player.stream = streams.get(event_name, streams.get("ui_click"))
    player.pitch_scale = clampf(0.94 + intensity * 0.08, 0.82, 1.28)
    player.volume_db = clampf(-10.0 + intensity * 2.0, -14.0, -4.0)
    player.play()
    return true

func get_event_count(event_name: String) -> int:
    return int(event_counts.get(event_name, 0))

func get_played_count(event_name: String) -> int:
    return int(played_counts.get(event_name, 0))

func reset_test_counters() -> void:
    event_counts.clear()
    played_counts.clear()
    last_play_msec.clear()

