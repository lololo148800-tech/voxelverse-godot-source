extends Node

func _ready() -> void:
    if VoiceChat == null:
        print("VOICE_SMOKE_FAIL missing_autoload")
        get_tree().quit(1)
        return
    if VoiceChat.enabled:
        print("VOICE_SMOKE_FAIL not_disabled_by_default")
        get_tree().quit(1)
        return
    VoiceChat.status_changed.connect(_on_voice_status)
    VoiceChat.set_push_to_talk(true)
    VoiceChat.set_enabled(true)
    print("VOICE_SMOKE_ENABLED_STATE=%s authorized=%s" % [VoiceChat.enabled, VoiceChat.voice_authorized])
    var audio := PackedByteArray([0, 0])
    var payload := {"token": VoiceChat.voice_session_token, "sequence": 1, "audio": audio}
    var accepted := VoiceChat._validate_payload(payload, VoiceChat.voice_session_token, 77, false)
    var duplicate_rejected := not VoiceChat._validate_payload(payload, VoiceChat.voice_session_token, 77, false)
    var oversized := PackedByteArray()
    oversized.resize(VoiceChat.MAX_PACKET_BYTES + 2)
    var oversized_rejected := not VoiceChat._validate_payload({"token": VoiceChat.voice_session_token, "sequence": 2, "audio": oversized}, VoiceChat.voice_session_token, 77, false)
    VoiceChat.set_peer_muted(77, true)
    var mute_ok := VoiceChat.is_peer_muted(77)
    if not accepted or not duplicate_rejected or not oversized_rejected or not mute_ok:
        print("VOICE_SMOKE_FAIL validation accepted=%s duplicate=%s oversized=%s mute=%s" % [accepted, duplicate_rejected, oversized_rejected, mute_ok])
        VoiceChat.set_enabled(false)
        get_tree().quit(1)
        return
    get_tree().create_timer(0.6).timeout.connect(_finish)

func _on_voice_status(message: String) -> void:
    print("VOICE_SMOKE_STATUS=%s" % message)

func _finish() -> void:
    VoiceChat.set_enabled(false)
    VoiceChat._on_peer_disconnected(77)
    var clean := not VoiceChat.enabled and not VoiceChat.speaking and VoiceChat.playback_players.is_empty()
    print("VOICE_SMOKE_PASS disabled=%s clean=%s" % [not VoiceChat.enabled, clean])
    get_tree().quit(0 if clean else 1)
