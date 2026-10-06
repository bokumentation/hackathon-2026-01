import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join, isAbsolute } from "node:path";
import { fileURLToPath } from "node:url";
import { marked } from "marked";

const dir = dirname(fileURLToPath(import.meta.url));

const ts = process.env.PROPOSAL_TS;
if (!ts) {
  console.error("PROPOSAL_TS is required (set by build.sh)");
  process.exit(1);
}

const htmlDir = process.env.PROPOSAL_HTML_DIR || dir;
mkdirSync(htmlDir, { recursive: true });

const base = `PROPOSAL-SALARAS-${ts}`;

const figure =
  '<figure><img src="assets/block-diagram.svg" alt="SALARAS system block diagram">' +
  "<figcaption>SALARAS system block diagram</figcaption></figure>";

const docs = [
  {
    in: "proposal-salaras.id.md",
    out: `${base}.id.html`,
    lang: "id",
    title: "Authenticated Fail-Closed Ingress Boundary - Proposal PERURI Chip Hackathon 2026",
    cover: {
      eyebrow: "PERURI CHIP HACKATHON 2026",
      chip: "AUTHENTICATED INGRESS BOUNDARY",
      subtitle:
        "A Hardware-Enforced Secure Ingress Barrier for Manchester/RF Serial Links",
      rows: [
        ["Kategori", "IC Chip Design &amp; FPGA Implementation"],
        ["Area Fokus", "04 - Secure Communication (secure framing &amp; interface integrity)"],
        ["Tim", "dinotice - Universitas Telkom"],
        ["Ketua", "Ibrahim Fauzi Rahman"],
        ["Anggota", "Idris Syaifulloh"],
        ["Dosen Pembimbing", "Dr. Setia Juli Irzal Ismail, S.T., M.T."],
        ["Berkas", "docs/proposal/proposal-salaras.id.md"],
      ],
      footer: "Proposal peserta - kurasi tahap pertama",
    },
  },
  {
    in: "proposal-salaras.en.md",
    out: `${base}.en.html`,
    lang: "en",
    title: "Authenticated Fail-Closed Ingress Boundary - PERURI Chip Hackathon 2026 Proposal",
    cover: {
      eyebrow: "PERURI CHIP HACKATHON 2026",
      chip: "AUTHENTICATED INGRESS BOUNDARY",
      subtitle:
        "A Hardware-Enforced Secure Ingress Barrier for Manchester/RF Serial Links",
      rows: [
        ["Category", "IC Chip Design &amp; FPGA Implementation"],
        ["Focus Area", "04 - Secure Communication (secure framing &amp; interface integrity)"],
        ["Team", "dinotice - Universitas Telkom"],
        ["Lead", "Ibrahim Fauzi Rahman"],
        ["Member", "Idris Syaifulloh"],
        ["Advisor", "Dr. Setia Juli Irzal Ismail, S.T., M.T."],
        ["Source", "docs/proposal/proposal-salaras.en.md"],
      ],
      footer: "Participant proposal - first curation stage",
    },
  },
];

function renderCover(c) {
  const rows = c.rows
    .map(([k, v]) => `<div class="c-k">${k}</div><div class="c-v">${v}</div>`)
    .join("\n");
  return `<section class="cover">
  <div class="cover-top">${c.eyebrow}</div>
  <div class="cover-mid">
    <h1 class="cover-title">${c.chip}</h1>
    <p class="cover-sub">${c.subtitle}</p>
    <div class="cover-meta">
${rows}
    </div>
  </div>
  <div class="cover-foot">${c.footer}</div>
</section>`;
}

marked.setOptions({ gfm: true, breaks: false });

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
