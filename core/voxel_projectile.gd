class_name VoxelProjectile
extends Node3D

var direction := Vector3.FORWARD
var world: Node
var distance_travelled: float = 0.0
var damage: float = 6.0
var speed: float = 16.0
var critical_chance: float = 0.14
var knockback_force: float = 2.2

func setup(origin: Vector3, travel_direction: Vector3, projectile_world: Node) -> void:
    global_position = origin
    direction = travel_direction.normalized()
    world = projectile_world
    critical_chance = 0.14
    knockback_force = 2.2

func _ready() -> void:
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.12, 0.12, 0.42)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("f1d384")
    material.emission_enabled = true
    material.emission = Color("a8793a")
    material.emission_energy_multiplier = 0.7
    mesh.material = material
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.instance_count = 1
    multi.mesh = mesh
    var instance := MultiMeshInstance3D.new()
    instance.multimesh = multi
    add_child(instance)

func _process(delta: float) -> void:
    var step := direction * speed * delta
    position += step
    distance_travelled += step.length()
    if is_instance_valid(world) and world.has_method("_projectile_try_hit") and world.call("_projectile_try_hit", self):
        queue_free()
        return
    if distance_travelled >= 16.0:
        queue_free()
