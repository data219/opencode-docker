// OmO 5.0.1 leaves these two special agents' effort outside OpenCode's variant field.
const expectedEffort = {
  "Prometheus - Plan Builder": "high",
  "Sisyphus-Junior": "medium",
};

export default async () => ({
  config: async (config) => {
    for (const [name, effort] of Object.entries(expectedEffort)) {
      const agent = config.agent?.[name];
      if (!agent) throw new Error(`OmO reasoning compatibility: missing ${name}`);
      if (agent.variant !== undefined) continue; // Upstream fix takes precedence.

      const upstreamEffort = agent.reasoning ?? agent.reasoningEffort;
      if (upstreamEffort !== effort) {
        throw new Error(`OmO reasoning compatibility: unexpected effort for ${name}: ${upstreamEffort}`);
      }
      agent.variant = effort;
    }
  },
});
