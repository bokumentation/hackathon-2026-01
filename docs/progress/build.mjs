import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join, isAbsolute } from "node:path";
import { fileURLToPath } from "node:url";
import { marked } from "marked";

const dir = dirname(fileURLToPath(import.meta.url));

const ts = process.env.PROGRESS_TS;
if (!ts) {
  console.error("PROGRESS_TS is required (set by build.sh)");
  process.exit(1);
}

const htmlDir = process.env.PROGRESS_HTML_DIR || dir;
mkdirSync(htmlDir, { recursive: true });

const base = `PROGRESS-TRIARGA-${ts}`;

const coverFile = process.env.COVER_FILE || join(dir, "cover.json");
const covers = JSON.parse(readFileSync(coverFile, "utf8"));

function esc(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

marked.setOptions({ gfm: true, breaks: false });

const doc = {
  in: "progress-report.md",
  out: `${base}.html`,
  lang: "en",
  title: "TRI-ARGA - Progress Report",
  cover: covers.en,
};

let md = readFileSync(join(dir, doc.in), "utf8");
md = md.replace(/^#\s.*\n/, "");
const body = marked.parse(md);

const c = doc.cover;

const html = `<!doctype html>
<html lang="${doc.lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(doc.title)}</title>
<link rel="stylesheet" href="progress.css">
</head>
<body>
<section class="cover">
  <div class="cover-top">${esc(c.event)}</div>
  <div class="cover-cat">${esc(c.categoryLabel)}: ${esc(c.category)}</div>
  <div class="cover-hero">
    <h1 class="cover-title">${esc(c.brand)}</h1>
    <p class="cover-sub">${esc(c.title)}</p>
    <p class="cover-sub">${esc(c.subtitle)}</p>
  </div>
</section>
<main class="doc">
${body}
</main>
</body>
</html>
`;

const outPath = isAbsolute(doc.out) ? doc.out : join(htmlDir, doc.out);
writeFileSync(outPath, html);
console.log(`wrote ${outPath}`);
