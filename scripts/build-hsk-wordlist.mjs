import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const sourcePath = process.argv[2];
const outputPath = process.argv[3] || fileURLToPath(new URL(
  "../javascripts/discourse/lib/moaclab-typing-words.js", import.meta.url
));

if (!sourcePath) {
  throw new Error("Usage: node build-hsk-wordlist.mjs <complete.min.json> [output.js]");
}

const source = JSON.parse(fs.readFileSync(sourcePath, "utf8"));
const excludedPartsOfSpeech = new Set(["nr", "ns", "nt", "nz", "w", "x"]);
const seen = new Set();

const rows = source
  .map((entry) => {
    const word = entry.s || "";
    const numeric = entry.f?.[0]?.i?.n || "";
    const pinyin = numeric
      .toLowerCase()
      .replaceAll("ü", "v")
      .replaceAll("u:", "v")
      .replace(/[1-5\s·’'’-]/g, "");
    const levels = (entry.l || [])
      .map((value) => Number(String(value).replace(/\D/g, "")))
      .filter(Boolean);

    return [
      word,
      pinyin,
      Math.min(...levels, 9),
      Number(entry.q) || 999999,
      entry.p || [],
    ];
  })
  .filter(([word, pinyin, , frequency, partsOfSpeech]) =>
    /^[\u3400-\u9fff]{2,4}$/.test(word) &&
    /^[a-zv]+$/.test(pinyin) &&
    frequency < 999999 &&
    !partsOfSpeech.some((part) => excludedPartsOfSpeech.has(part)) &&
    !seen.has(word) &&
    seen.add(word)
  )
  .sort((a, b) => a[3] - b[3])
  .slice(0, 3000)
  .map(([word, pinyin, level]) => [word, pinyin, level]);

const output = [
  "// Generated from drkameleon/complete-hsk-vocabulary (MIT).",
  "// Source snapshot: 2026-08-20. Do not edit by hand.",
  `export default ${JSON.stringify(rows)};`,
  "",
].join("\n");

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, output);

console.log(JSON.stringify({ count: rows.length, bytes: Buffer.byteLength(output) }));
