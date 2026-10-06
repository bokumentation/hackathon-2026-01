import pptxgen from "pptxgenjs";
import { join } from "node:path";

const ACCENT = "C2410C";
const INK = "111827";
const GRAY = "6B7280";
const LIGHT = "F1F5F9";
const GREEN = "166534";
const RED = "B91C1C";
const LINE = "E5E7EB";

const pptx = new pptxgen();
pptx.layout = "LAYOUT_16x9";
pptx.author = "dinotice";
pptx.company = "Universitas Telkom";
pptx.title = "SALARAS - PERURI Chip Hackathon 2026";

const TOTAL = 14;
let pageNo = 0;

function footer(slide) {
  slide.addText("SALARAS  |  PERURI Chip Hackathon 2026  |  dinotice", {
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
  const arr = items.map((t, i) => ({
    text: t,
    options: {
      bullet: true,
      color: opts.color || INK,
      fontSize: opts.fontSize || 15,
      breakLine: true,
      paraSpaceAfter: opts.paraSpaceAfter ?? 6,
    },
  }));
  return arr;
}

function table(rows, opts = {}) {
  const head = rows[0].map((c) => ({
    text: c, options: { bold: true, fill: { color: LIGHT }, color: INK },
  }));
  const body = rows.slice(1).map((r) => r.map((c) => ({ text: c, options: { color: INK } })));
  return [...[head], ...body];
}

/* ---------------- 1. Title ---------------- */
{
  pageNo += 1;
  const s = pptx.addSlide();
  s.background = { color: "FFFFFF" };
  s.addShape(pptx.ShapeType.rect, { x: 0, y: 0, w: 10, h: 0.22, fill: { color: ACCENT } });
  s.addText("PERURI CHIP HACKATHON 2026", {
    x: 0.7, y: 0.85, w: 8.6, h: 0.4, fontSize: 14, bold: true, color: ACCENT, charSpacing: 2, fontFace: "Arial",
  });
  s.addText("SALARAS", {
    x: 0.7, y: 1.35, w: 8.6, h: 1.1, fontSize: 54, bold: true, color: INK, fontFace: "Arial",
  });
  s.addText("A Hardware-Enforced Secure Ingress Barrier for Manchester/RF Serial Links", {
    x: 0.72, y: 2.5, w: 7.6, h: 0.7, fontSize: 17, color: GRAY, fontFace: "Arial",
  });
  s.addText(
    [
      { text: "Area Fokus 04 - Secure Communication", options: { bold: true, color: INK, fontSize: 13, breakLine: true } },
      { text: "Tim dinotice - Universitas Telkom", options: { color: INK, fontSize: 13, breakLine: true } },
      { text: "Ibrahim Fauzi Rahman, Idris Syaifulloh", options: { color: GRAY, fontSize: 12, breakLine: true } },
      { text: "Pembimbing: Dr. Setia Jul Ismail, S.T., M.T.", options: { color: GRAY, fontSize: 12 } },
    ],
    { x: 0.72, y: 3.4, w: 7.6, h: 1.4, fontFace: "Arial" }
  );
  s.addNotes(
    "Perkenalan singkat: tim dinotice dari Universitas Telkom. SALARAS adalah boundary verifikasi integritas berbasis hardware untuk jalur ingress Manchester/RF. Area fokus 04, Secure Communication."
  );
}

/* ---------------- 2. Problem ---------------- */
{
  const s = contentSlide(
    "Masalah",
    "Masalah utama: receiver ringan men-decode bitstream tak tepercaya tanpa validasi lapis tautan. Tiga kelas kelemahan dipetakan ke CWE. Tekankan bahwa data korup tetap tampak valid bagi host."
  );
  s.addText(
    bulletList([
      "Penerima serial/RF ringan men-decode bitstream tak tepercaya langsung ke shift register tanpa validasi lapis tautan.",
      "FSM pemrosesan rapuh terhadap transisi tak terduga dan timing (CWE-1245).",
      "Sinyal kendali (full, latch enable) rentan de-sinkronisasi dari data (CWE-1264).",
      "Field integritas yang sudah dikirim tidak pernah diverifikasi (CWE-354).",
      "Akibatnya payload korup atau hasil fault injection tetap tampil valid bagi host.",
    ]),
    { x: 0.7, y: 1.2, w: 8.6, h: 3.9, fontFace: "Arial", valign: "top" }
  );
}

/* ---------------- 3. Baseline gap ---------------- */
{
  const s = contentSlide(
    "Celah pada Baseline tt07-bep-decode",
    "Baseline adalah decoder Manchester Tiny Tapeout 07. Field tail_1..3 (diduga CRC-24) diekspos ke host tetapi tidak pernah dicek, ditandai komentar '// CRC?' pada RTL. Frame rusak bisa terlanjur di-latch sebagai sah."
  );
  s.addText(
    bulletList([
      "Decoder Manchester Tiny Tapeout 07 (433 MHz, 1x1 tile).",
      "Field integritas 24-bit (tail_1..3) diambil dan diekspos ke host.",
      "Tidak pernah dicek pada RTL baseline; ditandai \"// CRC?\".",
      "Frame data rusak atau tidak selaras dapat terlanjur di-latch sebagai data sah.",
    ]),
    { x: 0.7, y: 1.2, w: 8.6, h: 3.9, fontFace: "Arial", valign: "top" }
  );
}

/* ---------------- 4. Threat model ---------------- */
{
  const s = contentSlide(
    "Threat Model & Attack Surface",
    "Penyerang diasumsikan punya akses pada jalur ingress RF. Host dan bus register dipercaya setelah commit. Empat ancaman utama dipetakan ke CWE."
  );
  s.addTable(
    table([
      ["Kode", "Ancaman", "CWE"],
      ["T1", "Payload korup oleh noise/jitter di jalur RF", "CWE-354"],
      ["T2", "Fault injection single-bit flip pada payload/integritas", "CWE-354"],
      ["T3", "Glitch/timing menyebabkan desinkronisasi kontrol/data", "CWE-1264"],
      ["T4", "Input tak wajar membuat FSM macet/transisi tak sah", "CWE-1245"],
    ]),
    {
      x: 0.7, y: 1.2, w: 8.6, colW: [1.0, 5.6, 2.0], fontSize: 12.5,
      border: { type: "solid", color: "CBD5E1", pt: 1 }, align: "left", valign: "middle",
      fontFace: "Arial", rowH: 0.5, autoPage: false,
    }
  );
}

/* ---------------- 5. Solution overview ---------------- */
{
  const s = contentSlide(
    "Solusi: SALARAS Boundary",
    "SALARAS disisipkan antara decoder Manchester dan register host. Tiga layer: L1 framing/FSM, L2 integrity verify, L3 atomic commit. Fail-closed, tanpa mengubah format frame."
  );
  s.addText("Boundary verifikasi integritas fail-closed: L1 (framing & FSM), L2 (integritas), L3 (atomic commit).", {
    x: 0.7, y: 1.15, w: 8.6, h: 0.5, fontSize: 14, color: INK, fontFace: "Arial",
  });
  s.addImage({ path: "assets/block-diagram.png", x: 1.25, y: 1.75, w: 7.5, h: 2.63 });
}

/* ---------------- 6. L1 ---------------- */
{
  const s = contentSlide(
    "L1 - Framing & FSM Validator",
    "L1 memperluas data_validate. Memanfaatkan timer half_period (9 tick) yang sudah ada; validasi window sendiri logika baru. Ditambah timeout dan recovery branch. Timing window hanya pada edge di dalam frame."
  );
  s.addText(
    bulletList([
      "Reuse dan perluas data_validate (preamble/type/constant).",
      "Timing window memanfaatkan timer half_period 9 tick yang sudah ada; validator window adalah logika baru.",
      "Default/recovery branch untuk transisi FSM tak terduga.",
      "Timeout counter agar FSM tidak macet.",
      "Timing window diterapkan pada edge di dalam frame (setelah preamble valid), bukan hard-reject pada edge awal: start termutilasi yang valid tetap diterima.",
    ]),
    { x: 0.7, y: 1.2, w: 8.6, h: 3.9, fontFace: "Arial", valign: "top" }
  );
}

/* ---------------- 7. L2 ---------------- */
{
  const s = contentSlide(
    "L2 - Integrity Verify",
    "L2 menghitung nilai integritas secara streaming lewat LFSR dan membandingkan dengan tail_1..3. Hasil analisis: field bersifat affine tetapi bukan CRC-24 standar, sehingga L2 diparameterisasi."
  );
  s.addText(
    bulletList([
      "LFSR streaming menghitung nilai integritas dari byte payload.",
      "Dibandingkan dengan tail_1..3 yang diterima sebelum commit.",
      "Tanpa buffer besar; kompleksitas O(n) terhadap jumlah bit frame.",
      "Field affine (delta satu bit konstan) tetapi tidak cocok CRC-24 standar; penulis baseline menduga kode koreksi galat (ECC).",
    ]),
    { x: 0.7, y: 1.2, w: 8.6, h: 2.7, fontFace: "Arial", valign: "top" }
  );
  s.addText(
    "Catatan: hanya 7 pasangan tersedia (rank delta 5), sehingga pemetaan penuh belum dapat direkonstruksi; L2 menunggu pasangan tambahan saat bootcamp.",
    { x: 0.7, y: 4.05, w: 8.6, h: 1.0, fontSize: 12, color: RED, italic: true, fontFace: "Arial", valign: "top" }
  );
}

/* ---------------- 8. L3 ---------------- */
{
  const s = contentSlide(
    "L3 - Atomic Commit Gatekeeper",
    "L3 menggerbangi full dan latch enable secara bersamaan. Jika verifikasi gagal, full ditahan rendah dan fault sticky diangkat. Inilah inti fail-closed."
  );
  s.addText(
    bulletList([
      "Gerbang atomik pada sinyal full dan latch enable.",
      "Data dan kendali dikomit bersamaan hanya saat frame sah.",
      "Jika verifikasi gagal: full tetap rendah dan fault flag diangkat ke host.",
      "Fault bersifat sticky hingga di-acknowledge host.",
      "Fail-closed: kegagalan menahan data, bukan meloloskannya.",
    ]),
    { x: 0.7, y: 1.2, w: 8.6, h: 3.9, fontFace: "Arial", valign: "top" }
  );
}

/* ---------------- 9. Security-by-design ---------------- */
{
  const s = contentSlide(
    "Security-by-design: CWE ke Mitigasi",
    "Setiap CWE dipetakan ke satu layer mitigasi. Ini menunjukkan security-by-design, bukan fitur tempelan."
  );
  s.addTable(
    table([
      ["CWE", "Kelemahan", "Mitigasi SALARAS"],
      ["CWE-354", "Integritas tidak divalidasi", "L2 verifikasi sebelum commit"],
      ["CWE-1245", "FSM rapuh", "L1 recovery branch + timeout + konsistensi transisi"],
      ["CWE-1264", "Desinkronisasi kontrol/data", "L3 atomic commit + fail-closed"],
    ]),
    {
      x: 0.7, y: 1.25, w: 8.6, colW: [1.4, 3.0, 4.2], fontSize: 12.5,
      border: { type: "solid", color: "CBD5E1", pt: 1 }, align: "left", valign: "middle",
      fontFace: "Arial", rowH: 0.6, autoPage: false,
    }
  );
  s.addText("Attack surface dikelola: pin digital_in, timing half-period, handshake full, bus uo_out.", {
    x: 0.7, y: 4.2, w: 8.6, h: 0.6, fontSize: 12, color: GRAY, italic: true, fontFace: "Arial",
  });
}

/* ---------------- 10. Architecture & I/O ---------------- */
{
  const s = contentSlide(
    "Arsitektur & Interface",
    "Clock domain tunggal. Front-end baseline (edge_detect, state_machine, data_validate) dengan shift register pada frame_capture; tanpa block RAM. Interface host 8-bit dengan address 4-bit, handshake full dan fault."
  );
  s.addText(
    bulletList([
      "Jalur digital clock domain tunggal.",
      "Front-end baseline: edge_detect, state_machine, data_validate (dipakai di frame_capture).",
      "Output: uo_out[7:0], full, fault (sinyal baru).",
      "Tanpa block RAM: payload pada shift register frame_capture; state tambahan LFSR, flag, counter timing.",
      "LFSR tanpa DSP. Latency commit 1 siklus clock (terukur pada simulasi boundary).",
    ]),
    { x: 0.7, y: 1.2, w: 8.6, h: 3.9, fontFace: "Arial", valign: "top" }
  );
}

/* ---------------- 11. Verification S1 + S2 ---------------- */
{
  const s = contentSlide(
    "Verifikasi & Prototype (S1 + S2)",
    "Dua jalur memakai golden vector yang sama. S1 simulasi cocotb untuk CI. S2 wired: ESP32 replay ke DE10-Nano, host membaca hasil via USB-UART. Fault injection single-bit flip. Target detection 100 persen, false-reject 0 persen."
  );
  s.addText(
    bulletList([
      "S1 (simulasi, jalur CI): cocotb mem-drive digital_in dari capture CSV; fault injection pada level vektor; metrik otomatis.",
      "S2 (wired hardware-in-the-loop): ESP32 (RMT) replay capture ke pin digital_in DE10-Nano; 3.3 V, tanpa level shifter; host membaca uo_out/full/fault via USB-UART.",
      "Fault injection: single-bit flip pada payload dan field integritas, plus gangguan timing/jitter.",
      "Corner-case: start termutilasi valid tetap diterima; glitch dalam frame dan noise ditolak.",
      "Metrik target: detection rate 100%, false-reject 0%, latency 1 siklus.",
    ]),
    { x: 0.7, y: 1.2, w: 8.6, h: 3.9, fontFace: "Arial", valign: "top", fontSize: 13.5 }
  );
}

/* ---------------- 12. Target platform + prototype ---------------- */
{
  const s = contentSlide(
    "Target Platform & Prototype",
    "Target ASIC Tiny Tapeout pada sky130; hasil hardening menempati tile 1x2. Target FPGA DE10-Nano Cyclone V. Prototype wired tanpa RF agar deterministik."
  );
  s.addText("ASIC: 1x2 tile, 0.0363 mm^2, WNS 0.00 ns, 1.21 mW (sky130).   FPGA: DE10-Nano (Cyclone V SoC).", {
    x: 0.7, y: 1.12, w: 8.6, h: 0.4, fontSize: 13, color: INK, fontFace: "Arial",
  });
  s.addImage({ path: "assets/prototype-s1.png", x: 1.7, y: 1.5, w: 6.6, h: 1.03 });
  s.addImage({ path: "assets/prototype-s2.png", x: 1.7, y: 2.72, w: 6.6, h: 1.32 });
}

/* ---------------- 12b. Hasil ---------------- */
{
  const s = contentSlide(
    "Hasil Sementara",
    "Bukti simulasi (S1) dan hasil sintesis sky130 sudah tersedia."
  );
  s.addTable(
    table([
      ["Aspek", "Hasil"],
      ["Vulnerabilitas baseline", "Payload dan field integritas korup tetap di-latch (full=1, CWE-354)"],
      ["Boundary SALARAS", "Fail-closed: menolak, fault lengket, commit 1 siklus"],
      ["Hardening sky130", "Tile 1x2 (1x1 melampaui 105.57%), 0.0363 mm^2, 0 DRC"],
      ["Timing & daya", "WNS 0.00 ns; daya tipikal 1.21 mW"],
      ["Gate-level", "Simulasi netlist lolos (3/3)"],
    ]),
    {
      x: 0.7, y: 1.2, w: 8.6, colW: [2.6, 6.0], fontSize: 12.5,
      border: { type: "solid", color: "CBD5E1", pt: 1 }, align: "left", valign: "middle",
      fontFace: "Arial", rowH: 0.55, autoPage: false,
    }
  );
}

/* ---------------- 13. Roadmap ---------------- */
{
  const s = contentSlide(
    "Roadmap & Bootcamp (18-20 Oktober 2026)",
    "Rencana tiga hari bootcamp. Hari 1 finalisasi RTL dan integrasi. Hari 2 fault injection dan verifikasi. Hari 3 sintesis, SignalTap, demo dan presentasi Top 5 menuju Top 3."
  );
  s.addTable(
    table([
      ["Hari", "Fokus", "Deliverable"],
      ["Hari 1 (18 Okt)", "Finalisasi RTL L1-L3 + integrasi baseline", "RTL dapat disimulasikan"],
      ["Hari 2 (19 Okt)", "Fault injection + verifikasi cocotb", "Laporan detection rate & latency"],
      ["Hari 3 (20 Okt)", "Sintesis Quartus, SignalTap, demo DE10-Nano", "Bitstream + demo + presentasi Top 5"],
    ]),
    {
      x: 0.7, y: 1.3, w: 8.6, colW: [1.9, 3.6, 3.1], fontSize: 12.5,
      border: { type: "solid", color: "CBD5E1", pt: 1 }, align: "left", valign: "middle",
      fontFace: "Arial", rowH: 0.62, autoPage: false,
    }
  );
}

/* ---------------- 14. Team ---------------- */
{
  const s = contentSlide(
    "Tim & Peran",
    "Pembagian peran: RTL, verifikasi, dan pembimbing. Penutup: terima kasih."
  );
  s.addTable(
    table([
      ["Nama", "Peran"],
      ["Ibrahim Fauzi Rahman", "RTL Designer: desain L1-L3 (SALARAS) + integrasi baseline"],
      ["Idris Syaifulloh", "Verification: cocotb, fault injection, metrik"],
      ["Dr. Setia Jul Ismail, S.T., M.T.", "Pembimbing: review arsitektur dan metodologi verifikasi"],
    ]),
    {
      x: 0.7, y: 1.3, w: 8.6, colW: [3.0, 5.6], fontSize: 13,
      border: { type: "solid", color: "CBD5E1", pt: 1 }, align: "left", valign: "middle",
      fontFace: "Arial", rowH: 0.6, autoPage: false,
    }
  );
  s.addText("Terima kasih.", {
    x: 0.7, y: 4.35, w: 8.6, h: 0.6, fontSize: 20, bold: true, color: ACCENT, fontFace: "Arial",
  });
}

const outDir = process.env.DECK_OUT_DIR || ".";
const base = process.env.DECK_BASE || "salaras-deck";
const outPath = join(outDir, `${base}.pptx`);
await pptx.writeFile({ fileName: outPath });
console.log(`wrote ${outPath} (${pageNo} slides)`);
