#!/usr/bin/env tsx

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

export const DEFAULT_MAX_CHARS = 8000;
export const DEFAULT_MAX_SECTIONS = 8;
export const DEFAULT_TOP_RESULTS = 5;

export interface CliOptions {
  json: boolean;
  cache: boolean;
  raw: boolean;
  stats: boolean;
  maxChars: number;
  maxSections: number;
  topResults: number;
}

export interface ParsedArgs {
  command?: string;
  target?: string;
  query?: string;
  options: CliOptions;
}

export interface OptimizationOptions {
  maxChars: number;
  maxSections: number;
}

export interface OptimizationStats {
  charsBefore: number;
  charsAfter: number;
  estimatedTokensBefore: number;
  estimatedTokensAfter: number;
  blockCountBefore: number;
  blockCountAfter: number;
  truncated: boolean;
}

export interface OptimizationResult {
  text: string;
  stats: OptimizationStats;
}

interface Context7SearchResult {
  id?: string;
  title?: string;
  trustScore?: number;
  benchmarkScore?: number;
  description?: string;
}

const __dirname = dirname(fileURLToPath(import.meta.url));
const envPath = join(__dirname, ".env");
const cacheDir = (() => {
  const xdgCacheHome = process.env.XDG_CACHE_HOME?.trim();
  if (xdgCacheHome) {
    return join(xdgCacheHome, "codex-context7");
  }

  const home = process.env.HOME?.trim();
  if (home) {
    return join(home, ".cache", "codex-context7");
  }

  return join(__dirname, ".cache");
})();

const defaultOptions: CliOptions = {
  json: false,
  cache: false,
  raw: false,
  stats: false,
  maxChars: DEFAULT_MAX_CHARS,
  maxSections: DEFAULT_MAX_SECTIONS,
  topResults: DEFAULT_TOP_RESULTS,
};

function printHelp(): void {
  console.log(`
Context7 Query CLI

Usage:
  npx tsx query.ts <command> [options] <target> <query>

Commands:
  search, s    Search for libraries by name with intelligent LLM-powered ranking
  context, c   Retrieve token-optimized documentation context
  ask, a       Resolve a library by name, then fetch token-optimized documentation

Options:
  --json, -j              Output as JSON
  --cache                 Enable local caching
  --no-cache              Disable local caching
  --raw                   Return raw context without local compression
  --stats                 Include optimization metrics in text output
  --max-chars <number>    Hard cap for context output length (default: 8000)
  --max-sections <number> Maximum number of relevant sections to keep (default: 8)
  --top-results <number>  Maximum number of search results to keep (default: 5)

Examples:
  npx tsx query.ts search symfony "security voters" --json
  npx tsx query.ts context /symfony/symfony-docs "security voters" --max-chars 5000
  npx tsx query.ts ask symfony "How do I build a voter?" --cache --json
`);
}

function normalizeResolverValue(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, "");
}

export function estimateTokens(text: string): number {
  return Math.max(1, Math.ceil(text.length / 4));
}

function normalizeWhitespace(text: string): string {
  return text
    .replace(/\r\n/g, "\n")
    .replace(/[ \t]+\n/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function splitIntoBlocks(text: string): string[] {
  const normalized = normalizeWhitespace(text);
  if (!normalized) {
    return [];
  }

  const lines = normalized.split("\n");
  const blocks: string[] = [];
  const current: string[] = [];
  let inCodeFence = false;

  const flush = () => {
    if (current.length === 0) {
      return;
    }
    const block = current.join("\n").trim();
    if (block) {
      blocks.push(block);
    }
    current.length = 0;
  };

  for (const line of lines) {
    if (line.trim().startsWith("```")) {
      inCodeFence = !inCodeFence;
      current.push(line);
      continue;
    }

    if (!inCodeFence && line.trim() === "") {
      flush();
      continue;
    }

    current.push(line);
  }

  flush();
  return blocks;
}

function queryTerms(query: string): string[] {
  return Array.from(
    new Set(
      query
        .toLowerCase()
        .split(/[^a-z0-9]+/i)
        .map((term) => term.trim())
        .filter((term) => term.length >= 3),
    ),
  );
}

function scoreBlock(block: string, terms: string[], index: number): number {
  const lowerBlock = block.toLowerCase();
  const headingBonus = block.startsWith("#") ? 2 : 0;
  const codeBonus = block.includes("```") ? 1 : 0;
  const earlyBonus = Math.max(0, 1 - index * 0.05);

  let termScore = 0;
  for (const term of terms) {
    if (lowerBlock.includes(term)) {
      termScore += 4;
    }

    const regex = new RegExp(`\\b${term}\\b`, "g");
    termScore += (lowerBlock.match(regex) || []).length;
  }

  return headingBonus + codeBonus + earlyBonus + termScore;
}

function isHeadingBlock(block: string): boolean {
  return block.startsWith("#");
}

function isCodeBlock(block: string): boolean {
  return block.startsWith("```");
}

function truncateText(text: string, maxChars: number): { text: string; truncated: boolean } {
  if (text.length <= maxChars) {
    return { text, truncated: false };
  }

  if (maxChars <= 3) {
    return { text: ".".repeat(maxChars), truncated: true };
  }

  return {
    text: `${text.slice(0, maxChars - 3).trimEnd()}...`,
    truncated: true,
  };
}

export function optimizeContextText(
  text: string,
  query: string,
  options: OptimizationOptions,
): OptimizationResult {
  const normalized = normalizeWhitespace(text);
  const blocks = splitIntoBlocks(normalized);
  const terms = queryTerms(query);

  const scoredBlocks = blocks.map((block, index) => ({
    block,
    index,
    score: scoreBlock(block, terms, index),
  }));

  const selectedIndexes = new Set<number>();

  if (scoredBlocks.length > 0) {
    selectedIndexes.add(0);
  }

  for (const item of scoredBlocks
    .slice()
    .sort((left, right) => right.score - left.score || left.index - right.index)
    .slice(0, options.maxSections)) {
    selectedIndexes.add(item.index);

    const currentBlock = blocks[item.index];
    const nextBlock = blocks[item.index + 1];
    const previousBlock = blocks[item.index - 1];

    if (isHeadingBlock(currentBlock) && nextBlock) {
      selectedIndexes.add(item.index + 1);
    }

    if (nextBlock && isCodeBlock(nextBlock)) {
      selectedIndexes.add(item.index + 1);
    }

    if (previousBlock && isHeadingBlock(previousBlock)) {
      selectedIndexes.add(item.index - 1);
    }
  }

  const selectedBlocks = scoredBlocks
    .filter((item) => selectedIndexes.has(item.index))
    .sort((left, right) => left.index - right.index)
    .map((item) => item.block);

  const joined = normalizeWhitespace(selectedBlocks.join("\n\n"));
  const truncated = truncateText(joined, options.maxChars);

  return {
    text: truncated.text,
    stats: {
      charsBefore: normalized.length,
      charsAfter: truncated.text.length,
      estimatedTokensBefore: estimateTokens(normalized),
      estimatedTokensAfter: estimateTokens(truncated.text),
      blockCountBefore: blocks.length,
      blockCountAfter: selectedBlocks.length,
      truncated: truncated.truncated,
    },
  };
}

function parseIntegerOption(name: string, value: string | undefined, fallback: number): number {
  if (!value) {
    throw new Error(`Missing value for ${name}`);
  }

  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error(`Invalid value for ${name}: ${value}`);
  }

  return parsed || fallback;
}

export function parseCliArgs(argv: string[]): ParsedArgs {
  const options: CliOptions = { ...defaultOptions };
  const positional: string[] = [];

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];

    if (argument === "--json" || argument === "-j") {
      options.json = true;
    } else if (argument === "--cache") {
      options.cache = true;
    } else if (argument === "--no-cache") {
      options.cache = false;
    } else if (argument === "--raw") {
      options.raw = true;
    } else if (argument === "--stats") {
      options.stats = true;
    } else if (argument === "--max-chars") {
      options.maxChars = parseIntegerOption(argument, argv[index + 1], DEFAULT_MAX_CHARS);
      index += 1;
    } else if (argument === "--max-sections") {
      options.maxSections = parseIntegerOption(argument, argv[index + 1], DEFAULT_MAX_SECTIONS);
      index += 1;
    } else if (argument === "--top-results") {
      options.topResults = parseIntegerOption(argument, argv[index + 1], DEFAULT_TOP_RESULTS);
      index += 1;
    } else if (argument === "--help" || argument === "-h") {
      return { command: "help", options };
    } else {
      positional.push(argument);
    }
  }

  const [command, target, ...queryParts] = positional;
  const query = queryParts.join(" ").trim() || undefined;

  return {
    command,
    target,
    query,
    options,
  };
}

function loadApiKey(): string {
  const envKey = process.env.CONTEXT7_API_KEY?.trim();
  if (envKey) {
    return envKey;
  }

  if (existsSync(envPath)) {
    const envContent = readFileSync(envPath, "utf-8");
    const match = envContent.match(/CONTEXT7_API_KEY=(.+)/);
    if (match?.[1]?.trim()) {
      return match[1].trim();
    }
  }

  throw new Error("CONTEXT7_API_KEY not found. Set it in the environment or in .env.");
}

export function resolveLibraryMatch(
  target: string,
  results: Context7SearchResult[],
): string {
  const candidates = results.filter((result) => typeof result.id === "string");
  if (candidates.length === 0) {
    throw new Error(`No Context7 library match found for "${target}"`);
  }

  const normalizedTarget = normalizeResolverValue(target);
  const exact = candidates.find((result) => {
    const title = normalizeResolverValue(String(result.title || ""));
    const id = normalizeResolverValue(String(result.id || ""));
    return title === normalizedTarget || id.endsWith(normalizedTarget);
  });

  if (exact?.id) {
    return exact.id;
  }

  if (candidates.length === 1 && candidates[0].id) {
    return candidates[0].id;
  }

  const topCandidate = candidates[0];
  const secondCandidate = candidates[1];
  const topTrust = Number(topCandidate.trustScore || 0);
  const secondTrust = Number(secondCandidate?.trustScore || 0);

  if (topCandidate.id && topTrust >= secondTrust + 3) {
    return topCandidate.id;
  }

  const candidateSummary = candidates
    .slice(0, 3)
    .map((result) => `${String(result.title || result.id)} (${String(result.id)})`)
    .join(", ");

  throw new Error(
    `Ambiguous Context7 library match for "${target}". Provide an explicit libraryId. Candidates: ${candidateSummary}`,
  );
}

function ensureCacheDir(): void {
  if (!existsSync(cacheDir)) {
    mkdirSync(cacheDir, { recursive: true });
  }
}

function getCacheKey(type: string, key: string): string {
  const hash = Buffer.from(`${type}:${key}`).toString("base64url").slice(0, 24);
  return join(cacheDir, `context7_${type}_${hash}.json`);
}

function getCachedData(type: string, key: string, enabled: boolean): unknown | null {
  if (!enabled) {
    return null;
  }

  const cacheFile = getCacheKey(type, key);
  if (!existsSync(cacheFile)) {
    return null;
  }

  try {
    const cacheData = JSON.parse(readFileSync(cacheFile, "utf-8"));
    const ageHours = (Date.now() - cacheData.timestamp) / (1000 * 60 * 60);
    if (ageHours > 24) {
      return null;
    }
    return cacheData.data;
  } catch {
    return null;
  }
}

function setCachedData(type: string, key: string, data: unknown, enabled: boolean): void {
  if (!enabled) {
    return;
  }

  ensureCacheDir();
  const cacheFile = getCacheKey(type, key);

  try {
    writeFileSync(
      cacheFile,
      JSON.stringify(
        {
          timestamp: Date.now(),
          data,
        },
        null,
        2,
      ),
    );
  } catch {
    // Ignore cache write failures.
  }
}

async function fetchJson(url: URL, apiKey: string): Promise<any> {
  const response = await fetch(url.toString(), {
    headers: {
      Authorization: `Bearer ${apiKey}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Context7 API error (${response.status} ${response.statusText}): ${await response.text()}`);
  }

  return response.json();
}

async function fetchText(url: URL, apiKey: string): Promise<string> {
  const response = await fetch(url.toString(), {
    headers: {
      Authorization: `Bearer ${apiKey}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Context7 API error (${response.status} ${response.statusText}): ${await response.text()}`);
  }

  return response.text();
}

function normalizeLibraryId(target: string): string {
  return target.startsWith("/") ? target : `/${target}`;
}

async function searchLibraries(
  apiKey: string,
  libraryName: string,
  query: string,
  options: CliOptions,
): Promise<Record<string, unknown>> {
  const normalizedTarget = normalizeLibraryId(libraryName);
  const cacheKey = `search:${normalizedTarget}:${query}:${options.topResults}`;
  const cached = getCachedData("search", cacheKey, options.cache) as Record<string, unknown> | null;

  if (cached) {
    return { ...cached, cached: true };
  }

  const url = new URL("https://context7.com/api/v2/libs/search");
  url.searchParams.set("libraryName", normalizedTarget.split("/")[1] || "");
  url.searchParams.set("query", query);

  const data = await fetchJson(url, apiKey);
  const rawResults = Array.isArray(data.results) ? data.results : [];
  const results = rawResults.slice(0, options.topResults) as Context7SearchResult[];

  const output = {
    libraryName,
    query,
    count: results.length,
    totalCount: rawResults.length,
    results,
    cached: false,
  };

  setCachedData("search", cacheKey, output, options.cache);
  return output;
}

async function getContext(
  apiKey: string,
  libraryId: string,
  query: string,
  options: CliOptions,
): Promise<Record<string, unknown>> {
  const normalizedLibraryId = normalizeLibraryId(libraryId);
  const cacheKey = `context:${normalizedLibraryId}:${query}`;
  const cached = getCachedData("context", cacheKey, options.cache) as string | null;

  const rawContext = cached ?? (await (async () => {
    const url = new URL("https://context7.com/api/v2/context");
    url.searchParams.set("libraryId", normalizedLibraryId);
    url.searchParams.set("query", query);
    url.searchParams.set("type", "txt");
    const text = await fetchText(url, apiKey);
    setCachedData("context", cacheKey, text, options.cache);
    return text;
  })());

  const normalizedRawContext = normalizeWhitespace(rawContext);
  const rawBlockCount = splitIntoBlocks(normalizedRawContext).length;
  const optimized = options.raw
    ? null
    : optimizeContextText(rawContext, query, {
        maxChars: options.maxChars,
        maxSections: options.maxSections,
      });

  const optimization = options.raw
    ? {
        charsBefore: normalizedRawContext.length,
        charsAfter: normalizedRawContext.length,
        estimatedTokensBefore: estimateTokens(normalizedRawContext),
        estimatedTokensAfter: estimateTokens(normalizedRawContext),
        blockCountBefore: rawBlockCount,
        blockCountAfter: rawBlockCount,
        truncated: false,
      }
    : optimized!.stats;

  const context = options.raw ? normalizedRawContext : optimized!.text;

  return {
    libraryId: normalizedLibraryId,
    query,
    cached: Boolean(cached),
    optimization,
    context,
  };
}

async function askContext(
  apiKey: string,
  target: string,
  query: string,
  options: CliOptions,
): Promise<Record<string, unknown>> {
  const libraryId = target.startsWith("/")
    ? target
    : await (async () => {
      const search = await searchLibraries(apiKey, target, query, {
        ...options,
        topResults: Math.max(options.topResults, 5),
      });
      const results = Array.isArray(search.results) ? search.results as Context7SearchResult[] : [];
      return resolveLibraryMatch(target, results);
    })();

  const context = await getContext(apiKey, libraryId, query, options);
  return {
    mode: target.startsWith("/") ? "direct" : "resolved",
    ...context,
  };
}

function renderSearchText(payload: Record<string, unknown>): string {
  const lines: string[] = [];
  const results = Array.isArray(payload.results) ? payload.results as Array<Record<string, unknown>> : [];

  if (results.length === 0) {
    return "No results found.";
  }

  for (const [index, library] of results.entries()) {
    lines.push(`${index + 1}. ${String(library.title || library.id || "Unknown")}`);
    lines.push(`   ID: ${String(library.id || "N/A")}`);
    lines.push(`   Description: ${String(library.description || "N/A")}`);
    lines.push(`   Trust Score: ${String(library.trustScore || "N/A")}`);
    lines.push(`   Benchmark: ${String(library.benchmarkScore || "N/A")}`);
    lines.push("");
  }

  return lines.join("\n").trimEnd();
}

function renderContextText(payload: Record<string, unknown>, statsEnabled: boolean): string {
  const context = String(payload.context || "");
  if (!statsEnabled) {
    return context;
  }

  const optimization = payload.optimization as OptimizationStats;
  return `${context}\n\n---\nchars: ${optimization.charsBefore} -> ${optimization.charsAfter}\ntokens_est: ${optimization.estimatedTokensBefore} -> ${optimization.estimatedTokensAfter}\nblocks: ${optimization.blockCountBefore} -> ${optimization.blockCountAfter}\ntruncated: ${optimization.truncated}`;
}

function renderPayload(payload: Record<string, unknown>, command: string, options: CliOptions): string {
  if (options.json) {
    return JSON.stringify(payload, null, 2);
  }

  if (command === "search" || command === "s") {
    return renderSearchText(payload);
  }

  return renderContextText(payload, options.stats);
}

function formatErrorPayload(error: unknown): { error: string } {
  return {
    error: error instanceof Error ? error.message : String(error),
  };
}

export async function runCli(argv = process.argv.slice(2)): Promise<number> {
  try {
    const parsed = parseCliArgs(argv);

    if (!parsed.command || parsed.command === "help") {
      printHelp();
      return 0;
    }

    if (!parsed.target || !parsed.query) {
      throw new Error("Missing arguments. Usage: <command> <target> <query>");
    }

    const apiKey = loadApiKey();

    let payload: Record<string, unknown>;
    if (parsed.command === "search" || parsed.command === "s") {
      payload = await searchLibraries(apiKey, parsed.target, parsed.query, parsed.options);
    } else if (parsed.command === "context" || parsed.command === "c") {
      payload = await getContext(apiKey, parsed.target, parsed.query, parsed.options);
    } else if (parsed.command === "ask" || parsed.command === "a") {
      payload = await askContext(apiKey, parsed.target, parsed.query, parsed.options);
    } else {
      throw new Error(`Unknown command: ${parsed.command}`);
    }

    console.log(renderPayload(payload, parsed.command, parsed.options));
    return 0;
  } catch (error) {
    if (argv.includes("--json") || argv.includes("-j")) {
      console.log(JSON.stringify(formatErrorPayload(error), null, 2));
      return 1;
    }

    const message = error instanceof Error ? error.message : String(error);
    console.error(`Error: ${message}`);
    return 1;
  }
}

const entrypoint = process.argv[1] ? fileURLToPath(import.meta.url) === process.argv[1] : false;
if (entrypoint) {
  const exitCode = await runCli();
  process.exit(exitCode);
}
