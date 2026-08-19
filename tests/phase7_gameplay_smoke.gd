extends Node

var world: Node

func _ready() -> void:
    world = get_node_or_null("VoxelWorld")
    if world == null:
        print("PHASE7_SMOKE_FAIL missing_world")
        _finish(1)
        return
    var new_ids := [world.WATER, world.ASH_FLUID, world.ARCANE_CRYSTAL, world.ARCANE_CONDUIT, world.AUTOMATION_FORGE, world.CARGO_RAIL]
    for item_id in new_ids:
        if not world.inventory_item_ids.has(item_id) or world._block_name(item_id) == "Воздух" or world._name_for_block(item_id) == "Предмет" or not world._is_placeable_block(item_id):
            print("PHASE7_SMOKE_FAIL registry id=%d" % item_id)
            _finish(1)
            return
    if world.spell_definitions.size() < 6 or world.recipes.size() < 26:
        print("PHASE7_SMOKE_FAIL data spells=%d recipes=%d" % [world.spell_definitions.size(), world.recipes.size()])
        _finish(1)
        return
    if not is_instance_valid(world.player):
        print("PHASE7_SMOKE_FAIL missing_player")
        _finish(1)
        return

    var original_mana: float = world.player.mana
    world.player.dead = false
    world.player.health = 10.0
    world.player.mana = world.player.MAX_MANA
    world.player.spell_cooldown = 0.0
    world.inventory[world.ECHO_SHARD] = 1
    var spell_ok: bool = world._cast_spell("mending_surge") and world.player.health > 10.0 and world.player.mana < world.player.MAX_MANA and int(world.inventory.get(world.ECHO_SHARD, 0)) == 0 and world.active_spell_effects.has("mending_surge")
    if not spell_ok:
        print("PHASE7_SMOKE_FAIL spell mana_before=%d mana_after=%d" % [int(original_mana), int(world.player.mana)])
        _finish(1)
        return

    world.inventory[world.ASTRAL_CRYSTAL] = 1
    world.player.mana = world.player.MAX_MANA
    world.player.spell_cooldown = 0.0
    world.player.barrier_points = 0.0
    var ward_ok: bool = world._cast_spell("frost_ward") and is_equal_approx(world.player.barrier_points, 8.0)
    world.player.spawn_protection_timer = 0.0
    world.player.health = world.player.MAX_HEALTH
    world.player.set_armor(true, 20)
    world.player.take_damage(6.0, "Phase7 barrier")
    var barrier_absorbs: bool = is_equal_approx(world.player.health, world.player.MAX_HEALTH) and is_equal_approx(world.player.barrier_points, 2.0) and world.player.armor_durability == 20
    world.player.mana = 0.0
    world.player.spell_cooldown = 0.0
    world.inventory[world.ASTRAL_CRYSTAL] = 1
    var refund_ok: bool = not world._cast_spell("frost_ward") and int(world.inventory.get(world.ASTRAL_CRYSTAL, 0)) == 1
    if not ward_ok or not barrier_absorbs or not refund_ok:
        print("PHASE7_SMOKE_FAIL barrier ward=%s absorbs=%s refund=%s points=%.1f health=%.1f armor=%d" % [ward_ok, barrier_absorbs, refund_ok, world.player.barrier_points, world.player.health, world.player.armor_durability])
        _finish(1)
        return

    var fluid_cells: Array[Vector3i] = []
    for fluid_cell_variant in world.blocks.keys():
        var fluid_cell: Vector3i = fluid_cell_variant
        var fluid_type := int(world.blocks[fluid_cell])
        if fluid_type == world.WATER or fluid_type == world.ASH_FLUID:
            fluid_cells.append(fluid_cell)
    for fluid_cell in fluid_cells:
        world._set_runtime_block(fluid_cell, world.AIR)
    var active_origin := Vector3i(floori(world.player.position.x), floori(world.player.position.y), floori(world.player.position.z))
    var fluid_source := active_origin + Vector3i(0, 2, 0)
    var fluid_target := fluid_source + Vector3i.DOWN
    world._set_runtime_block(fluid_target, world.AIR)
    world._set_runtime_block(fluid_source, world.WATER)
    world._update_fluid_simulation(0.4)
    if world._get_stored_block(fluid_target) != world.WATER:
        print("PHASE7_SMOKE_FAIL fluid")
        _finish(1)
        return

    var forge_cell := active_origin + Vector3i(1, -1, 1)
    world._set_runtime_block(forge_cell, world.AUTOMATION_FORGE)
    world.inventory[world.DEEP_CRYSTAL] = 1
    world.inventory[world.STAR_DUST] = 1
    for _step in range(6):
        world._update_automation(0.5)
    if int(world.inventory.get(world.ARCANE_CRYSTAL, 0)) < 1:
        print("PHASE7_SMOKE_FAIL automation")
        _finish(1)
        return

    var stale_transport_cells: Array[Vector3i] = []
    for cell_variant in world.blocks.keys():
        var cell: Vector3i = cell_variant
        var block_id := int(world.blocks[cell])
        if block_id == world.CARGO_RAIL or block_id == world.CHEST:
            stale_transport_cells.append(cell)
    for stale_cell in stale_transport_cells:
        world._set_runtime_block(stale_cell, world.AIR)
    world.transport_path.clear()
    world.transport_progress = 0.0
    world.transport_direction = 1
    world.transport_tick = 0.0
    world.transport_delivery_count = 0
    for transport_item in [world.ASTRAL_METAL, world.ASTRAL_SCRAP, world.STAR_DUST, world.ARCANE_CRYSTAL]:
        world.inventory[transport_item] = 0
        world.storage_inventory[transport_item] = 0
    world.inventory[world.ASTRAL_METAL] = 1
    var rail_a := active_origin + Vector3i(2, -1, 0)
    var rail_b := active_origin + Vector3i(3, -1, 0)
    var cargo_chest := rail_b + Vector3i(0, 0, 1)
    world._set_runtime_block(rail_a, world.CARGO_RAIL)
    world._set_runtime_block(rail_b, world.CARGO_RAIL)
    world._set_runtime_block(cargo_chest, world.CHEST)
    world.inventory[world.ASTRAL_METAL] = 1
    world.storage_inventory[world.ASTRAL_METAL] = 0
    for _step in range(18):
        world._update_transport(0.25)
    var transport_ok: bool = world.transport_delivery_count > 0 and int(world.storage_inventory.get(world.ASTRAL_METAL, 0)) == 1
    if not transport_ok:
        print("PHASE7_SMOKE_FAIL transport deliveries=%d stored=%d" % [world.transport_delivery_count, int(world.storage_inventory.get(world.ASTRAL_METAL, 0))])
        _finish(1)
        return

    print("PHASE7_GAMEPLAY_PASS spells=%d barrier=true reagent_refund=true fluid=true forge=%d rail_deliveries=%d mana_spent=%s" % [world.spell_definitions.size(), int(world.inventory.get(world.ARCANE_CRYSTAL, 0)), world.transport_delivery_count, str(world.player.mana < world.player.MAX_MANA)])
    _finish(0)

func _finish(exit_code: int) -> void:
    await get_tree().physics_frame
    for _frame in range(10):
        await get_tree().process_frame
    get_tree().quit(exit_code)
