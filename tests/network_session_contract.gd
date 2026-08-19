extends Node

func _ready() -> void:
    var config: Dictionary = NetworkSession.load_dedicated_config("res://data/dedicated_server.json")
    if str(config.get("server_name", "")).is_empty() or int(config.get("port", 0)) < 1024 or int(config.get("max_players", 0)) <= 0:
        print("SESSION_CONTRACT_FAIL config")
        get_tree().quit(1)
        return
    var code_a := NetworkSession._make_friend_code("Ashen Frontier host", 24639)
    var code_b := NetworkSession._make_friend_code("Ashen Frontier host", 24639)
    if code_a != code_b or not code_a.begins_with("AF-") or code_a.length() != 10:
        print("SESSION_CONTRACT_FAIL code=%s" % code_a)
        get_tree().quit(1)
        return
    if not NetworkSession.start_lan_discovery():
        print("SESSION_CONTRACT_FAIL discovery")
        get_tree().quit(1)
        return
    if not NetworkSession.host_game(24639, "Contract host"):
        print("SESSION_CONTRACT_FAIL host")
        NetworkSession.stop_lan_discovery()
        get_tree().quit(1)
        return
    if NetworkSession.friend_code.is_empty() or not NetworkSession.is_host():
        print("SESSION_CONTRACT_FAIL friend_code")
        NetworkSession.stop_online()
        NetworkSession.stop_lan_discovery()
        get_tree().quit(1)
        return
    print("SESSION_CONTRACT_PASS code=%s discovery=true config_port=%d" % [NetworkSession.friend_code, int(config.get("port", 0))])
    NetworkSession.stop_online()
    NetworkSession.stop_lan_discovery()
    get_tree().quit(0)
