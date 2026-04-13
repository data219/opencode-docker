import test from "node:test";
import assert from "node:assert/strict";

import { loadQueriesFromString } from "./benchmark.ts";

test("loadQueriesFromString requires pinned libraryId for each benchmark entry", () => {
  assert.throws(
    () => loadQueriesFromString(JSON.stringify([
      {
        label: "Missing library ID",
        target: "symfony",
        query: "voter docs",
      },
    ])),
    /libraryId/,
  );
});
