extends SceneTree

const TEST_PORT: int = 24631
var role: String = ""
var network_session: Node

func _initialize() -> void:
    network_session = get_root().get_node_or_null("NetworkSession")
    if network_session == null:
        print("NETWORK_SMOKE_FAIL missing_session_autoload")
        quit(1)
        return
    var args := OS.get_cmdline_user_args()
    role = str(args[0]).to_lower() if not args.is_empty() else "host"
    if role == "host":
        if not network_session.host_game(TEST_PORT):
            print("NETWORK_SMOKE_FAIL host_create")
            quit(1)
            return
        print("NETWORK_SMOKE_HOST_READY")
        create_timer(5.0).timeout.connect(_finish_host)
    elif role == "client":
        network_session.connected_to_server.connect(_client_connected)
        network_session.connection_failed.connect(_client_failed)
        if not network_session.join_game("127.0.0.1", TEST_PORT):
            print("NETWORK_SMOKE_FAIL client_create")
            quit(1)
            return
        print("NETWORK_SMOKE_CLIENT_CONNECTING")
    else:
        print("NETWORK_SMOKE_FAIL unknown_role")
        quit(1)

func _client_connected() -> void:
    print("NETWORK_SMOKE_CLIENT_CONNECTED")
    create_timer(0.6).timeout.connect(_finish_client)

func _client_failed() -> void:
    print("NETWORK_SMOKE_FAIL client_connection")
    quit(1)

func _finish_client() -> void:
    network_session.stop_online()
    quit(0)

func _finish_host() -> void:
    network_session.stop_online()
    print("NETWORK_SMOKE_HOST_DONE")
    quit(0)
