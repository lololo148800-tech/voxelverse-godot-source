extends Node

func _ready() -> void:
    var world_a := VoxelWorld.new()
    var world_b := VoxelWorld.new()
    add_child(world_a)
    add_child(world_b)
    await get_tree().process_frame
    world_a.seed_value = 1357911
    world_b.seed_value = 2468022
    world_a._generate_world()
    world_b._generate_world()
    var fingerprint_a := _world_fingerprint(world_a)
    var fingerprint_b := _world_fingerprint(world_b)
    var heights_a := _height_signature(world_a)
    var heights_b := _height_signature(world_b)
    var biomes_a := _biome_signature(world_a)
    var biomes_b := _biome_signature(world_b)
    var different := fingerprint_a != fingerprint_b and heights_a != heights_b and biomes_a != biomes_b
    if not different:
        print("TERRAIN_SEED_DIVERSITY_FAIL fingerprint_a=%s fingerprint_b=%s heights_a=%s heights_b=%s biomes_a=%s biomes_b=%s" % [fingerprint_a, fingerprint_b, heights_a, heights_b, biomes_a, biomes_b])
        get_tree().quit(1)
        return
    print("TERRAIN_SEED_DIVERSITY_PASS seed_a=1357911 seed_b=2468022 fingerprint_different=true heights_different=true biomes_a=%d biomes_b=%d" % [biomes_a.size(), biomes_b.size()])
    get_tree().quit(0)

func _world_fingerprint(world: VoxelWorld) -> int:
    var hash_value := 17
    for x in range(0, world.WORLD_SIZE_X, 4):
        for z in range(0, world.WORLD_SIZE_Z, 4):
            var y := world._highest_solid_y(x, z)
            hash_value = hash_value * 31 + y + world._biome_for(x, z).hash()
    return hash_value

func _height_signature(world: VoxelWorld) -> String:
    var values: Array[String] = []
    for point in [Vector2i(2, 2), Vector2i(12, 12), Vector2i(22, 22), Vector2i(36, 14), Vector2i(50, 42), Vector2i(60, 60)]:
        values.append(str(world._highest_solid_y(point.x, point.y)))
    return ",".join(values)

func _biome_signature(world: VoxelWorld) -> Dictionary:
    var values: Dictionary = {}
    for x in range(0, world.WORLD_SIZE_X, 5):
        for z in range(0, world.WORLD_SIZE_Z, 5):
            values[world._biome_for(x, z)] = true
    return values
