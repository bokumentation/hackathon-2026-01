import { readFileSync, writeFileSync, readdirSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { marked } from "marked";

const dir = dirname(fileURLToPath(import.meta.url));
const outDir = join(dir, "pdf");
mkdirSync(outDir, { recursive: true });

const all = readdirSync(dir).filter((f) => /^ideas-\d+.*\.md$/.test(f)).sort();
const combinedFiles = all.filter((f) => !/outline/i.test(f));
const outlineFiles = all.filter((f) => /outline/i.test(f));

function renderDoc(file) {
  const body = marked.parse(readFileSync(join(dir, file), "utf8"));
  return `<section class="idea-doc">${body}</section>`;
}

function page(files, title) {
  return `<!doctype html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
<link rel="stylesheet" href="../proposal/proposal.css">
<style>
.idea-doc + .idea-doc { break-before: page; }
</style>
</head>
<body>
<main class="doc">
${files.map(renderDoc).join("\n")}
</main>
</body>
</html>
`;
}

writeFileSync(
  join(dir, "ideas-combined.html"),
  page(combinedFiles, "Ide SALARAS-RX - Area 04 Secure Communication")
);
console.log("combined " + combinedFiles.length + " files: " + combinedFiles.join(", "));

if (outlineFiles.length) {
  writeFileSync(
    join(dir, "salaras-serdes-crc-outline.html"),
    page(outlineFiles, "Outline Proposal SALARAS-SERDES (CRC)")
  );
  console.log("standalone " + outlineFiles.length + " file: " + outlineFiles.join(", "));
}
