from __future__ import annotations

import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
world = (root / "core" / "voxel_world.gd").read_text(encoding="utf-8")
recipes = json.loads((root / "data" / "recipes.json").read_text(encoding="utf-8"))
ores = json.loads((root / "data" / "ores.json").read_text(encoding="utf-8"))
biomes = json.loads((root / "data" / "biomes.json").read_text(encoding="utf-8"))
structures = json.loads((root / "data" / "structures.json").read_text(encoding="utf-8"))
npcs = json.loads((root / "data" / "npcs.json").read_text(encoding="utf-8"))
quests = json.loads((root / "data" / "quests.json").read_text(encoding="utf-8"))
horror_encounters = json.loads((root / "data" / "horror_encounters.json").read_text(encoding="utf-8"))
boss_arenas = json.loads((root / "data" / "boss_arenas.json").read_text(encoding="utf-8"))

constant_pairs = dict((name, int(value)) for name, value in re.findall(r"const\s+([A-Z_]+):\s*int\s*=\s*(\d+)", world))
required = {
    "COSMIC_STONE", "STAR_DUST", "ASTRAL_CRYSTAL", "ASTRAL_SCRAP",
    "WHISPER_SOIL", "WHISPER_BARK", "WHISPER_SHARD", "ASTRAL_METAL",
    "COSMIC_ICE", "VOID_SHARD", "ANTIMATTER", "NEBULA_GAS",
}
missing = sorted(name for name in required if name not in constant_pairs)
if missing:
    raise SystemExit(f"missing constants: {missing}")

inventory_match = re.search(r"inventory_item_ids = \[(.*?)\]", world, re.S)
if inventory_match is None:
    raise SystemExit("inventory_item_ids not found")
ids = [constant_pairs[name] for name in re.findall(r"[A-Z_]+", inventory_match.group(1))]
if len(ids) != len(set(ids)):
    raise SystemExit("duplicate inventory item IDs")
if not set(constant_pairs[name] for name in required).issubset(set(ids)):
    raise SystemExit("Astral IDs missing from inventory catalog")

if len(ores) != 50:
    raise SystemExit(f"ore registry must contain 50 entries, got {len(ores)}")
if sum(1 for ore in ores if ore.get("kind") == "common") != 30:
    raise SystemExit("ore registry must contain 30 common entries")
if sum(1 for ore in ores if ore.get("kind") == "rare") != 20:
    raise SystemExit("ore registry must contain 20 rare entries")
block_ids = [int(ore["block_id"]) for ore in ores]
raw_ids = [int(ore["raw_id"]) for ore in ores]
ingot_ids = [int(ore["ingot_id"]) for ore in ores]
if len(set(block_ids)) != 50 or set(block_ids) != set(range(56, 106)):
    raise SystemExit("ore block IDs are not the exact 56..105 range")
if len(set(raw_ids)) != 50 or set(raw_ids) != set(range(256, 306)):
    raise SystemExit("ore raw IDs are not the exact 256..305 range")
if len(set(ingot_ids)) != 50 or set(ingot_ids) != set(range(306, 356)):
    raise SystemExit("ore ingot IDs are not the exact 306..355 range")
for ore in ores:
    required_ore_fields = {"id", "name", "block_id", "raw_id", "ingot_id", "kind", "biome_tags", "depth_min", "depth_max", "rarity_bps", "cluster_size", "tool_tier", "color"}
    if not required_ore_fields.issubset(ore):
        raise SystemExit(f"ore is missing fields: {ore.get('id')}")
    if not ore["biome_tags"] or ore["depth_min"] < 1 or ore["depth_max"] < ore["depth_min"] or ore["rarity_bps"] <= 0:
        raise SystemExit(f"invalid ore bounds: {ore.get('id')}")

if len(biomes) < 50:
    raise SystemExit(f"biome registry must contain at least 50 entries, got {len(biomes)}")
biome_names = [str(biome.get("name", "")) for biome in biomes]
if len(set(biome_names)) != len(biome_names) or any(not name for name in biome_names):
    raise SystemExit("biome names must be unique and non-empty")
for biome in biomes:
    required_biome_fields = {"name", "surface_block", "subsurface_block", "spawn_mob", "terrain_lift", "temperature", "hazard", "rarity"}
    if not required_biome_fields.issubset(biome):
        raise SystemExit(f"biome is missing fields: {biome.get('name')}")
    if not (0.0 <= float(biome["temperature"]) <= 1.0) or int(biome["terrain_lift"]) < -2 or int(biome["terrain_lift"]) > 5:
        raise SystemExit(f"invalid biome climate/height: {biome.get('name')}")

if len(structures) < 8:
    raise SystemExit(f"structure registry must contain at least 8 entries, got {len(structures)}")
structure_ids = [str(structure.get("id", "")) for structure in structures]
if len(set(structure_ids)) != len(structure_ids) or any(not structure_id for structure_id in structure_ids):
    raise SystemExit("structure IDs must be unique and non-empty")
for structure in structures:
    required_structure_fields = {"id", "name", "anchor", "size", "height", "floor_block", "wall_block", "chest_offset", "loot", "salt"}
    if not required_structure_fields.issubset(structure) or len(structure["loot"]) == 0:
        raise SystemExit(f"structure is missing fields or loot: {structure.get('id')}")

npc_ids = [str(npc.get("id", "")) for npc in npcs]
if len(npcs) < 3 or len(set(npc_ids)) != len(npc_ids) or any(not npc_id for npc_id in npc_ids):
    raise SystemExit("NPC registry must contain 3 unique non-empty definitions")
for npc in npcs:
    if not {"id", "name", "role", "faction", "spawn_tag", "dialogue", "schedule", "shop"}.issubset(npc):
        raise SystemExit(f"NPC is missing fields: {npc.get('id')}")
    if not npc["dialogue"] or not npc["schedule"]:
        raise SystemExit(f"NPC lacks dialogue or schedule: {npc.get('id')}")
    for offer in npc["shop"]:
        if int(offer.get("item_id", -1)) < 0 or int(offer.get("price_id", -1)) < 0 or int(offer.get("price_count", 0)) <= 0:
            raise SystemExit(f"invalid NPC shop offer: {npc.get('id')}")

quest_ids = [str(quest.get("id", "")) for quest in quests]
if len(quests) < 6 or len(set(quest_ids)) != len(quest_ids) or any(not quest_id for quest_id in quest_ids):
    raise SystemExit("quest registry must contain 6 unique non-empty definitions")
for quest in quests:
    if not {"id", "title", "description", "order", "objective", "reward", "hidden_flags"}.issubset(quest):
        raise SystemExit(f"quest is missing fields: {quest.get('id')}")
    if int(quest["objective"].get("target", 0)) <= 0 or int(quest["reward"].get("count", 0)) <= 0:
        raise SystemExit(f"invalid quest bounds: {quest.get('id')}")

horror_ids = [str(encounter.get("id", "")) for encounter in horror_encounters]
if len(horror_encounters) < 3 or len(set(horror_ids)) != len(horror_ids):
    raise SystemExit("horror encounter registry must contain 3 unique definitions")
for encounter in horror_encounters:
    if not {"id", "trigger", "cooldown", "fear", "weakness_duration", "message"}.issubset(encounter):
        raise SystemExit(f"horror encounter is missing fields: {encounter.get('id')}")
    if float(encounter["fear"]) < 0.0 or float(encounter["fear"]) > 100.0:
        raise SystemExit(f"invalid horror fear bounds: {encounter.get('id')}")

arena_ids = [str(arena.get("id", "")) for arena in boss_arenas]
if len(boss_arenas) < 2 or len(set(arena_ids)) != len(arena_ids):
    raise SystemExit("boss arena registry must contain 2 unique definitions")
for arena in boss_arenas:
    if not {"id", "boss_kind", "center", "radius", "phase_thresholds", "phase_messages", "reward"}.issubset(arena):
        raise SystemExit(f"boss arena is missing fields: {arena.get('id')}")
    if len(arena["phase_thresholds"]) != 2 or len(arena["phase_messages"]) != 3 or float(arena["radius"]) < 3.0:
        raise SystemExit(f"invalid boss arena: {arena.get('id')}")

if len(recipes) < 18:
    raise SystemExit("recipe registry is unexpectedly short")
constant_values = set(constant_pairs.values())
for recipe in recipes:
    if int(recipe["output"]) not in constant_values:
        raise SystemExit(f"unknown recipe output: {recipe['output']}")
    for input_id in recipe["input"]:
        if int(input_id) not in constant_values:
            raise SystemExit(f"unknown recipe input: {input_id}")

print(f"CONTENT_REGISTRY_PASS constants={len(constant_pairs)} inventory_ids={len(ids)} recipes={len(recipes)} ores={len(ores)} common=30 rare=20 biomes={len(biomes)} structures={len(structures)} npcs={len(npcs)} quests={len(quests)} horror={len(horror_encounters)} arenas={len(boss_arenas)}")
