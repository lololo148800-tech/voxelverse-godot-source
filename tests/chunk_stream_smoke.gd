extends Node

var world: Node
var initial_center: Vector2i
var old_save_text: String = ""
var had_old_save: bool = false

func _ready() -> void:
    world = get_node_or_null("VoxelWorld")
    if world == null:
        print("CHUNK_SMOKE_FAIL missing_world")
        get_tree().quit(1)
        return
    var expected_chunks: int = ceili(float(world.WORLD_SIZE_X) / float(world.CHUNK_SIZE)) * ceili(float(world.WORLD_SIZE_Z) / float(world.CHUNK_SIZE))
    if world.chunk_storage.size() != expected_chunks or world.loaded_chunk_keys.is_empty() or world.loaded_chunk_keys.size() > world.MAX_STREAM_CHUNKS:
        print("CHUNK_SMOKE_FAIL initial_storage chunks=%d expected=%d loaded=%d" % [world.chunk_storage.size(), expected_chunks, world.loaded_chunk_keys.size()])
        get_tree().quit(1)
        return
    initial_center = world.stream_center
    var serialized: Array = world._serialize_chunk_storage()
    if serialized.size() != expected_chunks:
        print("CHUNK_SMOKE_FAIL serialization=%d expected=%d" % [serialized.size(), expected_chunks])
        get_tree().quit(1)
        return
    var save_path := "user://voxelverse_slot_1.json"
    had_old_save = FileAccess.file_exists(save_path)
    if had_old_save:
        var old_file := FileAccess.open(save_path, FileAccess.READ)
        old_save_text = old_file.get_as_text() if old_file != null else ""
        if old_file != null:
            old_file.close()
    world._save_world()
    var saved_file := FileAccess.open(save_path, FileAccess.READ)
    var saved_variant: Variant = JSON.parse_string(saved_file.get_as_text()) if saved_file != null else null
    if saved_file != null:
        saved_file.close()
    if not (saved_variant is Dictionary) or int(saved_variant.get("version", 0)) != 6 or not (saved_variant.get("chunks", []) is Array):
        print("CHUNK_SMOKE_FAIL save_schema")
        _restore_save(save_path)
        get_tree().quit(1)
        return
    world.player.position = Vector3(30.0, 8.0, 30.0)
    get_tree().create_timer(0.8).timeout.connect(_finish)

func _finish() -> void:
    var moved: bool = world.stream_center != initial_center
    var bounded: bool = world.loaded_chunk_keys.size() > 0 and world.loaded_chunk_keys.size() <= world.MAX_STREAM_CHUNKS
    _restore_save("user://voxelverse_slot_1.json")
    if not moved or not bounded:
        print("CHUNK_SMOKE_FAIL movement moved=%s loaded=%d" % [moved, world.loaded_chunk_keys.size()])
        get_tree().quit(1)
        return
    print("CHUNK_SMOKE_PASS stored=%d loaded=%d" % [world.chunk_storage.size(), world.loaded_chunk_keys.size()])
    get_tree().quit(0)

func _restore_save(path: String) -> void:
    if had_old_save:
        var restore := FileAccess.open(path, FileAccess.WRITE)
        if restore != null:
            restore.store_string(old_save_text)
            restore.close()
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
