# Ide-05: DISPARITY-GUARD

8b/10b Penuh dan Berintegritas dengan Teknik SALARAS-RX

*Baseline*: `TT_UM_SERDES` (`tt_um_serdes`)
Area Fokus: 04 - Secure Communication (secure framing, *PHY* hardening)
Status: ide turunan yang memakai ulang teknik SALARAS-RX
Skor simulasi juri: 77.0 dari 100

## 1. Ringkasan Ide

Masalah yang diangkat adalah implementasi 8b/10b pada *baseline* belum lengkap, sehingga deteksi error dan keseimbangan DC tidak optimal.
*Baseline* tidak mengatur *running disparity*, tidak memakai *K-code*, dan *decoder*-nya menelan kode tidak sah menjadi nol.
Solusi yang ditawarkan adalah *DISPARITY*-GUARD, yaitu penyempurnaan lapis fisik 8b/10b menjadi penuh, ditambah framing dan integritas dengan teknik SALARAS-RX.

Chip yang dirancang menambahkan manajemen *running disparity*, *K-code* dan penanda koma, penanganan kode tidak sah, status lock, dan integritas CRC.
Target pengguna adalah perancang tautan serial yang membutuhkan pengkodean fisik yang benar dan terdeteksi.
Dampaknya adalah tautan yang lebih andal dan aman pada lapis *PHY*.

## 2. Baseline: tt_um_serdes

Yang tersedia: tabel *encoder* dan *decoder* 8b/10b, PISO, dan SIPO.
Yang kurang: *running disparity*, *K-code*, penanda koma, deteksi kode tidak sah, framing, dan integritas.

## 3. Penerapan Teknik SALARAS-RX

| Lapisan | Implementasi pada DISPARITY-GUARD |
| --- | --- |
| L1 | Penanda koma, penyelarasan, status lock, penanganan kode tidak sah |
| L2 | Manajemen disparitas dan CRC atas frame |
| L3 | Gate data saat kode tidak sah atau CRC gagal, fail-closed, fault lengket |

## 4. Integritas: Disparitas dan CRC

Disparitas menjaga keseimbangan DC dan membantu sinkronisasi.
CRC menambahkan deteksi error pada tingkat *frame*.
Keduanya bersifat non-kriptografis, sehingga untuk data sensitif tetap perlu MAC.

## 5. Perbandingan dengan SALARAS-RX

| Aspek | SALARAS-RX (tt07-bep-decode) | DISPARITY-GUARD |
| --- | --- | --- |
| Lapis | Protokol frame | Lapis fisik dan pengkodean |
| Integritas | Verifikasi CRC | Disparitas dan CRC |
| Keamanan adversarial | Lemah | Lemah sampai sedang |
| Relevansi Peruri | Rendah | Sedang, fondasi tautan serial |
| Kompleksitas | Sedang | Sedang |

Plus: memperbaiki fondasi *PHY*, murah area, meningkatkan keandalan.
Minus: tidak menambah keamanan kriptografis, kurang menonjol bila berdiri sendiri.

## 6. Kelayakan dan Possibility to Create

Kelayakan teknis: tinggi.
Estimasi area: 1x1 *tile*.
Alat sama dengan SALARAS-RX.
Waktu: singkat.
Risiko utama: kebenaran tabel 8b/10b penuh membutuhkan pengujian yang teliti.

## 7. Simulasi Penjurian

| Kriteria | Bobot | Skor |
| --- | --- | --- |
| Relevansi Masalah | 15 | 78 |
| Kebaruan dan Keunggulan | 15 | 74 |
| Kualitas Teknis dan Arsitektur | 20 | 82 |
| Keamanan dan Threat Model | 20 | 76 |
| Kelayakan dan Verifikasi | 15 | 74 |
| Dampak dan Hilirisasi | 10 | 74 |
| Kepatuhan dan Kejelasan | 5 | 82 |
| Total tertimbang | 100 | 77.0 |

Pertanyaan kritis:
1. Apakah keamanan bertambah, atau hanya keandalan?
2. Bagaimana membuktikan tabel 8b/10b penuh benar?
3. Apa bedanya dengan SerDes standar di industri?

*Verdict*: ide teknis yang rapi namun kurang menonjol sebagai produk keamanan.

## 8. Rekomendasi

- Posisikan sebagai fondasi bagi SALARAS-SERDES.
- Tambahkan CRC dan status lock agar dapat berdiri sendiri.

## 9. Glosarium

- *Running disparity*: keseimbangan berjalan antara bit satu dan nol.
- *K-code*: kode kontrol pada 8b/10b.
- *Comma*: pola khusus untuk penyelarasan.
- *PHY*: lapis fisik komunikasi.

## 10. Pertanyaan Terbuka

- Perlukah dukungan kecepatan tinggi, atau cukup untuk demonstrasi 1 *tile*?
- Bagaimana rencana verifikasi tabel pengkodean secara menyeluruh?
