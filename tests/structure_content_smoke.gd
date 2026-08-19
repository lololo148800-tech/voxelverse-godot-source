extends Node

var world: Node
var old_save_text: String = ""
var had_old_save: bool = false

func _ready() -> void:
    world = get_node_or_null("VoxelWorld")
    if world == null:
        print("STRUCTURE_SMOKE_FAIL missing_world")
        get_tree().quit(1)
        return
    var furniture_ids := [world.FURNITURE_CRATE, world.FURNITURE_TABLE, world.FURNITURE_LAMP]
    for item_id in furniture_ids:
        if not world.inventory_item_ids.has(item_id) or world._block_name(item_id) == "Воздух" or world._name_for_block(item_id) == "Предмет":
            print("STRUCTURE_SMOKE_FAIL registry id=%d" % item_id)
            get_tree().quit(1)
            return
    var chest_count := 0
    for chunk_variant in world.chunk_storage.values():
        var chunk: Dictionary = chunk_variant
        for cell_variant in chunk.keys():
            var cell: Vector3i = cell_variant
            if int(chunk[cell]) == world.CHEST:
                chest_count += 1
    if chest_count < 3 or world.structure_loot.size() < 3:
        print("STRUCTURE_SMOKE_FAIL chests=%d loot=%d" % [chest_count, world.structure_loot.size()])
        get_tree().quit(1)
        return
    var first_key: String = str(world.structure_loot.keys()[0])
    var loot_before: Dictionary = world.storage_inventory.duplicate()
    var loot_cell := _parse_key(first_key)
    world._claim_structure_loot(loot_cell)
    var claimed_amount := _inventory_total(world.storage_inventory) - _inventory_total(loot_before)
    var after_first: Dictionary = world.storage_inventory.duplicate()
    world._claim_structure_loot(loot_cell)
    var after_second := _inventory_total(world.storage_inventory)
    if claimed_amount <= 0 or after_second != _inventory_total(after_first):
        print("STRUCTURE_SMOKE_FAIL claim first=%d second_delta=%d" % [claimed_amount, after_second - _inventory_total(after_first)])
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
    var saved: Variant = JSON.parse_string(saved_file.get_as_text()) if saved_file != null else null
    if saved_file != null:
        saved_file.close()
    _restore_save(save_path)
    if not (saved is Dictionary) or not (saved.get("claimed_structure_loot", {}) is Dictionary) or not bool(saved["claimed_structure_loot"].get(first_key, false)):
        print("STRUCTURE_SMOKE_FAIL persistence")
        get_tree().quit(1)
        return
    print("STRUCTURE_SMOKE_PASS chests=%d loot=%d claimed=%d" % [chest_count, world.structure_loot.size(), claimed_amount])
    get_tree().quit(0)

func _inventory_total(inv: Dictionary) -> int:
    var total := 0
    for value in inv.values():
        total += int(value)
    return total

func _parse_key(key: String) -> Vector3i:
    var parts := key.split(":")
    return Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))

func _restore_save(path: String) -> void:
    if had_old_save:
        var restore := FileAccess.open(path, FileAccess.WRITE)
        if restore != null:
            restore.store_string(old_save_text)
            restore.close()
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
