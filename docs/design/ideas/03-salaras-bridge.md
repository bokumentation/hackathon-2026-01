# Ide-03: SALARAS-BRIDGE

*End-to-End* Secure *Ingress* dengan SerDes dan CDC FIFO

*Baseline*: `TT_UM_SERDES` dan `tt07_cdc_fifo`
Area Fokus: 04 - Secure Communication (secure framing, CDC, interface integrity)
Status: ide turunan gabungan yang memakai ulang teknik SALARAS
Skor simulasi juri: 82.6 dari 100

## 1. Ringkasan Ide

Masalah yang diangkat adalah jalur *ingress* dari tautan serial ke subsistem berclock berbeda belum memiliki integritas ujung ke ujung.
Data masuk sebagai aliran serial tanpa framing dan tanpa integritas, lalu melintasi domain *clock* tanpa pengecekan.
Solusi yang ditawarkan adalah SALARAS-BRIDGE, yaitu rangkaian SerDes aman yang menyuplai CDC FIFO terpercaya, dengan verifikasi integritas di setiap tahap dan *commit* *fail-closed*.

Chip yang dirancang menyusun dua blok: lapis pertama adalah tautan serial aman dengan framing dan MAC, lapis kedua adalah FIFO lintas *clock* dengan ECC pada *payload*.
Target pengguna adalah perancang sistem identitas dan pembayaran yang menghubungkan front-end serial ke *host* atau *secure element*.
Dampaknya adalah satu *boundary* *ingress* yang menolak data rusak atau dipalsukan sebelum mencapai *host*.

## 2. Baseline yang Dipakai

Dari `tt_um_serdes` tersedia *encoder* dan *decoder* 8b/10b, PISO, dan SIPO, tetapi tanpa framing dan integritas.
Dari `tt07_cdc_fifo` tersedia FIFO asinkron dengan pointer *gray code*, sinkronizer dua *flip-flop*, dan *dual-port RAM*, tetapi tanpa *parity* atau ECC.
Gabungan keduanya membentuk jalur lengkap dari bit serial sampai data paralel pada domain *clock* tujuan.

## 3. Penerapan Teknik SALARAS

| Lapisan | Implementasi pada SALARAS-BRIDGE |
| --- | --- |
| L1 | Framing, penyelarasan, lock pada SerDes, dan cek status handshake pada FIFO |
| L2 | MAC atau CRC pada tautan serial, lalu ECC pada payload FIFO |
| L3 | Commit atomik end-to-end, fail-closed di kedua tahap, fault lengket ke host |

Integritas diperiksa dua kali, yaitu pada tautan serial dan pada lintas domain *clock*, sehingga kesalahan tidak lolos dari salah satu tahap.

## 4. Integritas: Kombinasi yang Tepat

Pada tautan serial yang melewati batas kepercayaan, MAC lebih tepat karena melindungi dari pemalsuan.
Pada FIFO internal antar domain *clock*, ECC atau *parity* lebih hemat dan cukup untuk error acak.
Kombinasi MAC pada tautan dan ECC pada FIFO memberi perlindungan berlapis dengan biaya yang terkendali.

## 5. Perbandingan dengan SALARAS

| Aspek | SALARAS (tt07-bep-decode) | SALARAS-BRIDGE |
| --- | --- | --- |
| Cakupan | Satu titik boundary | Dua tahap, serial dan CDC |
| Integritas | Verifikasi CRC yang ada | MAC pada tautan dan ECC pada FIFO |
| Domain clock | Tunggal | Dua domain |
| Relevansi Peruri | Rendah | Paling tinggi, jalur ingress lengkap |
| Area | Kecil | Paling besar, kemungkinan 1x2 |
| Kelengkapan | Sempit | End-to-end |

Plus dari ide ini:
- Memberi perlindungan berlapis dan paling lengkap.
- Sangat relevan untuk sistem identitas dan pembayaran.
- Memanfaatkan dua *baseline* resmi Area 04 sekaligus.

Minus dari ide ini:
- Area paling besar dan berisiko melebihi 1 *tile*.
- Verifikasi paling kompleks karena dua domain *clock* dan dua mekanisme integritas.
- Waktu pengerjaan paling panjang.

## 6. Kelayakan dan Possibility to Create

Kelayakan teknis: sedang, karena menggabungkan dua subsistem yang sudah ada.
Estimasi area: kemungkinan 1x2 *tile*.
Alat sama dengan SALARAS, ditambah *testbench* dua *clock* dan *loopback* serial.
Waktu: realistis bila difokuskan pada integrasi, bukan pada MAC penuh.
Risiko utama: area dan kompleksitas integrasi.

## 7. Simulasi Penjurian

| Kriteria | Bobot | Skor |
| --- | --- | --- |
| Relevansi Masalah | 15 | 88 |
| Kebaruan dan Keunggulan | 15 | 80 |
| Kualitas Teknis dan Arsitektur | 20 | 84 |
| Keamanan dan Threat Model | 20 | 86 |
| Kelayakan dan Verifikasi | 15 | 68 |
| Dampak dan Hilirisasi | 10 | 88 |
| Kepatuhan dan Kejelasan | 5 | 88 |
| Total tertimbang | 100 | 82.6 |

Pertanyaan kritis yang akan diajukan:
1. Apakah desain masih muat pada 1 *tile*, atau perlu 1x2?
2. Bagaimana membagi domain *clock* secara benar antara kedua tahap?
3. Apakah MAC pada tautan serial cukup ringan untuk area yang tersedia?
4. Bagaimana strategi verifikasi *end-to-end* dengan waktu *bootcamp* yang terbatas?

*Verdict*: ide paling lengkap namun paling berisiko pada area dan waktu.

## 8. Rekomendasi

- Mulai dari integrasi SerDes dan FIFO tanpa MAC penuh, lalu tambahkan MAC bila area tersisa.
- Tetapkan target 1x2 sejak awal untuk mengurangi risiko sintesis.
- Siapkan rencana bertahap: integrasi, lalu integritas, lalu penguatan.

## 9. Glosarium

- Bridge: rangkaian penghubung dua subsistem.
- ECC: kode yang dapat memperbaiki error.
- *End-to-end*: verifikasi dari ujung masukan sampai ujung keluaran.
- *Ingress*: jalur masuk data.
- MAC: nilai pemeriksa berkunci.
- SerDes: konverter serial dan paralel.
- CDC: perpindahan lintas domain *clock*.

## 10. Pertanyaan Terbuka

- Apakah target 1x2 dapat diterima untuk tahap *proposal*?
- Fitur mana yang diprioritaskan bila area tidak mencukupi?
