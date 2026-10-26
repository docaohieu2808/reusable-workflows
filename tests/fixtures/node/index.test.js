const { test } = require("node:test");
const assert = require("node:assert");
const { add } = require("./index.js");

test("adds two numbers", () => assert.strictEqual(add(2, 3), 5));

// The self-test sets FIXTURE_FAIL=1 to prove that a failing test turns the pipeline red.
test("fails on request", () => assert.notStrictEqual(process.env.FIXTURE_FAIL, "1"));
