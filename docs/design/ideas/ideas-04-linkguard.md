# Ide-04: LINK-GUARD

Online Serial Link Monitor dan *Anti-Tamper* Flag dengan Teknik SALARAS-RX

*Baseline*: `TT_UM_SERDES` (`tt_um_serdes`)
Area Fokus: 04 - Secure Communication (protocol security, *anti-tamper*)
Status: ide turunan yang memakai ulang teknik SALARAS-RX
Skor simulasi juri: 78.4 dari 100

## 1. Ringkasan Ide

Masalah yang diangkat adalah gangguan pada tautan serial sering tidak terlihat dan tidak tercatat, sehingga indikasi *tamper* hilang.
*Baseline* SerDes tidak memiliki pemantauan, tidak memiliki penghitung error, dan tidak melaporkan kode 10b yang tidak sah.
Solusi yang ditawarkan adalah LINK-GUARD, yaitu blok pemantauan yang memakai pola teknik SALARAS-RX untuk mengamati kesehatan tautan dan menaikkan *fault* bila ada anomali.

Chip yang dirancang memantau disparitas, kode 8b/10b yang tidak sah, *glitch*, dan laju error, lalu menyimpannya pada register status yang dapat dibaca *host*.
Target pengguna adalah perancang perangkat aman yang membutuhkan indikasi *tamper* pada lapis fisik.
Dampaknya adalah visibilitas terhadap gangguan tautan dan dasar untuk respons keamanan.

## 2. Baseline: tt_um_serdes

Yang tersedia: *encoder* dan *decoder* 8b/10b, PISO, dan SIPO.
Yang kurang untuk pemantauan: tidak ada deteksi kode tidak sah, tidak ada penghitung error, tidak ada status kesehatan tautan, dan tidak ada sinyal *fault*.

## 3. Penerapan Teknik SALARAS-RX

| Lapisan | Implementasi pada LINK-GUARD |
| --- | --- |
| L1 | Pemantauan framing dan kode, status lock, timeout |
| L2 | Pengecekan disparitas dan kode 8b/10b, penghitung error |
| L3 | Ambang fault, fault lengket, gate data bila anomali melewati ambang |

L2 di sini lebih tepat memakai pemeriksaan struktural (disparitas dan kode) daripada MAC, karena tujuannya pemantauan, bukan autentikasi.

## 4. Integritas: Pemantauan Struktural

Disparitas dan kode 8b/10b yang tidak sah adalah sinyal murah untuk mendeteksi gangguan.
Penghitung error memberi ukuran kuantitatif kesehatan tautan.
Untuk keperluan autentikasi, MAC tetap diperlukan bila tautan dipakai untuk data sensitif.

## 5. Perbandingan dengan SALARAS-RX

| Aspek | SALARAS-RX (tt07-bep-decode) | LINK-GUARD |
| --- | --- | --- |
| Tujuan | Menolak frame tidak sah | Memantau dan melaporkan anomali |
| Integritas | Verifikasi CRC | Pemeriksaan struktural dan penghitung error |
| Aksi | Fail-closed | Fault lengket dan gate opsional |
| Relevansi Peruri | Rendah | Sedang-tinggi untuk anti-tamper |
| Kompleksitas | Sedang | Sedang |

Plus: ringan area, meningkatkan observabilitas, sesuai tema *anti-tamper*.
Minus: bukan mekanisme autentikasi, sehingga bukan pengganti MAC.

## 6. Kelayakan dan Possibility to Create

Kelayakan teknis: tinggi.
Estimasi area: 1x1 *tile*.
Alat sama dengan SALARAS-RX.
Waktu: singkat, cocok sebagai pelengkap ide lain.
Risiko utama: menetapkan ambang *fault* yang tepat agar tidak false alarm.

## 7. Simulasi Penjurian

| Kriteria | Bobot | Skor |
| --- | --- | --- |
| Relevansi Masalah | 15 | 80 |
| Kebaruan dan Keunggulan | 15 | 72 |
| Kualitas Teknis dan Arsitektur | 20 | 78 |
| Keamanan dan Threat Model | 20 | 80 |
| Kelayakan dan Verifikasi | 15 | 80 |
| Dampak dan Hilirisasi | 10 | 78 |
| Kepatuhan dan Kejelasan | 5 | 84 |
| Total tertimbang | 100 | 78.4 |

Pertanyaan kritis:
1. Bagaimana ambang *fault* ditentukan agar tidak false alarm?
2. Apakah pemantauan ini dapat di-bypass oleh penyerang?
3. Bagaimana indikasi *tamper* dipakai oleh *host*?

*Verdict*: ide pelengkap yang kuat untuk *anti-tamper*.

## 8. Rekomendasi

- Gabungkan dengan SALARAS-SERDES sebagai lapis observabilitas.
- Sediakan register status dan penghitung error yang jelas.

## 9. Glosarium

- *Disparity*: selisih jumlah bit satu dan nol.
- *Glitch*: pulsa pendek yang tidak diinginkan.
- *Anti-tamper*: upaya mendeteksi gangguan fisik atau logika.
- *Fault* lengket: penanda yang bertahan sampai dihapus.

## 10. Pertanyaan Terbuka

- Perlu tidaknya ambang adaptif terhadap tingkat noise?
- Bagaimana integrasi status dengan *host* melalui register atau *interrupt*?
