#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_BIN:-/home/ubuntu/local_bin/godot}"
export HOME="${HOME:-/home/ubuntu/godot-home}"
export GODOT_SILENCE_ROOT_WARNING=1

has_unexpected_diagnostics() {
  local filtered
  filtered="$(mktemp)"
  grep -Ev '^(ERROR: Parameter "m" is null\.|   at: mesh_get_surface_count)' "$@" >"$filtered" || true
  if grep -Eq 'SCRIPT ERROR|Parse Error|ERROR:|Invalid|Cannot|WARNING:' "$filtered"; then
    rm -f "$filtered"
    return 0
  fi
  rm -f "$filtered"
  return 1
}

run_single() {
  local scene="$1"
  local label="$2"
  local log
  log="$(mktemp)"
  echo "REGRESSION_START ${label}"
  timeout 50s "$GODOT" --headless --path "$ROOT" --scene "$scene" >"$log" 2>&1
  cat "$log"
  if has_unexpected_diagnostics "$log"; then
    echo "REGRESSION_FAIL ${label} diagnostics"
    rm -f "$log"
    exit 1
  fi
  rm -f "$log"
  echo "REGRESSION_PASS ${label}"
}

cd "$ROOT"
python3 tests/content_registry_check.py
python3 tests/visual_asset_check.py

run_single res://tests/inventory_invariant.tscn inventory_invariant
run_single res://tests/phase2_offline_core_smoke.tscn phase2_offline_core
run_single res://tests/phase3_player_config_smoke.tscn phase3_player_config
run_single res://tests/water_input_perf_smoke.tscn water_input_perf_smoke
run_single res://tests/block_break_smoke.tscn block_break
run_single res://tests/combat_smoke.tscn combat_smoke
run_single res://tests/chunk_stream_smoke.tscn chunk_stream_smoke
run_single res://tests/chunk_dirty_rebuild_smoke.tscn chunk_dirty_rebuild_smoke
run_single res://tests/chunk_mass_destroy_perf_smoke.tscn chunk_mass_destroy_perf_smoke
run_single res://tests/structure_content_smoke.tscn structure_content_smoke
run_single res://tests/network_state_contract.tscn network_state_contract
run_single res://tests/network_session_contract.tscn network_session_contract
run_single res://tests/voice_smoke.tscn voice_smoke
run_single res://tests/phase7_gameplay_smoke.tscn phase7_gameplay
run_single res://tests/phase6_living_world_smoke.tscn phase6_living_world
run_single res://tests/phase8_data_hooks_smoke.tscn phase8_data_hooks

host_log="$(mktemp)"
client_log="$(mktemp)"
cleanup() {
  if [[ -n "${host_pid:-}" ]] && kill -0 "$host_pid" 2>/dev/null; then
    kill "$host_pid" 2>/dev/null || true
    wait "$host_pid" 2>/dev/null || true
  fi
  rm -f "$host_log" "$client_log"
}
trap cleanup EXIT

echo "REGRESSION_START network_world_smoke"
timeout 20s "$GODOT" --headless --path "$ROOT" --scene res://tests/network_world_smoke.tscn -- host >"$host_log" 2>&1 &
host_pid=$!
sleep 1
timeout 20s "$GODOT" --headless --path "$ROOT" --scene res://tests/network_world_smoke.tscn -- client >"$client_log" 2>&1
wait "$host_pid"
cat "$host_log"
cat "$client_log"
if has_unexpected_diagnostics "$host_log" "$client_log"; then
  echo "REGRESSION_FAIL network_world_smoke diagnostics"
  exit 1
fi
if ! grep -q 'WORLD_NETWORK_SMOKE_HOST_DONE' "$host_log" || ! grep -q 'WORLD_NETWORK_SMOKE_STATE_RECEIVED' "$client_log"; then
  echo "REGRESSION_FAIL network_world_smoke markers"
  exit 1
fi
echo "REGRESSION_PASS network_world_smoke"

echo "REGRESSION_ALL_PASS"
