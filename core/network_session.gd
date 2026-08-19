extends Node

signal status_changed(message: String)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal discovery_updated(servers: Array)
signal friend_code_changed(code: String)

const DEFAULT_PORT: int = 24560
const DISCOVERY_PORT: int = 24561
const MAX_CLIENTS: int = 16
const DISCOVERY_INTERVAL: float = 1.5
const PROTOCOL_NAME := "ashen_frontier_lan_v1"

var mode: String = "offline"
var address: String = ""
var port: int = DEFAULT_PORT
var server_name: String = "Ashen Frontier host"
var friend_code: String = ""
var last_status: String = "Offline singleplayer"
var discovery_enabled: bool = false
var discovery_peer: PacketPeerUDP
var discovery_tick: float = 0.0
var discovered_servers: Dictionary = {}
var dedicated_config: Dictionary = {}

func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(delta: float) -> void:
    if discovery_enabled:
        _poll_discovery_packets()
        discovery_tick += delta
        if discovery_tick >= DISCOVERY_INTERVAL:
            discovery_tick = 0.0
            _broadcast_lan_presence()

func host_game(host_port: int = DEFAULT_PORT, requested_name: String = "Ashen Frontier host") -> bool:
    var peer := ENetMultiplayerPeer.new()
    var error := peer.create_server(host_port, MAX_CLIENTS)
    if error != OK:
        _set_status("Не удалось открыть сервер: %s" % error)
        return false
    multiplayer.multiplayer_peer = peer
    mode = "host"
    port = clampi(host_port, 1024, 65535)
    address = "0.0.0.0"
    server_name = requested_name.strip_edges() if not requested_name.strip_edges().is_empty() else "Ashen Frontier host"
    friend_code = _make_friend_code(server_name, port)
    friend_code_changed.emit(friend_code)
    _set_status("Сервер друзей запущен: %s · код %s" % [server_name, friend_code])
    if discovery_enabled:
        _broadcast_lan_presence()
    return true

func join_game(server_address: String, server_port: int = DEFAULT_PORT) -> bool:
    if server_address.strip_edges().is_empty():
        _set_status("Нужен адрес сервера или LAN-хоста")
        return false
    var peer := ENetMultiplayerPeer.new()
    var error := peer.create_client(server_address.strip_edges(), clampi(server_port, 1024, 65535))
    if error != OK:
        _set_status("Не удалось начать подключение: %s" % error)
        return false
    multiplayer.multiplayer_peer = peer
    mode = "client"
    address = server_address.strip_edges()
    port = clampi(server_port, 1024, 65535)
    _set_status("Подключение к %s:%d" % [address, port])
    return true

func join_by_friend_code(code: String) -> bool:
    var normalized := code.strip_edges().to_upper()
    for record_variant in discovered_servers.values():
        var record: Dictionary = record_variant
        if str(record.get("friend_code", "")).to_upper() == normalized:
            return join_game(str(record.get("address", "127.0.0.1")), int(record.get("port", DEFAULT_PORT)))
    _set_status("Код не найден в текущей LAN-сети: %s" % normalized)
    return false

func start_lan_discovery() -> bool:
    if discovery_peer == null:
        discovery_peer = PacketPeerUDP.new()
        var error := discovery_peer.bind(DISCOVERY_PORT)
        if error != OK:
            discovery_peer = null
            _set_status("LAN discovery недоступен на порту %d" % DISCOVERY_PORT)
            return false
        discovery_peer.set_broadcast_enabled(true)
    discovery_enabled = true
    discovery_tick = DISCOVERY_INTERVAL
    _set_status("LAN discovery включён; ищу серверы в локальной сети")
    return true

func stop_lan_discovery() -> void:
    discovery_enabled = false
    discovered_servers.clear()
    discovery_updated.emit([])
    if discovery_peer != null:
        discovery_peer.close()
        discovery_peer = null

func get_discovered_servers() -> Array:
    return discovered_servers.values()

func load_dedicated_config(path: String = "res://data/dedicated_server.json") -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        dedicated_config = {}
        return dedicated_config
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    dedicated_config = parsed if parsed is Dictionary else {}
    return dedicated_config

func host_from_dedicated_config(path: String = "res://data/dedicated_server.json") -> bool:
    var config := load_dedicated_config(path)
    var configured_port := clampi(int(config.get("port", DEFAULT_PORT)), 1024, 65535)
    var configured_name := str(config.get("server_name", "Ashen Frontier dedicated"))
    return host_game(configured_port, configured_name)

func is_online() -> bool:
    return mode != "offline" and multiplayer.multiplayer_peer != null

func is_host() -> bool:
    return mode == "host"

func is_client() -> bool:
    return mode == "client"

func stop_online() -> void:
    if multiplayer.multiplayer_peer != null:
        multiplayer.multiplayer_peer.close()
    multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
    mode = "offline"
    address = ""
    port = DEFAULT_PORT
    friend_code = ""
    friend_code_changed.emit(friend_code)
    _set_status("Offline singleplayer")

func _make_friend_code(name_value: String, port_value: int) -> String:
    var fingerprint := (name_value + "|" + str(port_value) + "|" + OS.get_unique_id()).md5_text().to_upper()
    return "AF-%s-%s" % [fingerprint.substr(0, 3), fingerprint.substr(3, 3)]

func _broadcast_lan_presence() -> void:
    if not discovery_enabled or discovery_peer == null or mode != "host":
        return
    var payload := {"protocol": PROTOCOL_NAME, "server_name": server_name, "friend_code": friend_code, "port": port, "players": multiplayer.get_peers().size() + 1, "max_players": MAX_CLIENTS}
    var packet := JSON.stringify(payload).to_utf8_buffer()
    discovery_peer.set_dest_address("255.255.255.255", DISCOVERY_PORT)
    discovery_peer.put_packet(packet)

func _poll_discovery_packets() -> void:
    if discovery_peer == null:
        return
    var changed := false
    while discovery_peer.get_available_packet_count() > 0:
        var packet := discovery_peer.get_packet()
        var parsed: Variant = JSON.parse_string(packet.get_string_from_utf8())
        if not (parsed is Dictionary) or str(parsed.get("protocol", "")) != PROTOCOL_NAME:
            continue
        var source_address := discovery_peer.get_packet_ip()
        var source_port := int(parsed.get("port", DEFAULT_PORT))
        var key := "%s:%d" % [source_address, source_port]
        parsed["address"] = source_address
        parsed["last_seen"] = Time.get_ticks_msec()
        if not discovered_servers.has(key) or discovered_servers[key] != parsed:
            discovered_servers[key] = parsed
            changed = true
    if changed:
        discovery_updated.emit(get_discovered_servers())

func _set_status(message: String) -> void:
    last_status = message
    status_changed.emit(message)

func _on_peer_connected(peer_id: int) -> void:
    peer_joined.emit(peer_id)
    _set_status("Игрок подключён: %d" % peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
    peer_left.emit(peer_id)
    _set_status("Игрок отключён: %d" % peer_id)

func _on_connected_to_server() -> void:
    _set_status("Подключено к серверу друзей")

func _on_connection_failed() -> void:
    mode = "offline"
    _set_status("Подключение не удалось; игра остаётся offline")

func _on_server_disconnected() -> void:
    mode = "offline"
    _set_status("Сервер отключён; игра возвращена в offline")
