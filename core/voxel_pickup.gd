class_name VoxelPickup
extends Node3D

var item_id: int = 0
var amount: int = 1
var target: Node3D
var world: Node
var drift_time: float = 0.0
var collected: bool = false

func setup(resource_id: int, count: int, pickup_target: Node3D, pickup_world: Node) -> void:
    item_id = resource_id
    amount = count
    target = pickup_target
    world = pickup_world

func _ready() -> void:
    var cube := BoxMesh.new()
    cube.size = Vector3(0.28, 0.28, 0.28)
    var material := StandardMaterial3D.new()
    material.albedo_color = _pickup_color()
    material.emission_enabled = item_id >= 13
    material.emission = _pickup_color()
    material.emission_energy_multiplier = 0.8 if item_id >= 13 else 0.0
    cube.material = material
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.instance_count = 1
    multi.mesh = cube
    multi.set_instance_transform(0, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 0.0)))
    var mesh_instance := MultiMeshInstance3D.new()
    mesh_instance.multimesh = multi
    add_child(mesh_instance)

func _pickup_color() -> Color:
    if is_instance_valid(world) and world.has_method("_block_color"):
        return world.call("_block_color", item_id)
    return Color("f4d08a")

func _process(delta: float) -> void:
    if collected:
        return
    drift_time += delta
    rotation.y += delta * 2.4
    position.y += sin(drift_time * 3.0) * delta * 0.08
    if is_instance_valid(target) and target.global_position.distance_to(global_position) <= 1.55:
        if is_instance_valid(world) and world.has_method("_collect_pickup"):
            world.call("_collect_pickup", self)

func collect() -> void:
    if collected:
        return
    collected = true
    queue_free()
