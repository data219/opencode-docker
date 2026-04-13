import test from "node:test";
import assert from "node:assert/strict";

import {
  DEFAULT_MAX_CHARS,
  DEFAULT_MAX_SECTIONS,
  parseCliArgs,
  resolveLibraryMatch,
  runCli,
  optimizeContextText,
} from "./query.ts";

const sampleContext = `
# Example Library

## Authentication

Use the auth middleware to validate JWT tokens on every request.

\`\`\`ts
app.use(authenticateJwt());
\`\`\`

## Caching

Use cache tags to invalidate responses after writes.

\`\`\`ts
await cache.invalidate("users");
\`\`\`

## Deployment

Deploy with the bundled CLI after building production assets.

\`\`\`bash
example deploy --prod
\`\`\`
`.trim();

test("optimizeContextText prioritizes relevant sections", () => {
  const result = optimizeContextText(sampleContext, "How do I validate JWT auth middleware?", {
    maxChars: DEFAULT_MAX_CHARS,
    maxSections: 3,
  });

  assert.match(result.text, /Authentication/);
  assert.match(result.text, /authenticateJwt/);
  assert.doesNotMatch(result.text, /example deploy --prod/);
  assert.equal(result.stats.blockCountAfter <= result.stats.blockCountBefore, true);
});

test("optimizeContextText enforces maxChars and marks truncation", () => {
  const longContext = `${sampleContext}\n\n${sampleContext}\n\n${sampleContext}`;
  const result = optimizeContextText(longContext, "cache invalidation", {
    maxChars: 180,
    maxSections: DEFAULT_MAX_SECTIONS,
  });

  assert.equal(result.text.length <= 180, true);
  assert.equal(result.stats.truncated, true);
  assert.match(result.text, /\.\.\.$/);
});

test("parseCliArgs parses token optimization flags", () => {
  const parsed = parseCliArgs([
    "ask",
    "symfony",
    "security voter",
    "--json",
    "--max-chars",
    "5000",
    "--max-sections",
    "6",
  ]);

  assert.equal(parsed.command, "ask");
  assert.equal(parsed.target, "symfony");
  assert.equal(parsed.query, "security voter");
  assert.equal(parsed.options.json, true);
  assert.equal(parsed.options.maxChars, 5000);
  assert.equal(parsed.options.maxSections, 6);
});

test("resolveLibraryMatch rejects ambiguous top matches without an exact target match", () => {
  assert.throws(
    () => resolveLibraryMatch("next", [
      {
        id: "/websites/nextjs",
        title: "Next.js",
        trustScore: 10,
      },
      {
        id: "/other/next-auth",
        title: "Next Auth",
        trustScore: 9,
      },
    ]),
    /Ambiguous Context7 library match/,
  );
});

test("runCli returns JSON-formatted errors in --json mode", async () => {
  const originalKey = process.env.CONTEXT7_API_KEY;
  delete process.env.CONTEXT7_API_KEY;

  const stdout: string[] = [];
  const stderr: string[] = [];
  const originalLog = console.log;
  const originalError = console.error;
  console.log = (message?: unknown) => {
    stdout.push(String(message ?? ""));
  };
  console.error = (message?: unknown) => {
    stderr.push(String(message ?? ""));
  };

  try {
    const exitCode = await runCli(["search", "symfony", "voter", "--json"]);

    assert.equal(exitCode, 1);
    assert.equal(stderr.length, 0);
    assert.equal(stdout.length, 1);

    const payload = JSON.parse(stdout[0]);
    assert.equal(payload.error, "CONTEXT7_API_KEY not found. Set it in the environment or in .env.");
  } finally {
    console.log = originalLog;
    console.error = originalError;
    if (originalKey) {
      process.env.CONTEXT7_API_KEY = originalKey;
    }
  }
});
