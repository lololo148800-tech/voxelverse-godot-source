class_name VoxelBoss
extends CharacterBody3D

var target: Node3D
var world: Node
var max_health: float = 40.0
var health: float = 40.0
var move_speed: float = 0.85
var attack_damage: float = 4.0
var attack_timer: float = 0.0
var phase_timer: float = 0.0
var defeated: bool = false
var knockback_velocity := Vector3.ZERO
var hit_flash_timer: float = 0.0
var hit_flash_strength: float = 0.0
var boss_kind: String = "Echo Warden"

func setup(boss_target: Node3D, boss_world: Node, kind: String = "Echo Warden") -> void:
    target = boss_target
    world = boss_world
    boss_kind = kind
    if boss_kind == "Void Leviathan":
        max_health = 72.0
        health = max_health
        move_speed = 1.15
        attack_damage = 7.0

func _ready() -> void:
    var cube := BoxMesh.new()
    var boss_scale := 1.35 if boss_kind == "Echo Warden" else 2.2
    cube.size = Vector3(boss_scale, boss_scale * 1.15, boss_scale)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("6f3b92") if boss_kind == "Echo Warden" else Color("243b8f")
    material.emission_enabled = true
    material.emission = Color("311442") if boss_kind == "Echo Warden" else Color("101d5c")
    material.emission_energy_multiplier = 1.2
    material.roughness = 0.65
    cube.material = material
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.instance_count = 1
    multi.mesh = cube
    multi.set_instance_transform(0, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.78, 0.0)))
    var mesh_instance := MultiMeshInstance3D.new()
    mesh_instance.name = "EchoWardenBody"
    mesh_instance.multimesh = multi
    add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(1.35, 1.55, 1.35)
    collision.shape = shape
    collision.position.y = cube.size.y * 0.5
    add_child(collision)

func _physics_process(delta: float) -> void:
    if defeated or not is_instance_valid(target):
        return
    attack_timer = maxf(0.0, attack_timer - delta)
    phase_timer += delta
    hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
    knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, delta * 7.0)
    hit_flash_strength = move_toward(hit_flash_strength, 0.0, delta * 5.0)
    scale = Vector3.ONE * (1.0 + hit_flash_strength)
    var to_target := target.global_position - global_position
    to_target.y = 0.0
    var distance := to_target.length()
    var direction := Vector3.ZERO
    if distance < 2.4:
        if attack_timer <= 0.0 and target.has_method("take_damage"):
            target.call("take_damage", attack_damage, boss_kind)
            VoxelAudio.play_event("mob_attack", clampf(attack_damage / 6.0, 0.9, 1.4))
            attack_timer = 2.8
    elif distance < 18.0 and distance > 2.0:
        direction = to_target.normalized()
    else:
        direction = Vector3(cos(phase_timer * 0.4), 0.0, sin(phase_timer * 0.35)).normalized() * 0.2
    velocity.x = direction.x * move_speed + knockback_velocity.x
    velocity.z = direction.z * move_speed + knockback_velocity.z
    if not is_on_floor():
        velocity.y -= 18.0 * delta
    else:
        velocity.y = -0.1
    move_and_slide()

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, critical: bool = false) -> void:
    if defeated:
        return
    var capped_knockback := knockback.limit_length(5.0)
    knockback_velocity.x = capped_knockback.x
    knockback_velocity.z = capped_knockback.z
    knockback_velocity.y = clampf(capped_knockback.y, 0.0, 3.5)
    hit_flash_timer = 0.2 if critical else 0.12
    hit_flash_strength = 0.14 if critical else 0.07
    attack_timer = maxf(attack_timer, 0.3 if critical else 0.16)
    set_meta("last_hit_critical", critical)
    set_meta("last_hit_damage", amount)
    health = maxf(0.0, health - amount)
    VoxelAudio.play_event("mob_hit", 1.15 if not critical else 1.35)
    if health <= 0.0:
        defeated = true
        if is_instance_valid(world) and world.has_method("_on_boss_defeated"):
            world.call("_on_boss_defeated", self)
        queue_free()
