load ../test_helper

@test "OmO compatibility restores the missing Prometheus and Junior variants" {
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

@test "OmO compatibility preserves variants already supplied upstream" {
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

@test "OmO compatibility rejects changed agent or effort assumptions" {
  run node --input-type=module -e '
    import plugin from "./bootstrap/config/omo-reasoning-compat.mjs";
    const hook = (await plugin()).config;
    for (const config of [
      { agent: { "Prometheus - Plan Builder": { reasoning: "high" } } },
      { agent: {
        "Prometheus - Plan Builder": { reasoning: "xhigh" },
        "Sisyphus-Junior": { reasoningEffort: "medium" },
      } },
      { agent: {
        "Prometheus - Plan Builder": { reasoning: "high" },
        "Sisyphus-Junior": { reasoningEffort: "high" },
      } },
    ]) {
      let failed = false;
      try { await hook(config); } catch { failed = true; }
      if (!failed) process.exit(1);
      if (Object.values(config.agent).some(agent => agent.variant !== undefined)) process.exit(1);
    }
  '
  [ "$status" -eq 0 ]
}
