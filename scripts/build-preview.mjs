import { mkdir, writeFile } from "node:fs/promises";
import { build } from "esbuild";
import { compile } from "sass";

await mkdir("output/preview", { recursive: true });
await build({
  entryPoints: ["javascripts/discourse/api-initializers/moaclab-typing.gjs"],
  loader: { ".gjs": "js" },
  bundle: true,
  outfile: "output/preview/typing.js",
  plugins: [{
    name: "preview-discourse-api",
    setup(builder) {
      builder.onResolve({ filter: /^discourse\/lib\/api$/ }, () => ({ path: "api", namespace: "preview" }));
      builder.onLoad({ filter: /.*/, namespace: "preview" }, () => ({
        contents: "export const apiInitializer = callback => callback({ onPageChange() {} });",
      }));
    },
  }],
});
await writeFile("output/preview/typing.css", compile("common/common.scss").css);
await writeFile("output/preview/index.html", `<!doctype html>
<html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Moaclab Typing Preview</title><link rel="stylesheet" href="/typing.css">
<style>
:root{--primary:#191a1c;--secondary:#fff;--tertiary:#008bbd;--primary-very-low:#f5f6f7;--header-offset:56px}
body{margin:0;font:14px system-ui;background:var(--secondary);color:var(--primary)}
header{height:56px;padding:0 24px;display:flex;align-items:center;border-bottom:1px solid #ddd}
#main-outlet-wrapper{margin-left:248px}body.collapsed #main-outlet-wrapper{margin-left:32px}
@media(max-width:700px){#main-outlet-wrapper{margin-left:0}}
</style>
<header>Moaclab Typing</header><div id="main-outlet-wrapper"><div id="main-outlet"></div></div>
<script src="/typing.js"></script></html>`);
