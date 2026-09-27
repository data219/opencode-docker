#!/usr/bin/env node

const fs = require("fs");
const { parse, printParseErrorCode } = require("jsonc-parser");

const file = process.argv[2];

if (!file) {
  console.error("usage: assert-openai-model-map.js <file>");
  process.exit(2);
}

const errors = [];
const document = parse(fs.readFileSync(file, "utf8"), errors);

if (errors.length > 0) {
  for (const error of errors) {
    console.error(`${file}:${error.offset}: ${printParseErrorCode(error.error)}`);
  }
  process.exit(1);
}

const config = document["[opencode]"];
if (!config) {
  throw new Error("OmO 5 requires an [opencode] harness section");
}

const expectedAgents = {
  sisyphus: ["openai/gpt-5.6-sol", "medium"],
  hephaestus: ["openai/gpt-5.6-sol", "medium"],
  prometheus: ["openai/gpt-5.6-sol", "high"],
  metis: ["openai/gpt-5.6-sol", "high"],
  oracle: ["openai/gpt-6-astra", "high"],
  momus: ["openai/gpt-5.6-sol", "xhigh"],
  atlas: ["openai/gpt-5.6-sol", "medium"],
};
const expectedCategories = {
  ultrabrain: ["openai/gpt-6-astra", "high"],
  "visual-engineering": ["openai/gpt-5.6-sol", "high"],
  "unspecified-high": ["openai/gpt-5.6-sol", "high"],
  "deep-low": ["openai/gpt-5.6-terra", "xhigh"],
  "deep-high": ["openai/gpt-5.6-terra", "xhigh"],
  writing: ["openai/gpt-5.6-terra", "medium"],
  artistry: ["openai/gpt-5.6-sol", "xhigh"],
};

for (const [name, [model, variant]] of Object.entries(expectedAgents)) {
  const actual = config.agents?.[name];
  if (actual?.model !== model || actual?.variant !== variant) {
    throw new Error(`unexpected ${name} mapping: ${JSON.stringify(actual)}`);
  }
}

for (const [name, [model, variant]] of Object.entries(expectedCategories)) {
  const actual = config.categories?.[name];
  if (actual?.model !== model || actual?.variant !== variant) {
    throw new Error(`unexpected ${name} mapping: ${JSON.stringify(actual)}`);
  }
}

for (const [scope, allowed] of [["agents", "oracle"], ["categories", "ultrabrain"]]) {
  for (const [name, value] of Object.entries(config[scope])) {
    if (value.model?.startsWith("openai/gpt-6-astra") && name !== allowed) {
      throw new Error(`Astra is not approved for ${scope}.${name}`);
    }
    if (value.fallback_models?.some((model) => model.startsWith("openai/gpt-6-astra"))) {
      throw new Error(`Astra must not be added as a fallback for ${scope}.${name}`);
    }
  }
}

for (const name of ["explore", "librarian"]) {
  if (!config.agents?.[name]?.fallback_models?.includes("openai/gpt-5.6-luna")) {
    throw new Error(`${name} must use GPT-5.6 Luna as a fallback`);
  }
}

if (!config.agents?.["multimodal-looker"]?.fallback_models?.includes("openai/gpt-5.6-sol")) {
  throw new Error("multimodal-looker must use GPT-5.6 Sol as a fallback");
}

for (const model of ["openai/gpt-5.6-sol", "openai/gpt-5.6-terra", "openai/gpt-5.6-luna"]) {
  if (config.background_task?.modelConcurrency?.[model] !== 2) {
    throw new Error(`unexpected ${model} concurrency`);
  }
}

for (const target of [config.agents.oracle, config.categories.ultrabrain]) {
  if (target.fallback_models?.[0] !== "openai/gpt-5.6-sol") {
    throw new Error("Astra must fall back to GPT-5.6 Sol first");
  }
}

if (config.background_task?.modelConcurrency?.["openai/gpt-6-astra"] !== 1) {
  throw new Error("Astra background concurrency must be limited to one");
}

if (JSON.stringify(config).includes("openai/gpt-5.5")) {
  throw new Error("GPT-5.5 must not remain in the active model map");
}
