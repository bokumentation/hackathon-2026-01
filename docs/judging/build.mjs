import { readFileSync, writeFileSync, readdirSync } from "node:fs";
import { dirname, join, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { marked } from "marked";

const dir = dirname(fileURLToPath(import.meta.url));

const files = readdirSync(dir).filter((f) => f.endsWith(".md") && !f.startsWith("."));

for (const file of files) {
  const md = readFileSync(join(dir, file), "utf8");
  const body = marked.parse(md);
  const base = basename(file, ".md");
  const html = `<!doctype html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${base}</title>
<link rel="stylesheet" href="../proposal/proposal.css">
</head>
<body>
<main class="doc">
${body}
</main>
</body>
</html>
`;
  writeFileSync(join(dir, base + ".html"), html);
  console.log("wrote " + base + ".html");
}
