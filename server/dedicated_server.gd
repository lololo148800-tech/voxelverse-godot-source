extends Node

var world_instance: Node

func _ready() -> void:
    if not NetworkSession.host_from_dedicated_config("res://data/dedicated_server.json"):
        print("DEDICATED_SERVER_FAIL host_start")
        get_tree().quit(1)
        return
    var world_scene := load("res://core/voxel_world.tscn")
    if world_scene == null:
        print("DEDICATED_SERVER_FAIL world_scene")
        get_tree().quit(1)
        return
    world_instance = world_scene.instantiate()
    add_child(world_instance)
    print("DEDICATED_SERVER_READY name=%s code=%s port=%d" % [NetworkSession.server_name, NetworkSession.friend_code, NetworkSession.port])
    if "--smoke" in OS.get_cmdline_user_args():
        get_tree().create_timer(2.0).timeout.connect(_finish_smoke)

func _finish_smoke() -> void:
    if NetworkSession.is_host() and is_instance_valid(world_instance):
        print("DEDICATED_SERVER_SMOKE_PASS mobs=%d" % world_instance.mobs.size())
        NetworkSession.stop_online()
        get_tree().quit(0)
    else:
        print("DEDICATED_SERVER_SMOKE_FAIL")
        get_tree().quit(1)
