extends Node

var world: Node

func _ready() -> void:
    world = get_node_or_null("VoxelWorld")
    if world == null:
        print("PHASE2_CORE_SMOKE_FAIL missing_world")
        _finish(1)
        return
    if world.ore_definitions.size() != 50 or world.ore_raw_definitions.size() != 50 or world.ore_ingot_definitions.size() != 50:
        print("PHASE2_CORE_SMOKE_FAIL ore_maps=%d/%d/%d" % [world.ore_definitions.size(), world.ore_raw_definitions.size(), world.ore_ingot_definitions.size()])
        _finish(1)
        return
    if world.structure_definitions.size() < 8 or world.structure_loot.size() < 11:
        print("PHASE2_CORE_SMOKE_FAIL structures=%d loot=%d" % [world.structure_definitions.size(), world.structure_loot.size()])
        _finish(1)
        return
    if world.external_biome_definitions.size() < 50:
        print("PHASE2_CORE_SMOKE_FAIL biome_definitions=%d" % world.external_biome_definitions.size())
        _finish(1)
        return
    for biome_definition_variant in world.external_biome_definitions.values():
        var biome_definition: Dictionary = biome_definition_variant
        if not biome_definition.has("hazard") or not biome_definition.has("temperature") or not biome_definition.has("terrain_lift") or not biome_definition.has("rarity"):
            print("PHASE2_CORE_SMOKE_FAIL biome_fields")
            _finish(1)
            return
    if world.MAX_BLOCK_ID != 105 or world.MAX_CONTENT_ID != 355:
        print("PHASE2_CORE_SMOKE_FAIL bounds=%d/%d" % [world.MAX_BLOCK_ID, world.MAX_CONTENT_ID])
        _finish(1)
        return
    world._generate_world()
    var sampled_biomes: Dictionary = {}
    for sample_x in range(0, world.WORLD_SIZE_X, 2):
        for sample_z in range(0, world.WORLD_SIZE_Z, 2):
            sampled_biomes[world._biome_for(sample_x, sample_z)] = true
    if sampled_biomes.size() < 20:
        print("PHASE2_CORE_SMOKE_FAIL sampled_biomes=%d" % sampled_biomes.size())
        _finish(1)
        return
    var generated_ore_ids: Dictionary = {}
    for cell_variant in world.blocks.keys():
        var cell: Vector3i = cell_variant
        var block_id := int(world.blocks[cell])
        if world.ore_definitions.has(block_id):
            generated_ore_ids[block_id] = true
    if generated_ore_ids.size() < 3:
        print("PHASE2_CORE_SMOKE_FAIL generated_ore_count=%d" % generated_ore_ids.size())
        _finish(1)
        return
    var first_definition: Dictionary = world.ore_definitions[56]
    var raw_id := int(first_definition["raw_id"])
    var ingot_id := int(first_definition["ingot_id"])
    if str(world._block_name(56)).is_empty() or not str(world._block_name(raw_id)).begins_with("Сырьё:") or not str(world._block_name(ingot_id)).begins_with("Слиток:"):
        print("PHASE2_CORE_SMOKE_FAIL names")
        _finish(1)
        return
    var smelting_recipes := 0
    for recipe_variant in world.recipes:
        var recipe: Dictionary = recipe_variant
        var input: Dictionary = recipe.get("input", {})
        if input.has(raw_id) and int(recipe.get("output", -1)) == ingot_id:
            smelting_recipes += 1
    if smelting_recipes != 1 or world.recipes.size() < 77:
        print("PHASE2_CORE_SMOKE_FAIL recipes=%d smelting=%d" % [world.recipes.size(), smelting_recipes])
        _finish(1)
        return
    print("PHASE2_OFFLINE_CORE_PASS biomes=%d sampled_biomes=%d ores=%d generated_ores=%d structures=%d loot=%d recipes=%d bounds=%d/%d" % [world.external_biome_definitions.size(), sampled_biomes.size(), world.ore_definitions.size(), generated_ore_ids.size(), world.structure_definitions.size(), world.structure_loot.size(), world.recipes.size(), world.MAX_BLOCK_ID, world.MAX_CONTENT_ID])
    _finish(0)

func _finish(exit_code: int) -> void:
    if is_instance_valid(world):
        var player_node: Node = world.player
        if is_instance_valid(player_node):
            player_node.free()
        var body: Node = world.world_body
        var mesh: MeshInstance3D = world.world_mesh_instance as MeshInstance3D
        if is_instance_valid(body):
            body.free()
        if is_instance_valid(mesh):
            mesh.mesh = null
            mesh.material_override = null
            mesh.free()
        world.free()
    await get_tree().physics_frame
    await get_tree().process_frame
    get_tree().quit(exit_code)
