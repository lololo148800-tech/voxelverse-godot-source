extends Node

const VoxelMobScript = preload("res://core/voxel_mob.gd")

var world: Node
var test_mob: Node

func _ready() -> void:
    world = get_node_or_null("VoxelWorld")
    if world == null:
        print("PHASE8_SMOKE_FAIL missing_world")
        _finish(1)
        return
    var custom_name := "Киноварные сады"
    if world.external_biome_definitions.size() < 11 or not world.external_biome_definitions.has(custom_name):
        print("PHASE8_SMOKE_FAIL biome_definitions=%d" % world.external_biome_definitions.size())
        _finish(1)
        return
    if world.external_mob_definitions.size() < 2 or not world.external_mob_definitions.has("CinderMoth"):
        print("PHASE8_SMOKE_FAIL mob_definitions=%d" % world.external_mob_definitions.size())
        _finish(1)
        return
    if world._biome_for(12, 20) != custom_name:
        print("PHASE8_SMOKE_FAIL custom_region=%s" % world._biome_for(12, 20))
        _finish(1)
        return
    var custom_surface := int(world._surface_block_for_biome(custom_name))
    var custom_subsurface := int(world._subsurface_block_for_biome(custom_name))
    if custom_surface != world.EMBER or custom_subsurface != world.DIRT:
        print("PHASE8_SMOKE_FAIL surface=%d subsurface=%d" % [custom_surface, custom_subsurface])
        _finish(1)
        return
    var mob := VoxelMobScript.new()
    test_mob = mob
    mob.configure_kind("CinderMoth")
    mob.apply_external_definition(world.external_mob_definitions["CinderMoth"])
    var stats_ok: bool = is_equal_approx(mob.max_health, 11.0) and is_equal_approx(mob.move_speed, 2.2) and is_equal_approx(mob.attack_damage, 2.4)
    if not stats_ok or world.recipes.size() < 27:
        print("PHASE8_SMOKE_FAIL stats=%s recipes=%d" % [stats_ok, world.recipes.size()])
        _finish(1)
        return
    print("PHASE8_DATA_HOOKS_PASS biomes=%d mobs=%d recipes=%d custom=%s mob_health=%.1f" % [world.external_biome_definitions.size(), world.external_mob_definitions.size(), world.recipes.size(), custom_name, mob.max_health])
    _finish(0)

func _finish(exit_code: int) -> void:
    if is_instance_valid(test_mob):
        test_mob.free()
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
