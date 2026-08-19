extends Node

signal status_changed(message: String)

const VOICE_BUS_NAME := "VoiceCapture"
const VOICE_SAMPLE_RATE: int = 8000
const MAX_PACKET_BYTES: int = 4096
const CAPTURE_WINDOW_SECONDS: float = 0.08
const MAX_PACKETS_PER_SECOND: int = 20
const MAX_SEQUENCE_AHEAD: int = 128

var enabled: bool = false
var push_to_talk: bool = true
var speaking: bool = false
var last_status: String = "Voice chat off by default"
var muted_peers: Dictionary = {}
var capture_bus_index: int = -1
var capture_effect: AudioEffectCapture
var microphone_player: AudioStreamPlayer
var playback_players: Dictionary = {}
var voice_session_token: String = ""
var voice_authorized: bool = false
var handshake_requested: bool = false
var packet_sequence: int = 0
var last_sequence_by_peer: Dictionary = {}
var rate_window_by_peer: Dictionary = {}

func _ready() -> void:
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    voice_session_token = _make_session_token()

func set_enabled(active: bool) -> void:
    if active == enabled:
        return
    enabled = active
    if enabled:
        voice_authorized = NetworkSession.is_host()
        handshake_requested = false
        if not _start_capture():
            enabled = false
            voice_authorized = false
            _set_status("Voice chat unavailable: microphone capture could not start")
            return
        _set_status("Voice enabled locally; F6 push-to-talk; transport is opt-in")
    else:
        _stop_capture()
        voice_authorized = false
        handshake_requested = false
        packet_sequence = 0
        _set_status("Voice chat disabled")

func set_push_to_talk(active: bool) -> void:
    push_to_talk = active
    _set_status("Voice mode: push-to-talk" if push_to_talk else "Voice mode: open mic")

func set_peer_muted(peer_id: int, muted: bool) -> void:
    muted_peers[peer_id] = muted

func is_peer_muted(peer_id: int) -> bool:
    return bool(muted_peers.get(peer_id, false))

func _process(_delta: float) -> void:
    if not enabled:
        speaking = false
        return
    speaking = not push_to_talk or Input.is_key_pressed(KEY_F6)
    if not NetworkSession.is_online():
        return
    if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
        return
    if not voice_authorized:
        if not handshake_requested and not NetworkSession.is_host():
            handshake_requested = true
            rpc_id(1, "request_voice_session")
        return
    if not speaking:
        return
    if capture_effect == null or not capture_effect.can_get_buffer(1):
        return
    var frames_available := mini(capture_effect.get_frames_available(), 2048)
    if frames_available <= 0:
        return
    var frames := capture_effect.get_buffer(frames_available)
    var audio := _encode_frames(frames)
    if audio.size() <= 0 or audio.size() > MAX_PACKET_BYTES:
        return
    packet_sequence += 1
    var payload := {"token": voice_session_token, "sequence": packet_sequence, "audio": audio}
    if NetworkSession.is_host():
        _relay_voice_packet(multiplayer.get_unique_id(), payload)
    else:
        rpc_id(1, "submit_voice_packet", payload)

func _start_capture() -> bool:
    if capture_effect != null and is_instance_valid(microphone_player):
        return true
    capture_bus_index = AudioServer.get_bus_index(VOICE_BUS_NAME)
    if capture_bus_index < 0:
        AudioServer.add_bus()
        capture_bus_index = AudioServer.bus_count - 1
        AudioServer.set_bus_name(capture_bus_index, VOICE_BUS_NAME)
    if AudioServer.get_bus_effect_count(capture_bus_index) == 0:
        capture_effect = AudioEffectCapture.new()
        AudioServer.add_bus_effect(capture_bus_index, capture_effect)
    else:
        capture_effect = AudioServer.get_bus_effect(capture_bus_index, 0) as AudioEffectCapture
    if capture_effect == null:
        return false
    microphone_player = AudioStreamPlayer.new()
    microphone_player.name = "MicrophoneCapture"
    microphone_player.stream = AudioStreamMicrophone.new()
    microphone_player.bus = VOICE_BUS_NAME
    add_child(microphone_player)
    microphone_player.play()
    return true

func _stop_capture() -> void:
    speaking = false
    if is_instance_valid(microphone_player):
        microphone_player.stop()
        microphone_player.queue_free()
    microphone_player = null
    capture_effect = null
    capture_bus_index = -1

func _encode_frames(frames: PackedVector2Array) -> PackedByteArray:
    if frames.is_empty():
        return PackedByteArray()
    var input_rate := maxf(8000.0, AudioServer.get_mix_rate())
    var step := maxf(1.0, input_rate / float(VOICE_SAMPLE_RATE))
    var sample_count := maxi(1, int(floor(float(frames.size()) / step)))
    var packet := PackedByteArray()
    packet.resize(sample_count * 2)
    var output_index := 0
    var input_index := 0.0
    while output_index < sample_count and int(input_index) < frames.size():
        var sample_frame := frames[int(input_index)]
        var mono := clampf((sample_frame.x + sample_frame.y) * 0.5, -1.0, 1.0)
        packet.encode_s16(output_index * 2, int(mono * 32767.0))
        output_index += 1
        input_index += step
    if output_index < sample_count:
        packet.resize(output_index * 2)
    return packet

func _make_session_token() -> String:
    var seed_text := "%d|%d|%s" % [Time.get_ticks_usec(), randi(), OS.get_unique_id()]
    return seed_text.md5_text().substr(0, 16)

@rpc("any_peer", "reliable")
func request_voice_session() -> void:
    if not multiplayer.is_server() or not enabled:
        return
    var sender := multiplayer.get_remote_sender_id()
    rpc_id(sender, "receive_voice_session", voice_session_token)

@rpc("authority", "reliable")
func receive_voice_session(token: String) -> void:
    if token.is_empty() or not enabled:
        return
    voice_session_token = token
    voice_authorized = true
    handshake_requested = false
    _set_status("Voice transport authorized; mute and push-to-talk remain available")

@rpc("any_peer", "unreliable")
func submit_voice_packet(payload: Dictionary) -> void:
    if not multiplayer.is_server() or not enabled:
        return
    var sender := multiplayer.get_remote_sender_id()
    if not _validate_payload(payload, voice_session_token, sender, true):
        return
    _relay_voice_packet(sender, payload)

func _relay_voice_packet(sender_id: int, payload: Dictionary) -> void:
    if not NetworkSession.is_online():
        return
    for peer_id in multiplayer.get_peers():
        if peer_id != sender_id:
            rpc_id(peer_id, "receive_voice_packet", sender_id, payload)

@rpc("authority", "unreliable")
func receive_voice_packet(sender_id: int, payload: Dictionary) -> void:
    if not enabled or is_peer_muted(sender_id):
        return
    if not _validate_payload(payload, voice_session_token, sender_id, false):
        return
    var playback := _get_playback(sender_id)
    if playback == null:
        return
    var audio: PackedByteArray = payload.get("audio", PackedByteArray())
    var frames := PackedVector2Array()
    for offset in range(0, audio.size() - 1, 2):
        var sample := float(audio.decode_s16(offset)) / 32768.0
        frames.append(Vector2(sample, sample))
    if not frames.is_empty():
        playback.push_buffer(frames)

func _validate_payload(payload: Dictionary, expected_token: String, peer_id: int, enforce_rate: bool) -> bool:
    if str(payload.get("token", "")) != expected_token:
        return false
    var sequence := int(payload.get("sequence", -1))
    var audio: PackedByteArray = payload.get("audio", PackedByteArray())
    if sequence < 0 or audio.is_empty() or audio.size() > MAX_PACKET_BYTES or audio.size() % 2 != 0:
        return false
    var previous := int(last_sequence_by_peer.get(peer_id, -1))
    if sequence <= previous or sequence > previous + MAX_SEQUENCE_AHEAD:
        return false
    if enforce_rate and not _allow_rate(peer_id):
        return false
    last_sequence_by_peer[peer_id] = sequence
    return true

func _allow_rate(peer_id: int) -> bool:
    var now := Time.get_ticks_msec()
    var window: Dictionary = rate_window_by_peer.get(peer_id, {"start": now, "count": 0})
    if now - int(window.get("start", now)) >= 1000:
        window = {"start": now, "count": 0}
    var count := int(window.get("count", 0)) + 1
    window["count"] = count
    rate_window_by_peer[peer_id] = window
    return count <= MAX_PACKETS_PER_SECOND

func _get_playback(peer_id: int) -> AudioStreamGeneratorPlayback:
    var player: AudioStreamPlayer = playback_players.get(peer_id)
    if not is_instance_valid(player):
        player = AudioStreamPlayer.new()
        player.name = "VoicePeer_%d" % peer_id
        var stream := AudioStreamGenerator.new()
        stream.mix_rate = VOICE_SAMPLE_RATE
        stream.buffer_length = 0.35
        player.stream = stream
        add_child(player)
        player.play()
        playback_players[peer_id] = player
    return player.get_stream_playback() as AudioStreamGeneratorPlayback

func _on_peer_disconnected(peer_id: int) -> void:
    muted_peers.erase(peer_id)
    last_sequence_by_peer.erase(peer_id)
    rate_window_by_peer.erase(peer_id)
    var player: AudioStreamPlayer = playback_players.get(peer_id)
    if is_instance_valid(player):
        player.stop()
        player.queue_free()
    playback_players.erase(peer_id)

func _set_status(message: String) -> void:
    last_status = message
    status_changed.emit(message)
