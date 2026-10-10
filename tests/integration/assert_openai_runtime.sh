#!/usr/bin/env bash
set -euo pipefail

# Execute inside the booted image as opencode, with a dummy API key and no inference.
dump_dir="$(mktemp -d)"
trap 'rm -rf "$dump_dir"' EXIT
opencode debug paths | grep -F 'config     /home/opencode/.config/opencode'
opencode debug config > "$dump_dir/config.json"
jq -e '
  .model == "openai/gpt-6.1-sol"
  and .small_model == "openai/gpt-6-luna"
  and (.plugin | index("file:///opt/opencode-defaults/omo-reasoning-compat.mjs") != null)
' "$dump_dir/config.json" >/dev/null

while IFS='|' read -r name model effort; do
  opencode debug agent "$name" > "$dump_dir/agent.json"
  jq -e --arg model "$model" --arg effort "$effort" '
    .model.providerID == "openai"
    and .model.modelID == $model
    and .variant == $effort
  ' "$dump_dir/agent.json" >/dev/null || {
    jq '{name, model, variant, reasoning, reasoningEffort}' "$dump_dir/agent.json"
    exit 1
  }

  # Junior consumes its chain through OmO delegation, not OpenCode agent metadata.
  if [ "$name" != 'Sisyphus-Junior' ]; then
    jq -e --arg name "$name" --arg model "$model" --arg effort "$effort" '
      .agent[$name].fallback_models == (
        if $model == "gpt-6-astra" then ["openai/gpt-6.1-sol", "openai/gpt-6-luna"]
        elif $model == "gpt-6-luna" then ["openai/gpt-6.1-sol"]
        else ["openai/gpt-6-luna"] end
        | map(. + ":" + $effort)
      )
    ' "$dump_dir/config.json" >/dev/null || {
      jq --arg name "$name" '.agent[$name] | {name, fallback_models}' "$dump_dir/config.json"
      exit 1
    }
  fi
  printf '%s: %s (%s)\n' "$name" "$model" "$effort"
done <<'AGENTS'
Sisyphus - ultraworker|gpt-6.1-sol|medium
Hephaestus - Deep Agent|gpt-6.1-sol|medium
Prometheus - Plan Builder|gpt-6.1-sol|high
Metis - Plan Consultant|gpt-6.1-sol|high
oracle|gpt-6.1-sol|high
Momus - Plan Critic|gpt-6-astra|xhigh
Atlas - Plan Executor|gpt-6.1-sol|medium
Sisyphus-Junior|gpt-6.1-sol|medium
explore|gpt-6-luna|low
librarian|gpt-6-luna|high
multimodal-looker|gpt-6.1-sol|low
AGENTS

opencode models openai --refresh >/dev/null
opencode models openai --verbose > "$dump_dir/models.txt"
node - "$dump_dir/models.txt" <<'NODE'
const fs = require("fs");
const raw = fs.readFileSync(process.argv[2], "utf8");
const expected = ["gpt-6.1-sol", "gpt-6-astra", "gpt-6-luna"];
const models = new Map();
for (const part of raw.split(/(?=^openai\/)/m)) {
  const split = part.indexOf("\n");
  if (expected.some(id => part.slice(0, split) === `openai/${id}`)) {
    models.set(part.slice(0, split), JSON.parse(part.slice(split)));
  }
}
for (const id of expected) {
  const model = models.get(`openai/${id}`);
  if (!model) throw new Error(`Missing ${id} in runtime catalog`);
  if (model.options?.serviceTier) throw new Error(`${id} must use standard service`);
  for (const effort of ["low", "medium", "high", "xhigh", "max"]) {
    if (model.variants?.[effort]?.reasoningEffort !== effort || model.variants[effort].serviceTier) {
      throw new Error(`${id} ${effort} is not a supported standard variant`);
    }
  }
  console.log(`${id}: standard low/medium/high/xhigh/max available`);
}
NODE
