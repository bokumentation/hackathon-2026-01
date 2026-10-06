import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer-core";
import { PDFDocument, StandardFonts, rgb } from "pdf-lib";

const [htmlPath, pdfPath, chromePath, lang] = process.argv.slice(2);
if (!htmlPath || !pdfPath) {
  console.error(
    "usage: print-pdf.mjs <input.html> <output.pdf> [chrome-executable] [lang]"
  );
  process.exit(1);
}

const dir = dirname(fileURLToPath(import.meta.url));
const coverFile = process.env.COVER_FILE || join(dir, "cover.json");
const covers = JSON.parse(readFileSync(coverFile, "utf8"));
const runningHead = (covers[lang] || covers.en).runningHead;

const browser = await puppeteer.launch({
  executablePath: chromePath || undefined,
  headless: true,
  args: ["--no-sandbox", "--disable-gpu"],
});

try {
  const page = await browser.newPage();
  await page.goto("file://" + htmlPath, { waitUntil: "networkidle0" });
  await page.pdf({
    path: pdfPath,
    format: "A4",
    printBackground: true,
    displayHeaderFooter: true,
    headerTemplate: "<div></div>",
    footerTemplate:
      '<div style="width:100%; font-size:8pt; color:#6b7280; padding:0 18mm; text-align:right;">' +
      '<span class="pageNumber"></span> / <span class="totalPages"></span></div>',
    margin: { top: "18mm", bottom: "18mm", left: "18mm", right: "18mm" },
  });
} finally {
  await browser.close();
}

if (runningHead) {
  const mm = (v) => (v / 25.4) * 72;
  const pdf = await PDFDocument.load(readFileSync(pdfPath));
  const font = await pdf.embedFont(StandardFonts.Helvetica);
  const left = mm(18);
  const pages = pdf.getPages();

  let size = 8;
  if (pages.length > 1) {
    const usable = pages[1].getSize().width - 2 * left;
    const natural = font.widthOfTextAtSize(runningHead, size);
    if (natural > usable) size = Math.max(6.5, (size * usable) / natural);
  }

  for (let i = 1; i < pages.length; i++) {
    const p = pages[i];
    const { width, height } = p.getSize();
    const baseline = height - mm(11);
    p.drawText(runningHead, {
      x: left,
      y: baseline,
      size,
      font,
      color: rgb(0.42, 0.45, 0.5),
    });
    p.drawLine({
      start: { x: left, y: baseline - mm(2.4) },
      end: { x: width - left, y: baseline - mm(2.4) },
      thickness: 0.5,
      color: rgb(0.85, 0.87, 0.9),
    });
  }

  writeFileSync(pdfPath, await pdf.save());
}
