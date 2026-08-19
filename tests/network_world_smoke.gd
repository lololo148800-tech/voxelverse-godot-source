extends Node

const TEST_PORT: int = 24632
var role: String = ""
var network_session: Node
var world: Node
var waited: float = 0.0
var snapshot_seen: bool = false
var entity_seen: bool = false

func _ready() -> void:
    network_session = get_node_or_null("/root/NetworkSession")
    world = get_node_or_null("VoxelWorld")
    if network_session == null or world == null:
        print("WORLD_NETWORK_SMOKE_FAIL missing_nodes")
        get_tree().quit(1)
        return
    var args := OS.get_cmdline_user_args()
    role = str(args[0]).to_lower() if not args.is_empty() else "host"
    if role == "host":
        if not network_session.host_game(TEST_PORT):
            print("WORLD_NETWORK_SMOKE_FAIL host_create")
            get_tree().quit(1)
            return
        print("WORLD_NETWORK_SMOKE_HOST_READY")
        get_tree().create_timer(6.0).timeout.connect(_finish_host)
    elif role == "client":
        network_session.status_changed.connect(_on_status)
        if not network_session.join_game("127.0.0.1", TEST_PORT):
            print("WORLD_NETWORK_SMOKE_FAIL client_create")
            get_tree().quit(1)
            return
        print("WORLD_NETWORK_SMOKE_CLIENT_CONNECTING")
    else:
        print("WORLD_NETWORK_SMOKE_FAIL unknown_role")
        get_tree().quit(1)

func _process(delta: float) -> void:
    if role != "client" or snapshot_seen:
        return
    waited += delta
    if NetworkAuthority.remote_entities.size() > 0:
        entity_seen = true
    if str(world.generated_message).contains("Получен снимок мира"):
        snapshot_seen = true
        print("WORLD_NETWORK_SMOKE_SNAPSHOT_RECEIVED")
    if snapshot_seen and entity_seen and world.network_world_state_received:
        print("WORLD_NETWORK_SMOKE_STATE_RECEIVED entities=%d" % NetworkAuthority.remote_entities.size())
        get_tree().create_timer(0.5).timeout.connect(_finish_client)
    elif waited > 7.0:
        print("WORLD_NETWORK_SMOKE_FAIL state_timeout snapshot=%s entities=%s world_state=%s" % [snapshot_seen, entity_seen, world.network_world_state_received])
        get_tree().quit(1)

func _on_status(message: String) -> void:
    if message.begins_with("Подключено"):
        print("WORLD_NETWORK_SMOKE_CLIENT_CONNECTED")

func _finish_client() -> void:
    print("WORLD_NETWORK_SMOKE_CLIENT_DONE state_sent=%d" % NetworkAuthority.state_sent_count)
    network_session.stop_online()
    get_tree().quit(0)

func _finish_host() -> void:
    var state_seen: bool = NetworkAuthority.player_state_contract_seen
    var inventory_seen: bool = NetworkAuthority.inventory_state_contract_seen
    if not state_seen or not inventory_seen:
        print("WORLD_NETWORK_SMOKE_FAIL player_state=%s inventory=%s received=%d" % [state_seen, inventory_seen, NetworkAuthority.state_received_count])
        network_session.stop_online()
        get_tree().quit(1)
        return
    network_session.stop_online()
    print("WORLD_NETWORK_SMOKE_HOST_DONE player_state=true inventory=true received=%d" % NetworkAuthority.state_received_count)
    get_tree().quit(0)
