load ../test_helper

@test "OmO compatibility only restores the two missing agent variants" {
  run node --input-type=module -e '
    import plugin from "./bootstrap/config/omo-reasoning-compat.mjs";
    const config = { agent: {
      "Prometheus - Plan Builder": { reasoning: "high" },
      "Sisyphus-Junior": { reasoningEffort: "medium" },
      "Metis": { reasoning: "high" },
    } };
    await (await plugin()).config(config);
    if (config.agent["Prometheus - Plan Builder"].variant !== "high") process.exit(1);
    if (config.agent["Sisyphus-Junior"].variant !== "medium") process.exit(1);
    if (config.agent.Metis.variant !== undefined) process.exit(1);
  '
  [ "$status" -eq 0 ]
}

@test "OmO compatibility defers to an upstream variant" {
  run node --input-type=module -e '
    import plugin from "./bootstrap/config/omo-reasoning-compat.mjs";
    const config = { agent: {
      "Prometheus - Plan Builder": { variant: "xhigh" },
      "Sisyphus-Junior": { variant: "high" },
    } };
    await (await plugin()).config(config);
    if (config.agent["Prometheus - Plan Builder"].variant !== "xhigh") process.exit(1);
    if (config.agent["Sisyphus-Junior"].variant !== "high") process.exit(1);
  '
  [ "$status" -eq 0 ]
}

@test "OmO compatibility fails when its pinned agent assumptions change" {
  run node --input-type=module -e '
    import plugin from "./bootstrap/config/omo-reasoning-compat.mjs";
    const hook = (await plugin()).config;
    const missing = { agent: { "Prometheus - Plan Builder": { reasoning: "high" } } };
    const changed = { agent: {
      "Prometheus - Plan Builder": { reasoning: "xhigh" },
      "Sisyphus-Junior": { reasoningEffort: "medium" },
    } };
    for (const config of [missing, changed]) {
      let failed = false;
      try { await hook(config); } catch { failed = true; }
      if (!failed) process.exit(1);
    }
  '
  [ "$status" -eq 0 ]
}
