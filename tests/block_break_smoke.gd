extends Node

var world: Node
var original_tool: int = 0
var original_durability: Array[int] = []

func _ready() -> void:
    world = get_node_or_null("VoxelWorld")
    if world == null:
        print("BLOCK_BREAK_FAIL missing_world")
        get_tree().quit(1)
        return
    for _frame in range(4):
        await get_tree().process_frame
    original_tool = world.equipped_tool
    original_durability = world.tool_durability.duplicate()
    var stone_hardness: float = world._block_break_hardness(world.STONE)
    var grass_hardness: float = world._block_break_hardness(world.GRASS)
    if stone_hardness <= grass_hardness:
        print("BLOCK_BREAK_FAIL hardness grass=%f stone=%f" % [grass_hardness, stone_hardness])
        _finish(1)
        return
    var stone_speed_pick: float = world._block_break_speed(world.STONE)
    world.equipped_tool = 1
    var stone_speed_cutter: float = world._block_break_speed(world.STONE)
    if stone_speed_pick <= stone_speed_cutter:
        print("BLOCK_BREAK_FAIL tool_speed pick=%f cutter=%f" % [stone_speed_pick, stone_speed_cutter])
        _finish(1)
        return
    world.equipped_tool = 0
    var cell := Vector3i(16, 7, 16)
    world._set_runtime_block(cell, world.GRASS)
    world.target_cell = cell
    world.target_valid = true
    var before_durability: int = int(world.tool_durability[0])
    world._begin_block_break()
    world._update_block_break(0.1)
    var partial: bool = world._get_block(cell) == world.GRASS and world.break_progress > 0.0 and world.break_progress < 1.0
    if not partial:
        print("BLOCK_BREAK_FAIL partial progress=%f block=%d" % [world.break_progress, world._get_block(cell)])
        _finish(1)
        return
    for _step in range(20):
        world._update_block_break(0.1)
        if world._get_block(cell) == world.AIR:
            break
    var completed: bool = world._get_block(cell) == world.AIR
    var durability_used: bool = int(world.tool_durability[0]) == before_durability - 1
    if not completed or not durability_used:
        print("BLOCK_BREAK_FAIL completed=%s durability=%d/%d" % [completed, int(world.tool_durability[0]), before_durability])
        _finish(1)
        return
    world.world_mode = "Творческий тест"
    world.player.set_creative_mode(true)
    world._set_runtime_block(cell, world.STONE)
    world.target_cell = cell
    world.target_valid = true
    world.equipped_tool = 0
    world._begin_block_break()
    world._update_block_break(0.02)
    var creative_instant: bool = world._get_block(cell) == world.AIR
    if not creative_instant:
        print("BLOCK_BREAK_FAIL creative block=%d progress=%f" % [world._get_block(cell), world.break_progress])
        _finish(1)
        return
    print("BLOCK_BREAK_PASS progress=true hardness=true tool_speed=true durability=true creative_instant=true")
    _finish(0)

func _finish(code: int) -> void:
    if world != null:
        world.equipped_tool = original_tool
        if not original_durability.is_empty():
            world.tool_durability = original_durability
    get_tree().create_timer(0.2).timeout.connect(get_tree().quit.bind(code))
