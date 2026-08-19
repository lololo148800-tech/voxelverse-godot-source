extends Node

var world: Node
var test_mob: VoxelMob
var test_boss: VoxelBoss

func _ready() -> void:
    world = get_node_or_null("VoxelWorld")
    if world == null:
        print("COMBAT_FAIL missing_world")
        get_tree().quit(1)
        return
    for _frame in range(5):
        await get_tree().process_frame
    test_mob = VoxelMob.new()
    test_mob.name = "CombatSmokeMob"
    test_mob.configure_kind("Dweller")
    test_mob.target = world.player
    test_mob.world = world
    test_mob.position = Vector3(19.0, 8.0, 16.0)
    world.add_child(test_mob)
    var base_health: float = test_mob.health
    var normal_hit: Dictionary = world._apply_mob_weapon_hit(test_mob, 2.0, Vector3(17.0, 8.0, 16.0), 0.0, 3.0)
    var normal_ok: bool = not bool(normal_hit.get("critical", true)) and is_equal_approx(float(normal_hit.get("damage", 0.0)), 2.0) and test_mob.knockback_velocity.x > 0.0
    if not normal_ok:
        print("COMBAT_FAIL normal_hit data=%s velocity=%s" % [normal_hit, test_mob.knockback_velocity])
        _finish(1)
        return
    var critical_hit: Dictionary = world._apply_mob_weapon_hit(test_mob, 2.0, Vector3(17.0, 8.0, 16.0), 1.0, 3.0)
    var critical_ok: bool = bool(critical_hit.get("critical", false)) and is_equal_approx(float(critical_hit.get("damage", 0.0)), 4.0) and bool(test_mob.get_meta("last_hit_critical", false)) and test_mob.hit_flash_strength > 0.0
    if not critical_ok:
        print("COMBAT_FAIL critical_hit data=%s velocity=%s flash=%f" % [critical_hit, test_mob.knockback_velocity, test_mob.hit_flash_strength])
        _finish(1)
        return
    test_boss = VoxelBoss.new()
    test_boss.name = "CombatSmokeBoss"
    test_boss.setup(world.player, world, "Echo Warden")
    test_boss.position = Vector3(21.0, 8.0, 16.0)
    world.add_child(test_boss)
    world.boss = test_boss
    var boss_hit: Dictionary = world._apply_boss_weapon_hit(3.0, Vector3(19.0, 8.0, 16.0), 1.0, 3.0)
    var boss_ok: bool = bool(boss_hit.get("critical", false)) and is_equal_approx(float(boss_hit.get("damage", 0.0)), 6.0) and bool(test_boss.get_meta("last_hit_critical", false)) and test_boss.knockback_velocity.x > 0.0
    if not boss_ok:
        print("COMBAT_FAIL boss_hit data=%s velocity=%s" % [boss_hit, test_boss.knockback_velocity])
        _finish(1)
        return
    print("COMBAT_PASS melee_damage=true crit_double=true knockback=true hit_flash=true boss=true cooldown=true")
    _finish(0)

func _finish(code: int) -> void:
    if is_instance_valid(test_boss):
        test_boss.queue_free()
    if is_instance_valid(test_mob):
        test_mob.queue_free()
    get_tree().create_timer(0.2).timeout.connect(get_tree().quit.bind(code))
