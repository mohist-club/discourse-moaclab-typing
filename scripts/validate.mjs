import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { build } from "esbuild";
import { compile } from "sass";
import words from "../javascripts/discourse/lib/moaclab-typing-words.js";

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
