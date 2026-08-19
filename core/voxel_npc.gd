class_name VoxelNpc
extends Node3D

var npc_name: String = "Проводник Илара"
var definition_id: String = "wayfinder_ilara"
var role: String = "guide"
var faction: String = "Wayfinders"
var target: Node3D
var world: Node
var dialogue_index: int = 0
var dialogues: Array[String] = []
var schedule: Array[Dictionary] = []
var shop_inventory: Array[Dictionary] = []
var home_position := Vector3.ZERO
var schedule_destination := Vector3.ZERO

func setup(npc_target: Node3D, npc_world: Node, npc_definition: Dictionary = {}) -> void:
    target = npc_target
    world = npc_world
    if npc_definition.is_empty():
        npc_definition = {
            "id": "wayfinder_ilara",
            "name": "Проводник Илара",
            "role": "guide",
            "faction": "Wayfinders",
            "dialogue": [
                "Илара: Кристальный разлом лежит за восточными уступами.",
                "Илара: Если услышишь шёпот, проверь броню и запас еды."
            ],
            "schedule": [],
            "shop": []
        }
    definition_id = str(npc_definition.get("id", definition_id))
    npc_name = str(npc_definition.get("name", npc_name))
    role = str(npc_definition.get("role", role))
    faction = str(npc_definition.get("faction", faction))
    dialogues.clear()
    for line_variant in npc_definition.get("dialogue", []):
        if line_variant is String and not str(line_variant).strip_edges().is_empty():
            dialogues.append(str(line_variant))
    schedule.clear()
    for point_variant in npc_definition.get("schedule", []):
        if point_variant is Dictionary:
            schedule.append(point_variant)
    shop_inventory.clear()
    for offer_variant in npc_definition.get("shop", []):
        if offer_variant is Dictionary:
            shop_inventory.append(offer_variant)

func _ready() -> void:
    home_position = global_position
    var body_mesh := BoxMesh.new()
    body_mesh.size = Vector3(0.72, 1.35, 0.72)
    var material := StandardMaterial3D.new()
    material.albedo_color = _role_color()
    material.roughness = 0.72
    body_mesh.material = material
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.instance_count = 1
    multi.mesh = body_mesh
    multi.set_instance_transform(0, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.68, 0.0)))
    var body := MultiMeshInstance3D.new()
    body.name = "NpcBody"
    body.multimesh = multi
    add_child(body)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(0.72, 1.35, 0.72)
    collision.shape = shape
    collision.position.y = 0.68
    add_child(collision)

func _process(delta: float) -> void:
    if not is_instance_valid(world) or not world.has_method("_npc_schedule_destination"):
        return
    var destination_variant: Variant = world.call("_npc_schedule_destination", self)
    if not destination_variant is Vector3:
        return
    schedule_destination = destination_variant
    if global_position.distance_to(schedule_destination) > 0.7:
        global_position = global_position.move_toward(schedule_destination, delta * 1.15)

func interact() -> void:
    if dialogues.is_empty():
        return
    var line := dialogues[dialogue_index % dialogues.size()]
    dialogue_index = (dialogue_index + 1) % dialogues.size()
    if is_instance_valid(world) and world.has_method("_on_npc_talk"):
        world.call("_on_npc_talk", self, "%s: %s" % [npc_name, line] if not line.begins_with(npc_name + ":") else line)

func get_shop_inventory() -> Array[Dictionary]:
    return shop_inventory

func _role_color() -> Color:
    match role:
        "quartermaster":
            return Color("c58f58")
        "cartographer":
            return Color("7887d8")
        _:
            return Color("3f9b9f")
