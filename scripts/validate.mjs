import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { build } from "esbuild";
import { compile } from "sass";
import words from "../javascripts/discourse/lib/moaclab-typing-words.js";
import { completedRowAt, speedMilestone, tokenIndexAtOffset, visibleRows, wordWindow } from "../javascripts/discourse/lib/moaclab-typing-layout.js";

assert.equal(visibleRows(568, 80, 16), 6);
assert.equal(visibleRows(350, 80, 16), 3);
assert.equal(visibleRows(80, 80, 16), 1);
assert.equal(visibleRows(0, 80, 16), 1);
assert.equal(visibleRows(2000, 80, 16), 6);
assert.equal(visibleRows(492, 72, 12), 6);
assert.equal(visibleRows(491, 72, 12), 5);
assert.equal(visibleRows(240, 72, 12), 3);
const lengths = Array(30).fill(5);
assert.deepEqual(wordWindow(lengths, 0, 4, 3), { start: 0, end: 12 });
assert.deepEqual(wordWindow(lengths, 71, 4, 3), { start: 0, end: 12 });
assert.deepEqual(wordWindow(lengths, 72, 4, 3), { start: 12, end: 24 });
assert.deepEqual(wordWindow(lengths, 71, 2, 2), { start: 8, end: 12 });
assert.deepEqual(wordWindow(lengths, 179, 4, 3), { start: 24, end: 30 });
assert.equal(speedMilestone(160, 2900), 0);
assert.equal(speedMilestone(89, 3000), 60);
assert.equal(speedMilestone(210, 4000), 180);
assert.equal(tokenIndexAtOffset([2, 4, 3], 0), 0);
assert.equal(tokenIndexAtOffset([2, 4, 3], 2), 0);
assert.equal(tokenIndexAtOffset([2, 4, 3], 3), 1);
assert.deepEqual(completedRowAt([2, 4, 3, 5], 7, 2), { start: 0, end: 2, key: "2:0:2" });
assert.deepEqual(completedRowAt([2, 4, 3, 5], 17, 2), { start: 2, end: 4, key: "2:2:4" });
assert.equal(completedRowAt([2, 4, 3, 5], 8, 2), null);

const about = JSON.parse(await readFile(new URL("../about.json", import.meta.url)));
assert.equal(about.component, true);
assert.equal(words.length, 3000);
assert.equal(new Set(words.map(([word]) => word)).size, words.length);
assert(words.every(([word, pinyin]) => word && /^[a-zv]+$/.test(pinyin)));

compile("common/common.scss");
await build({
  entryPoints: ["javascripts/discourse/api-initializers/moaclab-typing.gjs"],
  loader: { ".gjs": "js" },
  bundle: true,
  external: ["discourse/lib/api"],
  write: false,
});
console.log(`Moaclab Typing ${about.theme_version}: metadata, vocabulary, CSS and JavaScript checks passed.`);
