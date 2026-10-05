import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { marked } from "marked";

const dir = dirname(fileURLToPath(import.meta.url));

const figure =
  '<figure><img src="assets/block-diagram.svg" alt="SALARAS-RX system block diagram">' +
  "<figcaption>SALARAS-RX system block diagram</figcaption></figure>";

const docs = [
  {
    in: "salaras-rx-proposal.id.md",
    out: "salaras-rx-proposal.id.html",
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
        ["Dosen Pembimbing", "Dr. Setia Jul Ismail, S.T., M.T."],
        ["Berkas", "docs/proposal/salaras-rx-proposal.id.md"],
      ],
      footer: "Proposal peserta - kurasi tahap pertama",
    },
  },
  {
    in: "salaras-rx-proposal.en.md",
    out: "salaras-rx-proposal.en.html",
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
        ["Advisor", "Dr. Setia Jul Ismail, S.T., M.T."],
        ["Source", "docs/proposal/salaras-rx-proposal.en.md"],
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

  writeFileSync(join(dir, doc.out), html);
  console.log(`wrote ${doc.out}`);
}
