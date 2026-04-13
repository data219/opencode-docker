#!/usr/bin/env tsx

import { readFileSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";
import { spawn } from "child_process";

import { MCPClient } from "mcp-client";

import { estimateTokens } from "./query.ts";

interface BenchmarkQuery {
  label: string;
  target: string;
  query: string;
  libraryId?: string;
  mcpTokens?: number;
}

interface BenchmarkOptions {
  file: string;
  maxChars: number;
  maxSections: number;
  mcpImage: string;
}

interface BenchmarkMetric {
  label: string;
  mode: "skill" | "mcp";
  resolvedLibraryId?: string;
  durationMs: number;
  chars: number;
  bytes: number;
  estimatedTokens: number;
  details: Record<string, unknown>;
}

const __dirname = dirname(fileURLToPath(import.meta.url));

function parseArgs(argv: string[]): BenchmarkOptions {
  const defaults: BenchmarkOptions = {
    file: join(__dirname, "benchmark.queries.example.json"),
    maxChars: 8000,
    maxSections: 8,
    mcpImage: "mcp/context7",
  };

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "--file") {
      defaults.file = argv[index + 1] || defaults.file;
      index += 1;
    } else if (argument === "--max-chars") {
      defaults.maxChars = Number.parseInt(argv[index + 1] || "", 10) || defaults.maxChars;
      index += 1;
    } else if (argument === "--max-sections") {
      defaults.maxSections = Number.parseInt(argv[index + 1] || "", 10) || defaults.maxSections;
      index += 1;
    } else if (argument === "--mcp-image") {
      defaults.mcpImage = argv[index + 1] || defaults.mcpImage;
      index += 1;
    } else if (argument === "--help" || argument === "-h") {
      console.log(`
Context7 benchmark

Usage:
  npm run benchmark -- --file ./benchmark.queries.json

Options:
  --file <path>          Query file (default: benchmark.queries.example.json)
  --max-chars <number>   Skill max chars (default: 8000)
  --max-sections <n>     Skill max sections (default: 8)
  --mcp-image <image>    MCP docker image (debug-only; default: mcp/context7)
`);
      process.exit(0);
    }
  }

  return defaults;
}

export function loadQueriesFromString(content: string): BenchmarkQuery[] {
  const raw = JSON.parse(content);
  if (!Array.isArray(raw)) {
    throw new Error("Benchmark file must contain a JSON array");
  }

  return raw.map((entry) => {
    if (!entry.label || !entry.target || !entry.query || !entry.libraryId) {
      throw new Error(`Each benchmark entry needs label, target, query and libraryId: ${JSON.stringify(entry)}`);
    }
    return entry as BenchmarkQuery;
  });
}

function loadQueries(file: string): BenchmarkQuery[] {
  return loadQueriesFromString(readFileSync(file, "utf-8"));
}

function extractTextFromMcp(result: any): string {
  if (typeof result?.structuredContent?.context === "string") {
    return result.structuredContent.context;
  }

  if (Array.isArray(result?.content)) {
    return result.content
      .filter((item: any) => item?.type === "text")
      .map((item: any) => String(item.text || ""))
      .join("\n")
      .trim();
  }

  return "";
}

function tryParseJson(text: string): any | null {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function rankLibraryIdCandidates(candidates: string[], target: string): string | undefined {
  const normalizedTarget = target.toLowerCase().replace(/[^a-z0-9]+/g, "");
  const filtered = candidates.filter((candidate) => candidate !== "/org/project");

  const scored = filtered.map((candidate) => {
    const normalizedCandidate = candidate.toLowerCase().replace(/[^a-z0-9]+/g, "");
    const containsTarget = normalizedCandidate.includes(normalizedTarget) ? 10 : 0;
    const pathDepth = candidate.split("/").filter(Boolean).length;
    const pathDepthScore = pathDepth >= 2 ? 2 : 0;
    return {
      candidate,
      score: containsTarget + pathDepthScore,
    };
  });

  return scored.sort((left, right) => right.score - left.score)[0]?.candidate;
}

function extractLibraryId(result: any, target: string): string | undefined {
  const candidates = new Set<string>();
  const structured = result?.structuredContent;
  if (typeof structured?.libraryId === "string") {
    candidates.add(structured.libraryId);
  }

  if (typeof structured?.context7CompatibleLibraryID === "string") {
    candidates.add(structured.context7CompatibleLibraryID);
  }

  if (Array.isArray(structured?.results) && typeof structured.results[0]?.id === "string") {
    for (const item of structured.results) {
      if (typeof item?.id === "string") {
        candidates.add(item.id);
      }
    }
  }

  const text = extractTextFromMcp(result);
  const parsed = tryParseJson(text);
  if (parsed) {
    if (typeof parsed.libraryId === "string") {
      candidates.add(parsed.libraryId);
    }
    if (Array.isArray(parsed.results)) {
      for (const item of parsed.results) {
        if (typeof item?.id === "string") {
          candidates.add(item.id);
        }
      }
    }
  }

  for (const match of text.matchAll(/\/[a-z0-9._-]+\/[a-z0-9._/-]+/gi)) {
    candidates.add(match[0]);
  }

  return rankLibraryIdCandidates(Array.from(candidates), target);
}

async function runSkillBenchmark(
  query: BenchmarkQuery,
  options: BenchmarkOptions,
): Promise<BenchmarkMetric> {
  const commandArgs = [
    "--import",
    "tsx",
    "query.ts",
    query.libraryId ? "context" : "ask",
    query.libraryId || query.target,
    query.query,
    "--json",
    "--no-cache",
    "--max-chars",
    String(options.maxChars),
    "--max-sections",
    String(options.maxSections),
  ];

  const start = process.hrtime.bigint();
  const result = await new Promise<{ stdout: string; stderr: string; exitCode: number }>((resolve) => {
    const child = spawn(process.execPath, commandArgs, {
      cwd: __dirname,
      env: process.env,
      stdio: ["ignore", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";

    child.stdout.on("data", (chunk) => {
      stdout += chunk.toString();
    });

    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });

    child.on("close", (exitCode) => {
      resolve({
        stdout,
        stderr,
        exitCode: exitCode ?? 1,
      });
    });
  });
  const durationMs = Number(process.hrtime.bigint() - start) / 1_000_000;

  if (result.exitCode !== 0) {
    throw new Error(`Skill benchmark failed for "${query.label}": ${result.stderr || result.stdout}`);
  }

  const payload = JSON.parse(result.stdout);
  const context = String(payload.context || "");

  return {
    label: query.label,
    mode: "skill",
    resolvedLibraryId: String(payload.libraryId || query.libraryId || ""),
    durationMs,
    chars: context.length,
    bytes: Buffer.byteLength(context, "utf-8"),
    estimatedTokens: estimateTokens(context),
    details: {
      cached: payload.cached,
      optimization: payload.optimization,
    },
  };
}

async function runMcpBenchmark(
  query: BenchmarkQuery,
  options: BenchmarkOptions,
): Promise<BenchmarkMetric> {
  const apiKey = process.env.CONTEXT7_API_KEY;
  if (!apiKey) {
    throw new Error("CONTEXT7_API_KEY is required for MCP benchmarking");
  }

  const client = new MCPClient({
    name: "context7-benchmark",
    version: "1.0.0",
  });

  const start = process.hrtime.bigint();
  await client.connect({
    type: "stdio",
    command: "docker",
    args: [
      "run",
      "-i",
      "--rm",
      "-e",
      "CONTEXT7_API_KEY",
      "-e",
      "MCP_TRANSPORT=stdio",
      options.mcpImage,
    ],
    env: {
      ...process.env,
      CONTEXT7_API_KEY: apiKey,
    },
  });

  try {
    const tools = await client.getAllTools();
    const docsTool = tools.find((tool) => tool.name === "query-docs" || tool.name === "get-library-docs");

    if (!docsTool) {
      throw new Error("Context7 MCP docs tool not found");
    }

    const libraryId = query.libraryId;

    const docsArgs: Record<string, unknown> = {};
    const docsProperties = Object.keys(docsTool.inputSchema?.properties || {});

    if (docsProperties.includes("libraryId")) {
      docsArgs.libraryId = libraryId;
    }
    if (docsProperties.includes("context7CompatibleLibraryID")) {
      docsArgs.context7CompatibleLibraryID = libraryId;
    }
    if (docsProperties.includes("query")) {
      docsArgs.query = query.query;
    }
    if (docsProperties.includes("topic")) {
      docsArgs.topic = query.query;
    }
    if (docsProperties.includes("tokens")) {
      docsArgs.tokens = query.mcpTokens || 5000;
    }

    const docsResult = await client.callTool({
      name: docsTool.name,
      arguments: docsArgs,
    });

    const context = extractTextFromMcp(docsResult);
    const durationMs = Number(process.hrtime.bigint() - start) / 1_000_000;

    return {
      label: query.label,
      mode: "mcp",
      resolvedLibraryId: libraryId,
      durationMs,
      chars: context.length,
      bytes: Buffer.byteLength(context, "utf-8"),
      estimatedTokens: estimateTokens(context),
      details: {
        docsTool: docsTool.name,
        requestedTokens: docsArgs.tokens || null,
      },
    };
  } finally {
    await client.close().catch(() => undefined);
  }
}

function formatDuration(value: number): string {
  return value.toFixed(1);
}

function printComparison(metrics: BenchmarkMetric[]): void {
  const grouped = new Map<string, BenchmarkMetric[]>();
  for (const metric of metrics) {
    grouped.set(metric.label, [...(grouped.get(metric.label) || []), metric]);
  }

  for (const [label, entries] of grouped) {
    const skill = entries.find((entry) => entry.mode === "skill");
    const mcp = entries.find((entry) => entry.mode === "mcp");

    console.log(`\n# ${label}`);
    if (skill) {
      console.log(
        `skill duration=${formatDuration(skill.durationMs)}ms chars=${skill.chars} bytes=${skill.bytes} tokens_est=${skill.estimatedTokens} library=${skill.resolvedLibraryId || "-"}`,
      );
    }
    if (mcp) {
      console.log(
        `mcp   duration=${formatDuration(mcp.durationMs)}ms chars=${mcp.chars} bytes=${mcp.bytes} tokens_est=${mcp.estimatedTokens} library=${mcp.resolvedLibraryId || "-"}`,
      );
    }
    if (skill && mcp) {
      console.log(
        `delta skill_vs_mcp duration=${formatDuration(skill.durationMs - mcp.durationMs)}ms chars=${skill.chars - mcp.chars} tokens_est=${skill.estimatedTokens - mcp.estimatedTokens}`,
      );
    }
  }

  console.log("\n# Raw JSON");
  console.log(JSON.stringify(metrics, null, 2));
}

async function main(): Promise<void> {
  const options = parseArgs(process.argv.slice(2));
  const queries = loadQueries(options.file);
  const metrics: BenchmarkMetric[] = [];

  for (const query of queries) {
    metrics.push(await runSkillBenchmark(query, options));
    metrics.push(await runMcpBenchmark(query, options));
  }

  printComparison(metrics);
}

const entrypoint = process.argv[1] ? fileURLToPath(import.meta.url) === process.argv[1] : false;
if (entrypoint) {
  await main();
}
