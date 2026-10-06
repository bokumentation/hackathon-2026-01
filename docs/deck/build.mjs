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
const GREEN = "166534";
const RED = "B91C1C";
const LINE = "E5E7EB";

const BRAND = cover.brand;
const TAGLINE = cover.subtitle;

const pptx = new pptxgen();
pptx.layout = "LAYOUT_16x9";
pptx.author = "Tri Arga";
pptx.company = "Universitas Telkom";
pptx.title = `${BRAND} - PERURI Chip Hackathon 2026`;

const TOTAL = 14;
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
    "Perkenalan: tim Tri Arga, Universitas Telkom. TRI-ARGA adalah boundary ingress tiga lapis yang mengautentikasi dan memeriksa kesegaran frame sebelum commit fail-closed. Area fokus 04, Secure Communication."
  );
}

/* ---------------- 2. Problem ---------------- */
{
  const s = contentSlide(
    "Masalah",
    "Penerima serial/RF ringan memparsing bitstream tak tepercaya tanpa autentikasi. Tiga kelas kegagalan: integritas tak divalidasi, replay, dan commit tak atomik. Akibatnya frame korup, palsu, atau lama tetap tampak sah bagi host."
  );
  s.addText(
    bulletList([
      "Penerima serial/RF ringan memparsing bitstream tak tepercaya langsung ke register, tanpa memeriksa integritas.",
      "Integritas tidak divalidasi: CRC/ECC tanpa kunci dapat dihitung ulang oleh penyerang (CWE-354, CWE-345).",
      "Replay: frame lama yang sah dapat diputar ulang tanpa penanda kesegaran (CWE-294).",
      "Commit tidak atomik dan FSM rapuh: data dan kendali dapat terlepas (CWE-1264, CWE-1245).",
      "Verifikasi di software berjalan setelah data melewati batas kepercayaan.",
    ]),
    { x: 0.7, y: 1.2, w: 8.6, h: 3.9, fontFace: "Arial", valign: "top" }
  );
}

/* ---------------- 3. Baseline evidence ---------------- */
{
  const s = contentSlide(
    "Bukti pada Baseline tt07-bep-decode",
    "Baseline Manchester Tiny Tapeout 07 menerima field integritas 24 bit (tail_1..3) dan tidak pernah memeriksanya. Simulasi kami menunjukkan payload dan field korup tetap di-latch dengan full=1, yaitu CWE-354 yang terukur."
  );
  s.addText(
    bulletList([
      "Decoder Manchester Tiny Tapeout 07 (`tt07-bep-decode`), contoh pola penerima ringan.",
      "Field integritas 24 bit (`tail_1..3`) diterima dan diteruskan ke host tanpa pemeriksaan.",
      "Terukur: payload korup dan field korup tetap di-latch dengan `full=1` (CWE-354).",
      "Field bersifat affine tetapi bukan CRC-24 standar dan belum dipecahkan; tetap menjadi bukti kelas kerentanan, bukan jalur integritas kami.",
    ]),
    { x: 0.7, y: 1.2, w: 8.6, h: 3.9, fontFace: "Arial", valign: "top" }
  );
}

/* ---------------- 4. Threat model ---------------- */
{
  const s = contentSlide(
    "Threat Model",
    "Penyerang dapat menyadap, menyisipkan, mengubah, menghapus, dan memutar ulang frame pada tautan. Ia tidak memiliki kunci dan tidak melakukan serangan kanal samping. Setiap ancaman dipetakan ke mitigasi per lapisan."
  );
  s.addTable(
    table([
      ["Ancaman", "CWE", "Mitigasi"],
      ["Frame palsu", "CWE-345", "MAC berkunci (SIMON CBC-MAC)"],
      ["Integritas tidak dicek", "CWE-354", "Tag selalu dihitung ulang dan dibandingkan"],
      ["Replay frame lama", "CWE-294", "Counter harus naik ketat"],
      ["Data dan kendali terlepas", "CWE-1264", "Commit atomik satu siklus"],
      ["FSM macet / state ilegal", "CWE-1245", "FSM terenumerasi, fault lengket"],
      ["Framing tidak sah", "CWE-20", "Pemuat menolak frame tak lengkap"],
    ]),
    {
      x: 0.7, y: 1.15, w: 8.6, colW: [2.6, 1.5, 4.5], fontSize: 12.5,
      border: { type: "solid", color: "CBD5E1", pt: 1 }, align: "left", valign: "middle",
      fontFace: "Arial", rowH: 0.48, autoPage: false,
    }
  );
}

/* ---------------- 5. Solution overview ---------------- */
{
  const s = contentSlide(
    "Solusi: TRI-ARGA, Tiga Lapis",
    "TRI-ARGA duduk di antara front-end yang tak tepercaya dan host: frame masuk, diautentikasi, diperiksa kesegarannya, lalu dilepas atomik atau ditolak. Tiga lapis: L1 pemuat, L2 auth, L3 commit."
  );
  s.addText("L1 Arga Kunci (pemuat frame), L2 Arga Auth (CBC-MAC + kesegaran), L3 Arga Commit (fail-closed).", {
    x: 0.7, y: 1.12, w: 8.6, h: 0.5, fontSize: 14, color: INK, fontFace: "Arial",
  });
  s.addImage({ path: "assets/block-diagram.png", x: 1.4, y: 1.2, w: 7.2, h: 4.32 });
}

/* ---------------- 6. L1 ---------------- */
{
  const s = contentSlide(
    "L1 - Arga Kunci (Pemuat Serial)",
    "L1 menggeser kunci 64 bit secara write-once lalu frame 128 bit pada satu antarmuka bit. Kunci tidak pernah melewati tautan; setelah 64 bit, kunci terkunci sampai reset."
  );
  s.addText(
    bulletList([
      "Antarmuka satu bit: `frame_bit`, `load_en`, dan `key_mode`.",
      "Kunci 64 bit dimuat sekali (write-once); setelah 64 bit `key_locked` naik dan pemuatan kunci berikutnya diabaikan.",
      "Frame 128 bit: counter (32) + payload (64) + tag (32), digeser MSB-first.",
      "Frame sebelum kunci dimuat diabaikan; kunci masuk dari host lewat jalur terpisah.",
    ]),
    { x: 0.7, y: 1.2, w: 8.6, h: 3.9, fontFace: "Arial", valign: "top" }
  );
}

/* ---------------- 7. L2 ---------------- */
{
  const s = contentSlide(
    "L2 - Arga Auth (Autentikasi & Kesegaran)",
    "L2 menghitung CBC-MAC SIMON-32/64 atas counter + payload (tiga blok), membandingkan tag 32 bit, dan memeriksa kesegaran counter secara ketat. Forgery dan replay ditolak."
  );
  s.addText(
    bulletList([
      "SIMON-32/64 terserialisasi, satu ronde per siklus; 33 siklus per blok.",
      "CBC-MAC panjang tetap atas tiga blok (B1 counter, B2-B3 payload), IV = 0, tag 32 bit.",
      "Tag hasil hitung dibandingkan dengan tag yang diterima; salah tag berarti tolak.",
      "Counter harus lebih besar dari yang terakhir diterima; counter sama atau basi ditolak (CWE-294).",
    ]),
    { x: 0.7, y: 1.2, w: 8.6, h: 3.0, fontFace: "Arial", valign: "top" }
  );
  s.addText(
    "Batas jujur: peluang forgery sekitar 2^-32 untuk tag 32 bit; CBC-MAC aman hanya untuk panjang tetap; kunci disarankan dirotasi.",
    { x: 0.7, y: 4.15, w: 8.6, h: 0.9, fontSize: 12, color: RED, italic: true, fontFace: "Arial", valign: "top" }
  );
}

/* ---------------- 8. L3 ---------------- */
{
  const s = contentSlide(
    "L3 - Arga Commit (Fail-Closed)",
    "L3 melepas data dan host_full bersamaan dalam satu siklus, hanya jika autentikasi dan kesegaran lulus. Jika gagal, data ditahan dan fault menyala lengket sampai di-acknowledge."
  );
  s.addText(
    bulletList([
      "Commit atomik: `host_data` dan `host_full` dilepas bersamaan.",
      "Data yang dikomit adalah data yang di-latch saat MAC dimulai, bukan port masukan yang berubah (menutup CWE-1264).",
      "Jika auth atau kesegaran gagal: `host_full` tetap rendah, `fault` naik.",
      "Fault bersifat lengket sampai host mengirim `fault_ack`.",
      "Fail-closed: kegagalan menahan data, bukan meloloskannya.",
    ]),
    { x: 0.7, y: 1.2, w: 8.6, h: 3.9, fontFace: "Arial", valign: "top" }
  );
}

/* ---------------- 9. Security-by-design ---------------- */
{
  const s = contentSlide(
    "Security-by-design",
    "Setiap CWE dipetakan ke satu lapisan mitigasi. Keamanan adalah fondasi rancangan, bukan fitur tempelan."
  );
  s.addTable(
    table([
      ["CWE", "Kelemahan", "Mitigasi"],
      ["CWE-354", "Integritas tidak divalidasi", "L2 menghitung dan membandingkan tag sebelum commit"],
      ["CWE-345", "Autentisitas data lemah", "L2 MAC berkunci SIMON-32/64"],
      ["CWE-294", "Replay", "L2 counter naik ketat"],
      ["CWE-1264", "Desinkronisasi kontrol/data", "L3 commit atomik dari data yang di-latch"],
      ["CWE-1245", "FSM rapuh", "FSM terenumerasi + fault lengket"],
      ["CWE-20", "Input tak tervalidasi", "L1 menolak frame tak lengkap"],
    ]),
    {
      x: 0.7, y: 1.2, w: 8.6, colW: [1.4, 2.9, 4.3], fontSize: 12,
      border: { type: "solid", color: "CBD5E1", pt: 1 }, align: "left", valign: "middle",
      fontFace: "Arial", rowH: 0.44, autoPage: false,
    }
  );
}

/* ---------------- 10. Architecture & I/O ---------------- */
{
  const s = contentSlide(
    "Arsitektur & Interface",
    "Satu domain clock, murni digital, tanpa block RAM, DSP, atau PLL. Format frame tetap 128 bit dengan kunci terpisah. Wrapper Tiny Tapeout mengekspos status ke host."
  );
  s.addText(
    bulletList([
      "Satu clock; state hanya register (cipher, counter, flag). Tanpa block RAM dan DSP.",
      "Format frame: counter (32) + payload (64) + tag (32); kunci 64 bit tidak ikut frame.",
      "My Tiny Tapeout I/O: `ui_in[0]` frame_bit, `ui_in[1]` load_en, `ui_in[2]` fault_ack, `ui_in[3]` key_mode.",
      "Output: done, host_full, fault, auth_ok, fresh_ok, key_locked.",
      "Latensi ujung ke ujung 108 siklus (2,16 us pada 50 MHz).",
    ]),
    { x: 0.7, y: 1.2, w: 8.6, h: 3.9, fontFace: "Arial", valign: "top" }
  );
}

/* ---------------- 11. Verification ---------------- */
{
  const s = contentSlide(
    "Verifikasi & Bukti",
    "Simulasi cocotb, properti formal SymbiYosys, dan hasil sintesis fisik. Rangkaian simulasi mencakup forgery, replay, bit flip, dan pemuatan kunci."
  );
  s.addText(
    bulletList([
      "Simulasi cocotb: 30 tes lolos pada suite simon, l2, auth, crc, wrapper, dan lampiran RF.",
      "Fault injection: 128 dari 128 single-bit flip ditolak; false reject 0 dari 20 frame bersih.",
      "Formal (SymbiYosys): 5 properti inti depth-40 + `l1_link`; satu properti data-integrity non-blocking masih gagal dan sedang diperbaiki.",
      "Uji jujur: angka yang dilaporkan hanya yang terukur; sisanya ditandai estimasi.",
    ]),
    { x: 0.7, y: 1.2, w: 8.6, h: 3.9, fontFace: "Arial", valign: "top" }
  );
}

/* ---------------- 12. Measured results ---------------- */
{
  const s = contentSlide(
    "Hasil Terukur",
    "Simulasi dan sintesis fisik sudah tersedia. Angka ASIC berasal dari signoff revisi wrapper sebelumnya dan akan dijalankan ulang."
  );
  s.addTable(
    table([
      ["Aspek", "Hasil"],
      ["Simulasi", "128/128 bit flip ditolak; false reject 0; 108 siklus ujung ke ujung"],
      ["Formal", "5 properti inti + l1_link; auth_data_integrity sedang diperbaiki"],
      ["ASIC sky130", "Tile 2x2, 0,0756 mm^2, 2354 sel, 0 DRC/LVS, 1,87 mW (revisi sebelumnya)"],
      ["FPGA DE10-Nano", "242 ALM, 654 FF, 0 M10K, 0 DSP, Fmax 136,37 MHz"],
      ["Daya FPGA", "425,4 mW total, 2,42 mW dinamis inti (vector-less PowerPlay)"],
    ]),
    {
      x: 0.7, y: 1.2, w: 8.6, colW: [2.2, 6.4], fontSize: 12,
      border: { type: "solid", color: "CBD5E1", pt: 1 }, align: "left", valign: "middle",
      fontFace: "Arial", rowH: 0.62, autoPage: false,
    }
  );
}

/* ---------------- 13. Roadmap ---------------- */
{
  const s = contentSlide(
    "Roadmap & Bootcamp (18-20 Oktober 2026)",
    "Rencana tiga hari. Hari 1 integrasi dengan baseline SerDes dan uji korupsi/replay. Hari 2 sintesis Quartus, SignalTap, dan uji on-board. Hari 3 pengukuran akhir dan demo."
  );
  s.addTable(
    table([
      ["Hari", "Fokus", "Deliverable"],
      ["Hari 1 (18 Okt)", "Integrasi inti dengan baseline TT07 SerDes; uji korupsi dan replay", "RTL terintegrasi lolos simulasi"],
      ["Hari 2 (19 Okt)", "Sintesis Quartus, SignalTap, uji forgery dan replay on-board", "Bitstream, laporan resource dan timing"],
      ["Hari 3 (20 Okt)", "Pengukuran akhir, poles hardening, demo dan presentasi", "Demo dan materi presentasi"],
    ]),
    {
      x: 0.7, y: 1.3, w: 8.6, colW: [1.9, 4.4, 2.3], fontSize: 12,
      border: { type: "solid", color: "CBD5E1", pt: 1 }, align: "left", valign: "middle",
      fontFace: "Arial", rowH: 0.66, autoPage: false,
    }
  );
}

/* ---------------- 14. Team ---------------- */
{
  const s = contentSlide(
    "Tim & Peran",
    "Pembagian peran: RTL dan verifikasi. Penutup: terima kasih."
  );
  s.addTable(
    table([
      ["Nama Anggota", "Keahlian Utama", "Tanggung Jawab & Peran"],
      ["Ibrahim Fauzi Rahman", "Embedded Hardware/System, IoT, Isolated PCB Design RS485/CAN Bus", "RTL: L1-L3 design and integration"],
      ["Idris Syaifulloh", "DevOps, Malware Researcher, CI/CD", "Verification: cocotb, fault injection, metrics"],
    ]),
    {
      x: 0.7, y: 1.3, w: 8.6, colW: [2.3, 3.4, 2.9], fontSize: 11,
      border: { type: "solid", color: "CBD5E1", pt: 1 }, align: "left", valign: "middle",
      fontFace: "Arial", rowH: 0.6, autoPage: false,
    }
  );
  s.addText("Terima kasih.", {
    x: 0.7, y: 4.35, w: 8.6, h: 0.6, fontSize: 20, bold: true, color: ACCENT, fontFace: "Arial",
  });
}

const outDir = process.env.DECK_OUT_DIR || ".";
const base = process.env.DECK_BASE || "tri-arga-deck";
const outPath = join(outDir, `${base}.pptx`);
await pptx.writeFile({ fileName: outPath });
console.log(`wrote ${outPath} (${pageNo} slides)`);
