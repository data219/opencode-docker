# OpenAI model map

Decision date: 2026-10-10. This map covers all 11 OmO agents and nine categories in the OpenCode profile. It uses only GPT-6.1 Sol, GPT-6 Astra, and GPT-6 Luna, at standard speed. These are evidence-based role assignments approved by the user, not claims of benchmark-proven optimality for this repository.

## Version and access baseline

- Dockerfile pins: **OpenCode 1.18.35**, source [`53d1eabb61e21162157817bf677da0a4ad3332e3`](https://github.com/anomalyco/opencode/tree/53d1eabb61e21162157817bf677da0a4ad3332e3); **OmO 5.1.29**, source [`6dfb41974556051b432c30ed71b134ed826c883a`](https://github.com/code-yeongyu/oh-my-openagent/tree/6dfb41974556051b432c30ed71b134ed826c883a).
- Previous tracked configuration: `master` at `26988e81bcbf8b0d0be81e677cf23fcecb867d1e`, under `bootstrap/config/variants/openai-chatgpt/`.
- Historical [PR #452](https://github.com/data219/opencode-docker/pull/452) was verified **OPEN and unmerged** at the audit, with head `231ecc8cca17bb0b8738abc0433efe75c3a97878`. Its GPT-6 Sol assignments and historical green checks are not the baseline configuration or validation of this change.
- All three selected models completed real, isolated `--pure`, `low` inference smoke calls through a fresh **V1 ChatGPT login** using the pinned OpenCode version. The access gate is passed; these calls do not measure role quality, every effort, or OmO fallback behavior.

| Model | Exact OpenCode ID | Supported reasoning in the pinned catalog and official API documentation |
|---|---|---|
| GPT-6.1 Sol | `openai/gpt-6.1-sol` | `low`, `medium`, `high`, `xhigh`, `max` |
| GPT-6 Astra | `openai/gpt-6-astra` | `low`, `medium`, `high`, `xhigh`, `max` |
| GPT-6 Luna | `openai/gpt-6-luna` | `none`, `low`, `medium`, `high`, `xhigh`, `max` |

Sol 6.1 and Astra do not support `none` or `minimal`. Codex's `ultra` orchestration mode is not a supported API effort for this configuration. See the official [Sol](https://developers.openai.com/api/docs/models/gpt-6.1-sol), [Astra](https://developers.openai.com/api/docs/models/gpt-6-astra), and [Luna](https://developers.openai.com/api/docs/models/gpt-6-luna) model pages.

## Matrix

**Legend:** S = GPT-6.1 Sol; A = GPT-6 Astra; L = GPT-6 Luna; S6 = GPT-6 Sol; S56 = GPT-5.6 Sol; T56 = GPT-5.6 Terra; M54 = GPT-5.4 mini; Spark = GPT-5.3 Codex Spark. Historical models appear only in the previous/default columns, never in the new routing. `—` means no explicit effort, not `none`.

The OmO column gives the **first native preference; OpenAI-only resolution or installer override** from the exact pin. It is not a guarantee of effective registration: provider availability, overrides, and special agent factories also affect selection. In particular, Junior initially inherits Atlas's resolved model unless explicitly overridden. The fallback column lists the ordered, user-approved **delegated-task** alternatives, all with the primary's explicit effort. Main-agent runtime model switching is disabled; see the fallback scope below.

### Agents

| Agent | Previous master model / effort | OmO 5.1.29 native; OpenAI-only | Selected model / effort | Delegated fallback / effort | Rationale and deviation from OmO |
|---|---|---|---|---|---|
| `sisyphus` | S56 / medium | Opus 5.5 / max; S56 / medium | **S / medium** | L / medium | Repeated orchestration and coding suit Sol. OpenAI restriction replaces the native model family; retain the OpenAI-path effort. |
| `hephaestus` | S56 / medium | S6 / medium; same | **S / medium** | L / medium | Autonomous implementation fits the upgraded Sol workhorse. Preserve the pinned effort instead of making every implementation a premium task. |
| `prometheus` | S56 / high | Fable 5.1 / xhigh; no OpenAI candidate | **S / high** | L / high | Explicit OpenAI replacement for interviews and planning; preserve established depth. Astra is reserved for selected difficult work. |
| `metis` | S56 / high | Fable 5.1 / max; no OpenAI candidate | **S / high** | L / high | Gap and risk analysis warrants Sol with high effort. The allowed model set requires a replacement for the native family. |
| `oracle` | S56 / high | S56 / xhigh; same | **S / high** | L / high | User chose Sol 6.1 high for consultation and debugging. Preserve prior effort, deliberately below OmO xhigh and different from #452's Astra assignment. |
| `momus` | S56 / xhigh | A / xhigh; same | **A / xhigh** | S / xhigh → L / xhigh | User retained OmO's premium review role for rigorous plan challenges. Higher usage is deliberate and limited to this role. |
| `atlas` | S56 / medium | Sonnet 5 / —; S56 / medium | **S / medium** | L / medium | Plan execution and coordination suit Sol; retain OpenAI-path effort while replacing the native family. |
| `sisyphus-junior` | Spark / medium | Sonnet 5 / —; S56 / medium, with Atlas inheritance | **S / medium** | L / medium | Delegated implementation may be substantial; the role name alone does not justify Luna. `quick` provides the light-work lane. |
| `explore` | M54 / — | Kimi Highspeed / off; L Fast / low | **L / low** | S / low | Focused code search suits Luna. Preserve OmO's OpenAI-path effort; use standard speed to avoid Fast-mode usage overhead. |
| `librarian` | M54 / — | Kimi Highspeed / off; L Fast / low | **L / high** | S / high | User chose high for source comparison and research. Deliberately exceeds OmO low; standard speed avoids Fast overhead. |
| `multimodal-looker` | GPT-5.4 / medium | S56 / low; same | **S / low** | L / low | Sol for visual interpretation, keeping OmO's low effort. Luna remains a lower-capability alternative rather than the default for complex diagrams. |

### Categories

| Category | Previous master model / effort | OmO 5.1.29 native; OpenAI-only | Selected model / effort | Delegated fallback / effort | Rationale and deviation from OmO |
|---|---|---|---|---|---|
| `ultrabrain` | S56 / xhigh | A / max; same | **A / max** | S / max → L / max | User-approved escalation lane for the hardest problems. Retain OmO's highest-depth setting; it is not the general default. |
| `visual-engineering` | S56 / high | Fable 5.1 / max; installer S56 / high | **S / high** | L / high | Sol handles UI implementation and visual coding; preserve the OpenAI-only override's depth. |
| `unspecified-high` | S56 / high | Opus 5.5 / medium; installer borrows `unspecified-low` without Claude Max20 | **S / high** | L / high | Explicit demanding general-work lane, independent of the installer's subscription-dependent path. High effort distinguishes it from `unspecified-low`. |
| `deep-low` | T56 / xhigh | S / medium; same | **S / medium** | L / medium | Matches the current pinned primary default. The restricted model set excludes upstream Fast and GPT-5.x alternatives. |
| `deep-high` | T56 / xhigh | A / high; same | **A / high** | S / high → L / high | User retained the pinned premium deep-work lane. High follows current OmO; #452's xhigh is not carried forward. |
| `writing` | T56 / medium | Opus 5.5 / low; no OpenAI candidate, installer omits the lane | **S / medium** | L / medium | Explicit OpenAI lane for longer technical writing and synthesis. Keep established effort; Luna fallback suits narrower transformations better. |
| `quick` | Spark / — | L Fast / low; installer L Fast with no explicit variant | **L / low** | S / low | Small, bounded tasks use Luna with explicit low effort. Standard speed and an explicit effort avoid Fast overhead and provider-default drift. |
| `unspecified-low` | M54 / low | Sonnet 5.5 / medium; T56 / high | **S / medium** | L / medium | User chose Sol medium for ordinary work that is not necessarily trivial. Deliberately lower effort than the OpenAI-only high path. |
| `artistry` | S56 / xhigh | Fable 5.1 / max; installer S56 / xhigh | **S / xhigh** | L / xhigh | User retained the OpenAI-only override's high depth for open creative tasks; no unmeasured claim that Astra would be better. |

Pinned sources: [agent requirements](https://github.com/code-yeongyu/oh-my-openagent/blob/6dfb41974556051b432c30ed71b134ed826c883a/packages/model-core/src/agent-model-requirements.ts), [category requirements](https://github.com/code-yeongyu/oh-my-openagent/blob/6dfb41974556051b432c30ed71b134ed826c883a/packages/model-core/src/category-model-requirements.ts), [OpenAI-only overrides](https://github.com/code-yeongyu/oh-my-openagent/blob/6dfb41974556051b432c30ed71b134ed826c883a/packages/omo-opencode/src/cli/openai-only-model-catalog.ts), and [installer resolution](https://github.com/code-yeongyu/oh-my-openagent/blob/6dfb41974556051b432c30ed71b134ed826c883a/packages/omo-opencode/src/cli/model-fallback.ts).

## Fallback scope and quota

The user approved these ordered retries for **delegated tasks**: A → S → L, S → L, and L → S. Each alternative carries the primary's explicit effort. These lists describe retries after an eligible failure, not quality-based escalation or proof that every alternative is equally capable.

`runtime_fallback.enabled=false` and `model_fallback=false` disable OmO's main-session model-switching mechanisms. A main agent stops visibly on model failure. OmO's delegated-task retries have their own paths and can still use the configured lists; disabling those two switches does not promise that all delegated fallback behavior is disabled. Separate behavior tests against the pinned source verify every category and agent chain, actual prompt payloads, and background retry payloads, including their reasoning levels. Authentication failures must be repaired rather than treated as a reason to try another model.

Luna fallback deliberately permits reduced capability even for difficult work. Preserve review and validation after such a retry. A fallback between OpenAI models does not restore an exhausted shared ChatGPT allowance and cannot reliably remedy a provider-wide failure.

| Concurrency scope | Limit |
|---|---:|
| OpenAI default for models without a model-specific limit | 3 |
| `openai/gpt-6.1-sol` | 2 |
| `openai/gpt-6-astra` | 1 |
| `openai/gpt-6-luna` | 2 |

OmO's model-specific limits override the provider default; they are separate counters, not a combined OpenAI cap. The selected limits allow up to five managed background tasks (2 + 1 + 2). Main sessions and nested synchronous tasks are outside this bound. These limits constrain parallelism, not quota or spending. See the pinned [concurrency manager](https://github.com/code-yeongyu/oh-my-openagent/blob/6dfb41974556051b432c30ed71b134ed826c883a/packages/omo-opencode/src/features/background-agent/concurrency.ts). No Fast/Priority model variants are selected. OpenAI recommends Sol 6.1 for complex coding, Luna for focused repeatable work, and Astra for the most demanding workflows. Higher effort can increase tokens and latency without guaranteeing better results. No fixed savings or ChatGPT quota ratios are assumed; task size, context, retries, model, and account allowances all matter. See [model selection](https://learn.chatgpt.com/docs/models) and [Work/Codex usage](https://help.openai.com/en/articles/20001516-managing-usage-with-gpt-6-astra-in-work-and-codex).

The user explicitly reviewed Oracle S/high, Momus A/xhigh, Deep-High A/high, Ultrabrain A/max, Librarian L/high, Unspecified-Low S/medium, Artistry S/xhigh, and the delegated fallback policy. Alternatives considered included stronger Oracle reasoning/Astra, Sol for premium review/deep work, and lower effort for Librarian/Artistry. They remain future workload comparisons, not silent routing changes.

## Authentication boundary

OpenCode 1.18.35 remains pinned. Its legacy ChatGPT login uses `auth.json` and its own refresh/inference flow. OpenCode 2's new `chatgpt-token-sharing` login stores credentials in SQLite with a registered client context and uses different endpoints. V2 login success neither updates V1's `auth.json` nor establishes V1 model access. Do not convert or copy a V2 token-sharing credential into V1 by renaming JSON fields. The successful model gate used a separate, fresh V1 login in an isolated container; no credentials belong in these tracked seeds. Sources: [V1 implementation](https://github.com/anomalyco/opencode/blob/53d1eabb61e21162157817bf677da0a4ad3332e3/packages/opencode/src/plugin/openai/codex.ts), [V2 token sharing](https://github.com/anomalyco/opencode/blob/v2.0.26/packages/core/src/plugin/provider/chatgpt.ts), and [V2's one-way legacy import](https://github.com/anomalyco/opencode/blob/v2.0.26/packages/core/src/database/migration/20260805200742_import_legacy_credentials.ts).

## Reasoning compatibility and verification

With the pinned versions, baseline `opencode debug agent` checks reproduced missing registered variants for **Prometheus high** and **Sisyphus-Junior medium**, despite configured efforts. The narrow compatibility adapter remains necessary: it fills only those missing variants and preserves an upstream variant when present. It validates both agents before applying either repair and throws on a missing agent or an unexpected effort. OpenCode 1.18.35 logs and suppresses plugin config-hook errors, so this diagnostic does not stop the host. The Docker registration test is the guard against changed assumptions. It must load after OmO. It is not a general reasoning translator; changing either expected effort requires revalidation. Sources: [agent overrides](https://github.com/code-yeongyu/oh-my-openagent/blob/6dfb41974556051b432c30ed71b134ed826c883a/packages/omo-opencode/src/agents/builtin-agents/agent-overrides.ts), [Prometheus builder](https://github.com/code-yeongyu/oh-my-openagent/blob/6dfb41974556051b432c30ed71b134ed826c883a/packages/omo-opencode/src/plugin-handlers/prometheus-agent-config-builder.ts), and [Junior factory](https://github.com/code-yeongyu/oh-my-openagent/blob/6dfb41974556051b432c30ed71b134ed826c883a/packages/omo-opencode/src/agents/sisyphus-junior/agent.ts).

Verification recorded while preparing this map:

- Three successful real inference smoke calls: Sol 6.1, Astra, and Luna, each `--pure`/`low`, through the pinned V1 login.
- The complete pinned image built successfully. All 11 registered agents match the selected model and `variant`, checked as the runtime user; the three catalog models expose all five selected standard reasoning levels.
- Docker verification: 100 unit tests (including three adapter tests), 32 lint tests, and all 11 integration cases verified. The model integration case was rerun successfully after replacing Doctor's misleading model-summary assertions with effective runtime checks.
- Separate Docker audit against unchanged OmO 5.1.29 sources: 28 behavior tests, 267 assertions covering all 20 primary/fallback chains, synchronous prompt and background retry payloads, and the disabled general fallback hooks. Network access and real model calls were blocked in this audit.
- Codex review and last-commit CI must be checked on the resulting PR. The historical PR's checks do not cover this change.

For final verification, run `opencode debug paths` and all 11 `opencode debug agent "<display name>"` checks as the `opencode` user inside the booted container. Assert model and `variant`; Doctor 5.1.29's model summary does not correctly account for canonical category `models` chains or some agent efforts, so it is used only for version/config-validity checks. Seeded-file existence alone is also insufficient. Exercise category/delegation resolution and retry effort separately. Managed changes belong in `bootstrap/config/`, with a config-version marker bump; do not edit `data/`. Merge requires explicit user approval.
