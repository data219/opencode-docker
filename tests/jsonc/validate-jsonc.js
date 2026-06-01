#!/usr/bin/env node

const fs = require("fs");
const { parse, printParseErrorCode } = require("jsonc-parser");

const file = process.argv[2];

if (!file) {
  console.error("usage: validate-jsonc.js <file>");
  process.exit(2);
}

let input;
try {
  input = fs.readFileSync(file, "utf8");
} catch (e) {
  console.error(`failed to read JSONC file: ${file}: ${e.message}`);
  process.exit(1);
}

const errors = [];

parse(input, errors);

if (errors.length > 0) {
  for (const error of errors) {
    console.error(`${file}:${error.offset}: ${printParseErrorCode(error.error)}`);
  }
  process.exit(1);
}
