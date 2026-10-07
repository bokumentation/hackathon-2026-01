import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer-core";

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
const footnote =
  (covers[lang] || covers.en).footer ||
  "TRI-ARGA | PERURI Chip Hackathon 2026 | Universitas Telkom";

const browser = await puppeteer.launch({
  executablePath: chromePath || undefined,
  headless: true,
  args: ["--no-sandbox", "--disable-gpu"],
});

try {
  const page = await browser.newPage();
  await page.goto("file://" + htmlPath, { waitUntil: "networkidle0" });
  await page.evaluate(() => document.fonts.ready);
  await page.pdf({
    path: pdfPath,
    format: "A4",
    printBackground: true,
    displayHeaderFooter: true,
    headerTemplate: "<div></div>",
    footerTemplate:
      '<div style="width:100%; font-size:8pt; color:#6b7280; padding:0 18mm; font-family:Helvetica,Arial,sans-serif;">' +
      '<div style="border-top:0.5px solid #d9dde3; padding-top:2mm;">' +
      '<table style="width:100%; border-collapse:collapse;"><tr>' +
      `<td style="text-align:left;">${footnote}</td>` +
      '<td style="text-align:right;"><span class="pageNumber"></span> / <span class="totalPages"></span></td>' +
      "</tr></table>" +
      "</div>" +
      "</div>",
    margin: { top: "18mm", bottom: "18mm", left: "18mm", right: "18mm" },
  });
} finally {
  await browser.close();
}
