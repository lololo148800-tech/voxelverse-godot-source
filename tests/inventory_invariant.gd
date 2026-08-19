extends Node

const WorldScript = preload("res://core/voxel_world.gd")

func _ready() -> void:
    var world := WorldScript.new()
    world._load_recipe_definitions()
    if world.recipes.size() < 18:
        print("INVENTORY_INVARIANT_FAIL recipe_registry")
        world.free()
        get_tree().quit(1)
        return
    var initial_wood := int(world.inventory.get(4, 0))
    var initial_planks := int(world.inventory.get(31, 0))
    world._craft_recipe(1)
    if int(world.inventory.get(4, 0)) != initial_wood - 1 or int(world.inventory.get(31, 0)) != initial_planks + 4:
        print("INVENTORY_INVARIANT_FAIL first_craft")
        world.free()
        get_tree().quit(1)
        return
    world._craft_recipe(1)
    if int(world.inventory.get(4, 0)) != initial_wood - 2 or int(world.inventory.get(31, 0)) != initial_planks + 8:
        print("INVENTORY_INVARIANT_FAIL second_craft")
        world.free()
        get_tree().quit(1)
        return
    world.inventory[4] = 0
    world._craft_recipe(1)
    if int(world.inventory.get(31, 0)) != initial_planks + 8:
        print("INVENTORY_INVARIANT_FAIL failed_craft_mutated")
        world.free()
        get_tree().quit(1)
        return
    print("INVENTORY_INVARIANT_PASS")
    world.free()
    get_tree().quit(0)
