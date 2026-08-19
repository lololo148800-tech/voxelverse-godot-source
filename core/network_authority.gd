extends Node

const MAX_SNAPSHOT_BLOCKS: int = 65536
const MAX_COORDINATE_DISTANCE: float = 128.0
const STATE_INTERVAL: float = 0.2
const ENTITY_INTERVAL: float = 0.25

var world: Node
var remote_players: Dictionary = {}
var remote_entities: Dictionary = {}
var peer_states: Dictionary = {}
var state_tick: float = 0.0
var state_sent_count: int = 0
var state_received_count: int = 0
var player_state_contract_seen: bool = false
var inventory_state_contract_seen: bool = false
var entity_tick: float = 0.0
var entity_snapshot_sequence: int = 0
var pending_entity_parts: Dictionary = {}
var bound: bool = false
var snapshot_requested: bool = false
var snapshot_request_scheduled: bool = false

func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)

func bind_world(world_node: Node) -> void:
    world = world_node
    bound = true
    snapshot_requested = false
    snapshot_request_scheduled = false
    _request_snapshot_if_connected()

func is_client_mode() -> bool:
    return NetworkSession.is_online() and not multiplayer.is_server()

func is_server_mode() -> bool:
    return NetworkSession.is_online() and multiplayer.is_server()

func _on_connected_to_server() -> void:
    if not is_client_mode() or snapshot_requested or snapshot_request_scheduled:
        return
    snapshot_request_scheduled = true
    get_tree().create_timer(0.25).timeout.connect(_on_snapshot_timer)

func _on_snapshot_timer() -> void:
    snapshot_request_scheduled = false
    _request_snapshot_if_connected()

func _request_snapshot_if_connected() -> void:
    if snapshot_requested or not bound or not is_client_mode():
        return
    if multiplayer.multiplayer_peer == null:
        return
    if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
        return
    snapshot_requested = true
    rpc_id(1, "request_world_snapshot")

func send_block_edit_request(cell: Vector3i, new_block: int, expected_old: int, source_item: int = -1) -> void:
    if not is_client_mode():
        return
    rpc_id(1, "request_block_edit", cell, new_block, expected_old, source_item)

func send_entity_attack(entity_id: String, damage: float = 4.0) -> void:
    if not is_client_mode() or entity_id.is_empty():
        return
    rpc_id(1, "request_entity_attack", entity_id, clampf(damage, 1.0, 8.0))

func _process(delta: float) -> void:
    if not bound or not NetworkSession.is_online():
        return
    if is_client_mode():
        if not is_instance_valid(world) or not is_instance_valid(world.player):
            return
        if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
            return
        state_tick += delta
        if state_tick >= STATE_INTERVAL:
            state_tick = 0.0
            state_sent_count += 1
            rpc_id(1, "submit_player_state", world.call("_network_build_player_state"))
        return
    if not multiplayer.is_server():
        return
    entity_tick += delta
    if entity_tick < ENTITY_INTERVAL:
        return
    entity_tick = 0.0
    if is_instance_valid(world):
        var entity_snapshot: Array = world.call("_network_build_entity_snapshot")
        var world_state: Dictionary = world.call("_network_build_world_state")
        for peer_id in multiplayer.get_peers():
            _send_entity_snapshot_to_peer(peer_id, entity_snapshot)
            rpc_id(peer_id, "receive_world_state", world_state)

@rpc("any_peer", "reliable")
func request_world_snapshot() -> void:
    if not multiplayer.is_server() or not bound:
        return
    var sender := multiplayer.get_remote_sender_id()
    rpc_id(sender, "receive_world_snapshot", world.call("_network_build_snapshot"))
    _send_entity_snapshot_to_peer(sender, world.call("_network_build_entity_snapshot"))
    rpc_id(sender, "receive_world_state", world.call("_network_build_world_state"))

@rpc("any_peer", "reliable")
func request_block_edit(cell: Vector3i, new_block: int, expected_old: int, source_item: int = -1) -> void:
    if not multiplayer.is_server() or not bound:
        return
    var sender := multiplayer.get_remote_sender_id()
    var state: Dictionary = peer_states.get(sender, {})
    var peer_inventory: Dictionary = state.get("inventory", {})
    if world.call("_network_apply_block_edit", cell, new_block, expected_old, sender, source_item, peer_inventory):
        if new_block != world.AIR:
            var updated_count := int(peer_inventory.get(source_item, 0)) - 1
            peer_inventory[source_item] = maxi(0, updated_count)
            state["inventory"] = peer_inventory
            peer_states[sender] = state
            rpc_id(sender, "receive_inventory_state", peer_inventory)
        for peer_id in multiplayer.get_peers():
            rpc_id(peer_id, "receive_block_edit", cell, new_block)

@rpc("authority", "reliable")
func receive_world_snapshot(snapshot: Dictionary) -> void:
    if not bound:
        return
    world.call("_network_apply_snapshot", snapshot)

@rpc("authority", "reliable")
func receive_block_edit(cell: Vector3i, new_block: int) -> void:
    if not bound:
        return
    world.call("_network_receive_block_edit", cell, new_block)

@rpc("any_peer", "reliable")
func request_entity_attack(entity_id: String, damage: float) -> void:
    if not multiplayer.is_server() or not bound:
        return
    var sender := multiplayer.get_remote_sender_id()
    var state: Dictionary = peer_states.get(sender, {})
    var attacker_position: Vector3 = state.get("position", Vector3.ZERO)
    var result: Dictionary = world.call("_network_apply_player_attack", entity_id, clampf(damage, 1.0, 8.0), attacker_position)
    if result.is_empty():
        return
    var health := float(result.get("health", 0.0))
    for peer_id in multiplayer.get_peers():
        rpc_id(peer_id, "receive_entity_damage", entity_id, health)

@rpc("authority", "reliable")
func receive_entity_damage(entity_id: String, health: float) -> void:
    var entity: Node3D = remote_entities.get(entity_id)
    if is_instance_valid(entity):
        entity.set_meta("health", health)

@rpc("authority", "reliable")
func receive_inventory_state(inventory_state: Dictionary) -> void:
    if not bound:
        return
    world.call("_network_apply_inventory_state", inventory_state)

@rpc("any_peer", "reliable")
func submit_player_state(state: Dictionary) -> void:
    if not multiplayer.is_server() or not bound:
        return
    var sender := multiplayer.get_remote_sender_id()
    state_received_count += 1
    player_state_contract_seen = true
    var incoming_position: Vector3 = state.get("position", Vector3.ZERO)
    var peer_state: Dictionary = peer_states.get(sender, {})
    var last_position: Vector3 = peer_state.get("position", incoming_position)
    var position_initialized: bool = bool(peer_state.get("position_initialized", false))
    if position_initialized and incoming_position.distance_to(last_position) > MAX_COORDINATE_DISTANCE:
        return
    state["position"] = incoming_position
    peer_state["position"] = incoming_position
    peer_state["position_initialized"] = true
    if not bool(peer_state.get("inventory_initialized", false)):
        var initial_inventory: Variant = state.get("inventory", {})
        if initial_inventory is Dictionary:
            peer_state["inventory"] = _sanitize_inventory(initial_inventory)
            inventory_state_contract_seen = true
        peer_state["inventory_initialized"] = true
    peer_states[sender] = peer_state
    for peer_id in multiplayer.get_peers():
        if peer_id != sender:
            rpc_id(peer_id, "receive_player_state", sender, state)

@rpc("authority", "unreliable")
func receive_player_state(peer_id: int, state: Dictionary) -> void:
    if not bound:
        return
    var position: Vector3 = state.get("position", Vector3.ZERO)
    _update_remote_player(peer_id, position, state)

@rpc("authority", "unreliable")
func receive_world_state(state: Dictionary) -> void:
    if not bound:
        return
    world.call("_network_apply_world_state", state)

func _send_entity_snapshot_to_peer(peer_id: int, snapshot: Array) -> void:
    entity_snapshot_sequence += 1
    var part_size := 4
    var part_count := maxi(1, ceili(float(snapshot.size()) / part_size))
    for part_index in range(part_count):
        var part: Array = []
        var start := part_index * part_size
        var finish := mini(snapshot.size(), start + part_size)
        for index in range(start, finish):
            part.append(snapshot[index])
        rpc_id(peer_id, "receive_entity_snapshot_part", part, entity_snapshot_sequence, part_index, part_count)

@rpc("authority", "reliable")
func receive_entity_snapshot_part(part: Array, sequence: int, part_index: int, part_count: int) -> void:
    if not bound or part_count <= 0 or part_index < 0 or part_index >= part_count:
        return
    if not pending_entity_parts.has(sequence):
        pending_entity_parts[sequence] = {"total": part_count, "parts": {}}
    var packet: Dictionary = pending_entity_parts[sequence]
    var packet_parts: Dictionary = packet["parts"]
    packet_parts[part_index] = part
    if packet_parts.size() < int(packet["total"]):
        return
    var combined: Array = []
    for index in range(int(packet["total"])):
        var records: Array = packet_parts.get(index, [])
        combined.append_array(records)
    pending_entity_parts.erase(sequence)
    _apply_entity_snapshot(combined)

@rpc("authority", "reliable")
func receive_entity_snapshot(snapshot: Array) -> void:
    if not bound:
        return
    _apply_entity_snapshot(snapshot)

func _apply_entity_snapshot(snapshot: Array) -> void:
    var seen: Dictionary = {}
    for record_variant in snapshot:
        if not (record_variant is Dictionary):
            continue
        var record: Dictionary = record_variant
        var entity_id := str(record.get("id", ""))
        if entity_id.is_empty():
            continue
        seen[entity_id] = true
        var entity := _get_or_create_remote_entity(entity_id, str(record.get("kind", "Entity")))
        entity.position = record.get("position", Vector3.ZERO)
        entity.set_meta("health", float(record.get("health", 0.0)))
        entity.set_meta("max_health", float(record.get("max_health", 0.0)))
    for old_id_variant in remote_entities.keys():
        var old_id: String = str(old_id_variant)
        if not seen.has(old_id):
            var old_entity: Node3D = remote_entities[old_id]
            if is_instance_valid(old_entity):
                old_entity.queue_free()
            remote_entities.erase(old_id)

func _sanitize_inventory(inventory_state: Dictionary) -> Dictionary:
    var clean: Dictionary = {}
    for item_variant in inventory_state.keys():
        var item_id := int(item_variant)
        if item_id >= 0 and item_id <= 128:
            clean[item_id] = clampi(int(inventory_state[item_variant]), 0, 9999)
    return clean

func _on_peer_connected(peer_id: int) -> void:
    if not bound or not multiplayer.is_server():
        return
    peer_states[peer_id] = {"inventory": {}, "inventory_initialized": false, "position_initialized": false}
    get_tree().create_timer(0.25).timeout.connect(_send_snapshot_to_peer.bind(peer_id))

func _send_snapshot_to_peer(peer_id: int) -> void:
    if not bound or not multiplayer.is_server():
        return
    if not multiplayer.get_peers().has(peer_id):
        return
    rpc_id(peer_id, "receive_world_snapshot", world.call("_network_build_snapshot"))
    _send_entity_snapshot_to_peer(peer_id, world.call("_network_build_entity_snapshot"))
    rpc_id(peer_id, "receive_world_state", world.call("_network_build_world_state"))

func _on_peer_disconnected(peer_id: int) -> void:
    var avatar: Node3D = remote_players.get(peer_id)
    if is_instance_valid(avatar):
        avatar.queue_free()
    remote_players.erase(peer_id)
    peer_states.erase(peer_id)

func _update_remote_player(peer_id: int, position: Vector3, state: Dictionary = {}) -> void:
    var avatar: Node3D = remote_players.get(peer_id)
    if not is_instance_valid(avatar):
        avatar = _create_remote_avatar(peer_id)
        remote_players[peer_id] = avatar
    avatar.position = position
    avatar.set_meta("health", float(state.get("health", avatar.get_meta("health", 20.0))))
    avatar.set_meta("hunger", float(state.get("hunger", avatar.get_meta("hunger", 20.0))))
    avatar.set_meta("thirst", float(state.get("thirst", avatar.get_meta("thirst", 20.0))))

func _create_remote_avatar(peer_id: int) -> Node3D:
    var avatar := Node3D.new()
    avatar.name = "RemotePeer_%d" % peer_id
    var mesh := MeshInstance3D.new()
    var cube := BoxMesh.new()
    cube.size = Vector3(0.72, 1.7, 0.72)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("4fc5bd")
    material.roughness = 0.72
    cube.material = material
    mesh.mesh = cube
    mesh.position.y = 0.85
    avatar.add_child(mesh)
    if is_instance_valid(world):
        world.add_child(avatar)
    return avatar

func _get_or_create_remote_entity(entity_id: String, kind: String) -> Node3D:
    var entity: Node3D = remote_entities.get(entity_id)
    if is_instance_valid(entity):
        return entity
    entity = Node3D.new()
    entity.name = "RemoteEntity_%s" % entity_id.replace(":", "_")
    var mesh := MeshInstance3D.new()
    var cube := BoxMesh.new()
    cube.size = Vector3(0.9, 1.1, 0.9)
    var material := StandardMaterial3D.new()
    material.albedo_color = _entity_color(kind)
    material.roughness = 0.8
    cube.material = material
    mesh.mesh = cube
    mesh.position.y = 0.55
    entity.add_child(mesh)
    if is_instance_valid(world):
        world.add_child(entity)
    remote_entities[entity_id] = entity
    return entity

func _entity_color(kind: String) -> Color:
    if kind == "Echo Warden":
        return Color("d878d6")
    if kind == "StarSpirit":
        return Color("f2d57b")
    if kind == "VoidSerpent":
        return Color("2a163d")
    if kind == "GuardianDrone":
        return Color("8fabc7")
    return Color("b85f7a")
