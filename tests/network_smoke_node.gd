extends Node

const TEST_PORT: int = 24631
var role: String = ""
var network_session: Node

func _ready() -> void:
    network_session = get_node_or_null("/root/NetworkSession")
    if network_session == null:
        print("NETWORK_SMOKE_FAIL missing_session_autoload")
        get_tree().quit(1)
        return
    var args := OS.get_cmdline_user_args()
    role = str(args[0]).to_lower() if not args.is_empty() else "host"
    if role == "host":
        if not network_session.host_game(TEST_PORT):
            print("NETWORK_SMOKE_FAIL host_create")
            get_tree().quit(1)
            return
        print("NETWORK_SMOKE_HOST_READY")
        get_tree().create_timer(5.0).timeout.connect(_finish_host)
    elif role == "client":
        network_session.status_changed.connect(_on_status)
        if not network_session.join_game("127.0.0.1", TEST_PORT):
            print("NETWORK_SMOKE_FAIL client_create")
            get_tree().quit(1)
            return
        print("NETWORK_SMOKE_CLIENT_CONNECTING")
    else:
        print("NETWORK_SMOKE_FAIL unknown_role")
        get_tree().quit(1)

func _on_status(message: String) -> void:
    if message.begins_with("Подключено"):
        print("NETWORK_SMOKE_CLIENT_CONNECTED")
        get_tree().create_timer(0.6).timeout.connect(_finish_client)

func _finish_client() -> void:
    network_session.stop_online()
    get_tree().quit(0)

func _finish_host() -> void:
    network_session.stop_online()
    print("NETWORK_SMOKE_HOST_DONE")
    get_tree().quit(0)
