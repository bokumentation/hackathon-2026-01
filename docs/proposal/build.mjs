import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join, isAbsolute } from "node:path";
import { fileURLToPath } from "node:url";
import { marked } from "marked";
import markedKatex from "marked-katex-extension";

const dir = dirname(fileURLToPath(import.meta.url));

const ts = process.env.PROPOSAL_TS;
if (!ts) {
  console.error("PROPOSAL_TS is required (set by build.sh)");
  process.exit(1);
}

const htmlDir = process.env.PROPOSAL_HTML_DIR || dir;
mkdirSync(htmlDir, { recursive: true });

const base = `PROPOSAL-TRIARGA-${ts}`;

const coverFile = process.env.COVER_FILE || join(dir, "cover.json");
const covers = JSON.parse(readFileSync(coverFile, "utf8"));

const figure =
  '<figure><img src="assets/block-diagram.svg" alt="TRI-ARGA system block diagram">' +
  "<figcaption>TRI-ARGA system block diagram</figcaption></figure>";

const docs = [
  {
    in: "proposal.id.md",
    out: `${base}.id.html`,
    lang: "id",
    title: "TRI-ARGA - Proposal PERURI Chip Hackathon 2026",
    cover: covers.id,
  },
  {
    in: "proposal.en.md",
    out: `${base}.en.html`,
    lang: "en",
    title: "TRI-ARGA - PERURI Chip Hackathon 2026 Proposal",
    cover: covers.en,
  },
];

function esc(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function emph(value) {
  return esc(value).replace(/_([^_\n]+)_/g, "<em>$1</em>");
}

function renderMembers(members) {
  return (members || [])
    .map((m) => {
      const detail = [m.institution, m.contact].filter(Boolean).join(" - ");
      const who = `${esc(m.name)}${detail ? " - " + esc(detail) : ""}`;
      return `<li><span class="m-role">${esc(m.role)}:</span> ${who}</li>`;
    })
    .join("\n      ");
}

function renderCover(c) {
  return `<section class="cover">
  <div class="cover-top">${esc(c.event)}</div>
  <div class="cover-cat">${esc(c.categoryLabel)}: ${esc(c.category)}</div>
  <div class="cover-hero">
    <h1 class="cover-title">${esc(c.brand)}</h1>
    <p class="cover-sub">${emph(c.subtitle)}</p>
  </div>
  <div class="cover-id">
    <div class="cover-id-h">${esc(c.idHeading)}</div>
    <dl class="cover-dl">
      <dt>${esc(c.chipLabel)}</dt>
      <dd>${emph(c.chip)}</dd>
      <dt>${esc(c.teamLabel)}</dt>
      <dd>${esc(c.team)}</dd>
      <dt>${esc(c.membersLabel)}</dt>
      <dd>
      <ul class="cover-members">
      ${renderMembers(c.members)}
      </ul>
      </dd>
      <dt>${esc(c.advisorLabel)}</dt>
      <dd>${esc(c.advisor)}</dd>
    </dl>
  </div>
</section>`;
}

marked.setOptions({ gfm: true, breaks: false });
marked.use(markedKatex({ throwOnError: false, output: "html", nonStandard: true }));

function boldSubheadings(md) {
  return md.replace(/^([A-Z][^\n*#|`]{2,60}:)\s*$/gm, (_, label) => `**${label}**`);
}

for (const doc of docs) {
  let md = readFileSync(join(dir, doc.in), "utf8");
  md = md.replace(/```mermaid[\s\S]*?```/g, `\n${figure}\n`);
  md = md.replace(/^#\s.*\n/, "");
  md = md.replace(/^(Kategori|Area Fokus|Category|Focus Area):.*\n/gm, "");
  md = md.replace(
    /^##\s+(Identitas Tim|Team Identity)\s*\n[\s\S]*?(?=\n##\s)/m,
    ""
  );
  md = boldSubheadings(md);
  const body = marked.parse(md);

  const html = `<!doctype html>
<html lang="${doc.lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${doc.title}</title>
<link rel="stylesheet" href="assets/katex/katex.min.css">
<link rel="stylesheet" href="proposal.css">
</head>
<body>
${renderCover(doc.cover)}
<main class="doc">
${body}
</main>
</body>
</html>
`;

  const outPath = isAbsolute(doc.out) ? doc.out : join(htmlDir, doc.out);
  writeFileSync(outPath, html);
  console.log(`wrote ${outPath}`);
}
