class_name VoxelMob
extends CharacterBody3D

signal mob_died(kind, pos)

var target: Node3D
var world: Node3D
var home_position := Vector3.ZERO
var wander_phase: float = 0.0
var mob_kind: String = "EchoCrawler"
var max_health: float = 8.0
var health: float = 8.0
var move_speed: float = 1.4
var attack_damage: float = 2.0
var attack_range: float = 1.65
var detection_range: float = 12.0

const GRAVITY: float = 18.0
const ATTACK_COOLDOWN: float = 2.2
var attack_timer: float = 0.0
var whisper_aura_timer: float = 6.0
var whisper_circle_phase: float = 0.0
var knockback_velocity := Vector3.ZERO
var hit_flash_timer: float = 0.0
var hit_flash_strength: float = 0.0

enum State { WANDER, PURSUIT, ATTACK, FLEE }
var current_state: State = State.WANDER

func configure_kind(kind: String) -> void:
    mob_kind = kind
    match mob_kind:
        "RiftStalker":
            max_health = 14.0
            move_speed = 1.9
            attack_damage = 3.0
            attack_range = 1.8
            detection_range = 14.0
        "AshMite":
            max_health = 5.0
            move_speed = 2.7
            attack_damage = 1.0
            attack_range = 1.35
            detection_range = 10.0
        "Dweller":
            max_health = 25.0
            move_speed = 0.8
            attack_damage = 5.0
            attack_range = 2.0
            detection_range = 16.0
        "Goatman":
            max_health = 12.0
            move_speed = 3.2
            attack_damage = 2.5
            attack_range = 1.8
            detection_range = 18.0
        "Mimicer":
            max_health = 10.0
            move_speed = 1.5
            attack_damage = 3.5
            attack_range = 1.5
            detection_range = 8.0
        "WhisperEntity":
            max_health = 24.0
            move_speed = 1.55
            attack_damage = 5.0
            attack_range = 1.9
            detection_range = 24.0
            whisper_aura_timer = 5.0
        "StarSpirit":
            max_health = 9.0
            move_speed = 2.1
            attack_damage = 2.5
            attack_range = 1.6
            detection_range = 20.0
        "VoidSerpent":
            max_health = 18.0
            move_speed = 2.35
            attack_damage = 4.0
            attack_range = 1.8
            detection_range = 22.0
        "GuardianDrone":
            max_health = 32.0
            move_speed = 1.1
            attack_damage = 6.0
            attack_range = 2.1
            detection_range = 26.0
        _:
            max_health = 8.0
            move_speed = 1.4
            attack_damage = 2.0
            attack_range = 1.65
            detection_range = 12.0
    health = max_health

func apply_external_definition(definition: Dictionary) -> void:
    max_health = clampf(float(definition.get("max_health", max_health)), 1.0, 500.0)
    move_speed = clampf(float(definition.get("move_speed", move_speed)), 0.1, 10.0)
    attack_damage = clampf(float(definition.get("attack_damage", attack_damage)), 0.0, 100.0)
    attack_range = clampf(float(definition.get("attack_range", attack_range)), 0.5, 8.0)
    detection_range = clampf(float(definition.get("detection_range", detection_range)), 1.0, 64.0)
    health = max_health

func _ready() -> void:
    var cube := BoxMesh.new()
    cube.size = Vector3(0.84, 1.4 if mob_kind == "Goatman" else 0.84, 0.84)
    var material := StandardMaterial3D.new()
    material.albedo_color = _color_for_kind()
    material.roughness = 0.8
    # No direct material on mesh to avoid headless error
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.instance_count = 1
    multi.mesh = cube
    multi.set_instance_transform(0, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.48, 0.0)))
    var body_mesh := MultiMeshInstance3D.new()
    body_mesh.name = "Body"
    body_mesh.multimesh = multi
    body_mesh.material_override = material
    add_child(body_mesh)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = cube.size
    collision.shape = shape
    collision.position.y = cube.size.y / 2.0
    add_child(collision)

func _color_for_kind() -> Color:
    match mob_kind:
        "RiftStalker": return Color("3e83b8")
        "AshMite": return Color("b77a45")
        "Dweller": return Color("333333")
        "Goatman": return Color("5d4037")
        "Mimicer": return Color("4caf50")
        "WhisperEntity": return Color("a85ec4")
        "StarSpirit": return Color("f0d77b")
        "VoidSerpent": return Color("3b2f81")
        "GuardianDrone": return Color("6eb9c9")
        _: return Color("7e3147")

func _physics_process(delta: float) -> void:
    if not is_instance_valid(target):
        return
    
    attack_timer = maxf(0.0, attack_timer - delta)
    hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
    knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, delta * 10.0)
    hit_flash_strength = move_toward(hit_flash_strength, 0.0, delta * 7.0)
    scale = Vector3.ONE * (1.0 + hit_flash_strength)
    if mob_kind == "WhisperEntity":
        whisper_aura_timer -= delta
    var to_target := target.global_position - global_position
    to_target.y = 0.0
    var distance := to_target.length()
    if mob_kind == "WhisperEntity" and whisper_aura_timer <= 0.0 and distance <= 10.0:
        if target.has_method("apply_whisper_debuff"):
            target.call("apply_whisper_debuff", 4.5)
        whisper_aura_timer = randf_range(5.0, 10.0)
    
    # State Machine
    if distance < attack_range:
        current_state = State.ATTACK
    elif distance < detection_range:
        current_state = State.PURSUIT
    else:
        current_state = State.WANDER
        
    var direction := Vector3.ZERO
    match current_state:
        State.ATTACK:
            direction = Vector3.ZERO
            if attack_timer <= 0.0 and target.has_method("take_damage"):
                target.call("take_damage", attack_damage, mob_kind)
                attack_timer = ATTACK_COOLDOWN
        State.PURSUIT:
            if mob_kind == "WhisperEntity":
                whisper_circle_phase += delta * 1.15
                var radial := to_target.normalized() * clampf((distance - 4.6) * 0.75, -1.0, 1.0)
                var tangent := Vector3(-to_target.z, 0.0, to_target.x).normalized()
                direction = (radial + tangent * 0.72).normalized()
            else:
                direction = to_target.normalized()
        State.WANDER:
            wander_phase += delta
            direction = Vector3(cos(wander_phase * 0.7), 0.0, sin(wander_phase * 0.5)).normalized() * 0.25

    velocity.x = direction.x * move_speed + knockback_velocity.x
    velocity.z = direction.z * move_speed + knockback_velocity.z
    
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = -0.1
        
    move_and_slide()

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, critical: bool = false) -> void:
    var capped_knockback := knockback.limit_length(7.0)
    knockback_velocity.x = capped_knockback.x
    knockback_velocity.z = capped_knockback.z
    knockback_velocity.y = clampf(capped_knockback.y, 0.0, 4.5)
    hit_flash_timer = 0.18 if critical else 0.10
    hit_flash_strength = 0.16 if critical else 0.08
    attack_timer = maxf(attack_timer, 0.24 if critical else 0.12)
    set_meta("last_hit_critical", critical)
    set_meta("last_hit_damage", amount)
    health = maxf(0.0, health - amount)
    if health <= 0.0:
        mob_died.emit(mob_kind, global_position)
        queue_free()
