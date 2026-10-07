import pptxgen from "pptxgenjs";
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const cover = JSON.parse(
  readFileSync(join(dirname(fileURLToPath(import.meta.url)), "..", "proposal", "cover.json"), "utf8")
).id;

const ACCENT = "C2410C";
const INK = "111827";
const GRAY = "6B7280";
const LIGHT = "F1F5F9";
const RED = "B91C1C";
const LINE = "E5E7EB";

const BRAND = cover.brand;
const TAGLINE = cover.subtitle;

const pptx = new pptxgen();
pptx.layout = "LAYOUT_16x9";
pptx.author = "Tri Arga";
pptx.company = "Universitas Telkom";
pptx.title = `${BRAND} - Video Demo PERURI Chip Hackathon 2026`;

const TOTAL = 11;
let pageNo = 0;

function footer(slide) {
  slide.addText(`${BRAND}  |  PERURI Chip Hackathon 2026  |  Universitas Telkom`, {
    x: 0.55, y: 5.2, w: 7.5, h: 0.3, fontSize: 8.5, color: GRAY, fontFace: "Arial",
  });
  slide.addText(`${pageNo} / ${TOTAL}`, {
    x: 8.9, y: 5.2, w: 0.7, h: 0.3, fontSize: 8.5, color: GRAY, align: "right", fontFace: "Arial",
  });
}

function contentSlide(title, notes) {
  pageNo += 1;
  const s = pptx.addSlide();
  s.background = { color: "FFFFFF" };
  s.addShape(pptx.ShapeType.rect, { x: 0, y: 0, w: 0.16, h: 5.625, fill: { color: ACCENT } });
  s.addText(title, {
    x: 0.55, y: 0.28, w: 8.9, h: 0.62, fontSize: 24, bold: true, color: INK, fontFace: "Arial",
  });
  s.addShape(pptx.ShapeType.line, {
    x: 0.55, y: 0.96, w: 8.9, h: 0, line: { color: LINE, width: 1 },
  });
  if (notes) s.addNotes(notes);
  footer(s);
  return s;
}

function bulletList(items, opts = {}) {
  return items.map((t) => ({
    text: t,
    options: {
      bullet: true,
      color: opts.color || INK,
      fontSize: opts.fontSize || 15,
      breakLine: true,
      paraSpaceAfter: opts.paraSpaceAfter ?? 6,
    },
  }));
}

function table(rows) {
  const head = rows[0].map((c) => ({
    text: c, options: { bold: true, fill: { color: LIGHT }, color: INK },
  }));
  const body = rows.slice(1).map((r) => r.map((c) => ({ text: c, options: { color: INK } })));
  return [...[head], ...body];
}

function flowBox(slide, y, text, fill) {
  slide.addShape(pptx.ShapeType.roundRect, {
    x: 1.55, y, w: 6.9, h: 0.55, rectRadius: 0.06,
    fill: { color: fill }, line: { color: "CBD5E1", width: 1 },
  });
  slide.addText(text, {
    x: 1.55, y, w: 6.9, h: 0.55, fontSize: 13, color: INK, align: "center", valign: "middle", fontFace: "Arial",
  });
}

function flowArrow(slide, y) {
  slide.addText("\u25BC", {
    x: 4.75, y, w: 0.5, h: 0.2, fontSize: 10, color: GRAY, align: "center", valign: "middle", fontFace: "Arial",
  });
}

/* ---------------- 1. Title ---------------- */
{
  pageNo += 1;
  const s = pptx.addSlide();
  s.background = { color: "FFFFFF" };
  s.addShape(pptx.ShapeType.rect, { x: 0, y: 0, w: 10, h: 0.22, fill: { color: ACCENT } });
  s.addText(cover.event, {
    x: 0.7, y: 0.85, w: 8.6, h: 0.4, fontSize: 14, bold: true, color: ACCENT, charSpacing: 2, fontFace: "Arial",
  });
  s.addText(BRAND, {
    x: 0.7, y: 1.3, w: 8.6, h: 1.1, fontSize: 54, bold: true, color: INK, fontFace: "Arial",
  });
  s.addText(TAGLINE, {
    x: 0.72, y: 2.45, w: 8.2, h: 0.7, fontSize: 17, color: GRAY, fontFace: "Arial",
  });
  const teamLines = cover.members.map((m) => ({
    text: `${m.role}: ${m.name} - ${m.institution}`,
    options: { color: GRAY, fontSize: 12, breakLine: true },
  }));
  teamLines.push({ text: `${cover.advisorLabel}: ${cover.advisor}`, options: { color: GRAY, fontSize: 12 } });
  s.addText(
    [
      { text: "Area Fokus 04 - Secure Communication", options: { bold: true, color: INK, fontSize: 13, breakLine: true } },
      ...teamLines,
    ],
    { x: 0.72, y: 3.4, w: 8.2, h: 1.4, fontFace: "Arial" }
  );
  s.addNotes(
    "[0:00-0:10] Kami tim Tri Arga dari Universitas Telkom. TRI-ARGA adalah gerbang ingress berbasis hardware yang memastikan host hanya melihat frame yang terautentikasi dan segar, pada area fokus 04 Secure Communication."
  );
}

/* ---------------- 2. Problem ---------------- */
{
  const s = contentSlide(
    "Masalah",
    "[0:10-0:35] Penerima serial dan RF ringan memparsing bitstream tak tepercaya tanpa autentikasi. Tiga kelas kegagalan: integritas tak divalidasi, replay, dan commit tak atomik. Akibatnya frame korup, palsu, atau lama tetap tampak sah bagi host. Verifikasi di software berjalan setelah data melewati batas kepercayaan."
  );
  s.addText(
    bulletList([
      "Penerima serial/RF ringan memparsing bitstream tak tepercaya langsung ke register, tanpa memeriksa integritas.",
      "Integritas tidak divalidasi: CRC/ECC tanpa kunci dapat dihitung ulang penyerang (CWE-354, CWE-345).",
      "Replay: frame lama yang sah dapat diputar ulang tanpa penanda kesegaran (CWE-294).",
      "Commit tidak atomik dan FSM rapuh: data dan kendali dapat terlepas (CWE-1264, CWE-1245).",
    ]),
    { x: 0.7, y: 1.2, w: 8.6, h: 3.9, fontFace: "Arial", valign: "top" }
  );
}

/* ---------------- 3. Baseline evidence ---------------- */
{
  const s = contentSlide(
    "Bukti pada Baseline tt07-bep-decode",
    "[0:35-1:00] Baseline Manchester Tiny Tapeout 07 menerima field integritas 24 bit dan tidak pernah memeriksanya. Simulasi kami menunjukkan payload korup dan field korup tetap di-latch dengan full sama dengan satu, yaitu CWE-354 yang terukur. Field-nya belum dipecahkan, jadi kasus RF ini bukti kelas kerentanan, bukan jalur integritas kami."
  );
  s.addText(
    bulletList([
      "Decoder Manchester Tiny Tapeout 07 (`tt07-bep-decode`), contoh pola penerima ringan.",
      "Field integritas 24 bit diterima dan diteruskan ke host tanpa pemeriksaan.",
      "Terukur: payload korup dan field korup tetap di-latch dengan `full=1` (CWE-354).",
    ], { fontSize: 13 }),
    { x: 0.7, y: 1.25, w: 5.2, h: 3.6, fontFace: "Arial", valign: "top" }
  );
  s.addImage({
    path: "assets/sim-baseline-vulnerability.png",
    x: 6.05, y: 1.35, w: 3.35, h: 3.3,
    sizing: { type: "contain", w: 3.35, h: 3.3 },
  });
}

/* ---------------- 4. Solution & architecture ---------------- */
{
  const s = contentSlide(
    "Solusi: TRI-ARGA, Tiga Lapis",
    "[1:00-1:30] TRI-ARGA duduk di antara front-end yang tak tepercaya dan host. Tiga lapis: L1 pemuat key dan frame, L2 autentikasi dengan CBC-MAC dan pemeriksaan kesegaran, dan L3 commit atomik fail-closed. Kunci masuk dari host lewat jalur terpisah dan tidak pernah melewati tautan. Transport dapat diganti; Tier B menambahkan tautan serial 8b/10b dengan word lock."
  );
  s.addText("L1 Arga Kunci (pemuat), L2 Arga Auth (CBC-MAC + kesegaran), L3 Arga Commit (fail-closed). Kunci dari host lewat jalur terpisah.", {
    x: 0.7, y: 1.1, w: 8.6, h: 0.75, fontSize: 13.5, color: INK, fontFace: "Arial",
  });
  s.addImage({
    path: "assets/block-diagram.png",
    x: 1.9, y: 1.95, w: 6.2, h: 3.0,
    sizing: { type: "contain", w: 6.2, h: 3.0 },
  });
}

/* ---------------- 5. Workflow ---------------- */
{
  const s = contentSlide(
    "Alur Kerja",
    "[1:30-2:05] Ini alur kerja dari kunci sampai data terlihat host. Pertama host memuat kunci 64 bit sekali, bersifat write-once. Lalu frame 128 bit digeser: counter, payload, dan tag. L1 memvalidasi batas frame dan menaikkan framing_ok. L2 menghitung CBC-MAC dan membandingkan tag, lalu memeriksa counter harus naik. Jika autentikasi dan kesegaran lulus, L3 melepas data dan host_full bersamaan. Jika gagal, host_full tetap rendah dan fault menyala lengket sampai di-acknowledge."
  );
  const boxes = [
    "Host memuat kunci 64 bit (write-once)",
    "Frame 128 bit digeser: counter + payload + tag",
    "L1: framing_ok, batas frame tervalidasi",
    "L2: CBC-MAC cocok + counter naik",
    "L3: commit atomik -> host_full; gagal -> fault lengket",
  ];
  const ys = [1.05, 1.72, 2.39, 3.06, 3.73];
  boxes.forEach((t, i) => {
    flowBox(s, ys[i], t, i === 4 ? "FEF3C7" : LIGHT);
    if (i < boxes.length - 1) flowArrow(s, ys[i] + 0.57);
  });
  s.addText("Jalur tolak: tag salah, counter basi, atau framing rusak -> host_full rendah + fault lengket.", {
    x: 0.7, y: 4.5, w: 8.6, h: 0.5, fontSize: 11.5, color: RED, italic: true, fontFace: "Arial",
  });
}

/* ---------------- 6. Auth & freshness ---------------- */
{
  const s = contentSlide(
    "Autentikasi & Kesegaran",
    "[2:05-2:35] L2 memakai SIMON-32/64 sebagai CBC-MAC panjang tetap atas tiga blok, dengan tag 32 bit dan IV nol. Tag hasil hitung dibandingkan dengan tag yang diterima. Counter harus lebih besar dari yang terakhir diterima, sehingga replay dan counter basi ditolak. Kami jujur soal batas: peluang forgery sekitar dua pangkat minus tiga puluh dua, dan CBC-MAC hanya aman untuk panjang tetap, jadi kunci disarankan dirotasi."
  );
  s.addText(
    bulletList([
      "SIMON-32/64 terserialisasi, satu ronde per siklus; 33 siklus per blok.",
      "CBC-MAC panjang tetap atas tiga blok, IV = 0, tag 32 bit.",
      "Tag hasil hitung dibandingkan dengan tag yang diterima.",
      "Counter harus naik ketat; replay dan counter basi ditolak (CWE-294).",
    ], { fontSize: 14 }),
    { x: 0.7, y: 1.15, w: 4.9, h: 3.6, fontFace: "Arial", valign: "top" }
  );
  s.addImage({
    path: "assets/frame-link.png",
    x: 5.75, y: 1.35, w: 3.65, h: 2.7,
    sizing: { type: "contain", w: 3.65, h: 2.7 },
  });
  s.addText("Tag 32 bit: peluang forgery sekitar 2^-32 per percobaan.", {
    x: 0.7, y: 4.5, w: 8.6, h: 0.5, fontSize: 11.5, color: RED, italic: true, fontFace: "Arial",
  });
}

/* ---------------- 7. Reject cases ---------------- */
{
  const s = contentSlide(
    "Kasus Tolak: Forgery, Replay, Line Error",
    "[2:35-3:05] Ini hasil simulasi yang menunjukkan fungsionalitas fail-closed. Frame bersih dikomit: host_full naik. Sebaliknya, tiga kasus ditolak. Forgery, saat payload diubah tetapi tag lama, membuat auth_ok rendah. Replay, saat counter sama, membuat fresh_ok rendah. Line error pada tautan serial memicu fault. Pada semua kasus gagal, host_full tetap rendah dan fault menyala lengket sampai di-acknowledge."
  );
  s.addText(
    bulletList([
      "Bersih: `host_full=1`, data tercommit.",
      "Forgery (payload diubah, tag lama): `auth_ok=0`, `fault=1`.",
      "Replay (counter sama): `fresh_ok=0`, `fault=1`.",
      "Line error (bit tautan rusak): fault pada tautan.",
      "Fault lengket sampai `fault_ack`.",
    ], { fontSize: 12.5 }),
    { x: 0.7, y: 1.2, w: 4.7, h: 3.8, fontFace: "Arial", valign: "top" }
  );
  s.addImage({
    path: "assets/sim-auth-commit.png",
    x: 5.55, y: 1.4, w: 3.85, h: 3.0,
    sizing: { type: "contain", w: 3.85, h: 3.0 },
  });
}

/* ---------------- 8. Verification ---------------- */
{
  const s = contentSlide(
    "Verifikasi & Bukti",
    "[3:05-3:30] Kami memverifikasi dengan tiga cara. Simulasi cocotb mencakup suite simon, l2, auth, wrapper, link-codec, link-framing, dan link-top. Fault injection menolak 128 dari 128 single-bit flip, dengan false reject nol dari dua puluh frame bersih. Properti formal SymbiYosys: sembilan job lolos, yaitu lima inti, satu Tier B, dan tiga lampiran RF. Angka yang kami laporkan hanya yang terukur."
  );
  s.addText(
    bulletList([
      "Simulasi cocotb: suite simon, l2, auth, wrapper, link-codec, link-framing, link-top lolos.",
      "Fault injection: 128/128 single-bit flip ditolak; false reject 0 dari 20 frame bersih.",
      "Formal SymbiYosys: 9 job lolos (5 inti, 1 Tier B, 3 lampiran RF).",
    ], { fontSize: 13.5 }),
    { x: 0.7, y: 1.25, w: 8.6, h: 3.8, fontFace: "Arial", valign: "top" }
  );
}

/* ---------------- 9. Measured results ---------------- */
{
  const s = contentSlide(
    "Hasil Terukur",
    "[3:30-3:55] Ringkasan hasil. Simulasi: 128 dari 128 bit flip ditolak, false reject nol, dan latensi 108 siklus. Formal: sembilan job lolos. Hardening sky130 inti: tile dua kali dua, 0,0756 milimeter persegi, 2511 sel, tanpa DRC, LVS, atau antena, dan 2,10 miliwatt. Tautan Tier B: 3220 sel dan 3,61 miliwatt. FPGA DE10-Nano: 421 ALM, 1029 flip-flop, Fmax 97,9 megahertz."
  );
  s.addTable(
    table([
      ["Aspek", "Hasil"],
      ["Simulasi", "128/128 bit flip ditolak; false reject 0; 108 siklus ujung ke ujung"],
      ["Loopback Tier B", "frame bersih dikomit; forgery, replay, dan line error ditolak"],
      ["Formal", "9 job lolos (5 inti, 1 Tier B, 3 lampiran RF)"],
      ["ASIC sky130 (inti)", "2x2, 0,0756 mm^2, 2511 sel, 0 DRC/LVS/antena, 2,10 mW"],
      ["ASIC sky130 (Tier B)", "2x2, 3220 sel, 2 pelanggaran antena, 3,61 mW"],
      ["FPGA DE10-Nano", "421 ALM, 1029 FF, 0 M10K, 0 DSP, Fmax 97,9 MHz"],
    ]),
    {
      x: 0.7, y: 1.2, w: 8.6, colW: [2.4, 6.2], fontSize: 11.5,
      border: { type: "solid", color: "CBD5E1", pt: 1 }, align: "left", valign: "middle",
      fontFace: "Arial", rowH: 0.56, autoPage: false,
    }
  );
}

/* ---------------- 10. Outputs & repository ---------------- */
{
  const s = contentSlide(
    "Luaran dan Repositori",
    "[3:55-4:10] Luaran yang kami serahkan: sumber RTL inti Tier A dan tautan Tier B, suite testbench cocotb, sembilan properti formal, hasil hardening sky130 beserta laporan DRC, LVS, timing, dan daya, bitstream FPGA beserta demo on-board di bootcamp, serta dokumen teknis dan repositori sumber."
  );
  s.addTable(
    table([
      ["Luaran", "Isi"],
      ["Sumber RTL", "`src/` inti Tier A dan tautan Tier B (8b/10b)"],
      ["Testbench", "Suite cocotb: simon, l2, auth, wrapper, link-codec, link-framing, link-top"],
      ["Formal", "9 job SymbiYosys lolos"],
      ["ASIC", "GDS sky130 dan laporan DRC/LVS/timing/daya"],
      ["FPGA", "Bitstream (.sof) dan demo on-board (bootcamp)"],
      ["Dokumen", "Proposal, laporan teknis (quartus-report, area), dan repositori sumber"],
    ]),
    {
      x: 0.7, y: 1.2, w: 8.6, colW: [2.0, 6.6], fontSize: 12.5,
      border: { type: "solid", color: "CBD5E1", pt: 1 }, align: "left", valign: "middle",
      fontFace: "Arial", rowH: 0.6, autoPage: false,
    }
  );
}

/* ---------------- 11. Closing ---------------- */
{
  const s = contentSlide(
    "Terima Kasih",
    "[4:10-4:15] Demikian TRI-ARGA: gerbang ingress yang autentik, anti-replay, dan fail-closed, dengan tautan serial Tier B. Terima kasih."
  );
  s.addText(BRAND, {
    x: 0.7, y: 2.0, w: 8.6, h: 0.9, fontSize: 40, bold: true, color: ACCENT, fontFace: "Arial",
  });
  s.addText("Autentik, anti-replay, dan fail-closed; tautan serial 8b/10b (Tier B).", {
    x: 0.72, y: 2.95, w: 8.6, h: 0.5, fontSize: 16, color: GRAY, fontFace: "Arial",
  });
  s.addText(`${cover.members[0].name}  \u00B7  ${cover.members[1].name}  \u00B7  Universitas Telkom`, {
    x: 0.72, y: 3.5, w: 8.6, h: 0.5, fontSize: 13, color: INK, fontFace: "Arial",
  });
}

const outDir = process.env.DECK_OUT_DIR || ".";
const base = process.env.DECK_BASE || "tri-arga-deck";
const outPath = join(outDir, `${base}.pptx`);
await pptx.writeFile({ fileName: outPath });
console.log(`wrote ${outPath} (${pageNo} slides)`);
