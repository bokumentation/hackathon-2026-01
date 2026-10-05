# Analisis Kelayakan dan Simulasi Penjurian SALARAS-RX

Kategori: IC Chip Design & FPGA Implementation  
Area Fokus: 04 - Secure Communication (secure framing & interface integrity)  
Dokumen: analisis kelayakan internal pra-kurasi PERURI Chip Hackathon 2026  
Objek: `docs/proposal/salaras-rx-proposal.id.md`  
*Baseline*: `tt07-bep-decode`, `TT_UM_SERDES`, `tt07_cdc_fifo`  
Tanggal: 4 Oktober 2026

## Ringkasan Eksekutif

SALARAS-RX layak secara teknis dan dapat diverifikasi, dengan satu revisi keamanan yang bersifat wajib.

Tiga temuan utama:
- Field integritas pada *baseline* bersifat affine (linear ditambah konstanta), tetapi tidak cocok dengan CRC-24 standar mana pun; penulis *baseline* menduga kode koreksi galat (ECC), sehingga L2 layak dikerjakan dengan catatan parameter perlu direkonstruksi.
- Klaim keamanan saat ini terlalu kuat, karena CRC bukan kontrol kriptografis dan penyerang pada jalur *ingress* dapat memalsukan CRC yang valid.
- Kepatuhan struktur proposal sudah lengkap untuk 5 struktur wajib, tetapi jumlah halaman (12) melampaui batas 6 halaman yang disebut pada laman kompetisi.

Hasil simulasi *panel* penjurian profesional menghasilkan rata-rata 72.83 dari 100 dengan *verdict* layak melaju apabila revisi keamanan P0 dikerjakan.

## 1. Metodologi

Analisis meninjau tiga sumber utama.
Pertama, proposal final `salaras-rx-proposal.id.md` beserta arsitektur L1, L2, dan L3, prototipe S1 dan S2, serta metrik keberhasilan.
Kedua, *baseline* RTL `tt07-bep-decode` pada `baseline/tt07-bep-decode`, termasuk `state_machine.v`, `serial_decode.v`, dan `data_validate.v`, ditambah data uji pada `test/data`.
Ketiga, ketentuan kompetisi pada `docs/competition/ketentuan-proposal.md`, `buku-panduan-peruri-chip-hackathon.md`, dan `peruri-chip-hackathon-2026.md`.

Untuk menguji kelayakan L2, dilakukan pemeriksaan empiris read-only terhadap pasangan (*payload*, tail) yang diekstrak dari `baseline/tt07-bep-decode/test/test.py`.
Pemeriksaan menguji delapan varian CRC-24 yang umum, lalu diperluas menjadi pencarian menyeluruh atas seluruh polinomial 24-bit ganjil (2^23) dengan variasi refIn/refOut, urutan bit, dan urutan byte; tidak ada yang cocok.

Rubrik penjurian pada Bagian 6 tidak dipublikasikan oleh penyelenggara, sehingga bobot dan kriteria disusun sebagai asumsi yang masuk akal berdasarkan 5 struktur proposal dan aturan teknis.

## 2. Kelayakan Teknis

### 2.1 Baseline tt07-bep-decode

*Baseline* adalah *decoder* Manchester Tiny Tapeout 07 berukuran 1x1 *tile* dengan *clock* 20 kHz.
*Frame* berjumlah 192 bit, yaitu 96 bit *header* (*preamble*, type, constant) ditambah 96 bit data, di mana 96 bit data memuat *payload* 72 bit (thermostat_id 32, room_temp 16, set_temp 16, state 8) dan field integritas 24 bit (`tail_1..3`).
*Baseline* memvalidasi *header* melalui `data_validate` dan mengekspos field integritas ke *host* tanpa memeriksanya, ditandai komentar `// CRC?`.
Struktur ini bersih dan modular sehingga titik sisip *boundary* L1 sampai L3 jelas, yaitu pada jalur antara front-end `state_machine` dan `frame_capture` (yang memuat `data_validate`).
Kesimpulan: *baseline* layak sebagai fondasi.

### 2.2 L1 Framing dan FSM Validator

L1 memperluas `data_validate` dan memanfaatkan *timer* `half_period` yang sudah ada pada `state_machine`.
Pekerjaan tambahan berupa *timing* window, default/recovery branch, dan *timeout* *counter* adalah logika kecil yang tidak mengubah antarmuka.
Karena validasi *header* sudah ada, risiko integrasi L1 rendah.
Kesimpulan: layak dengan risiko rendah.

### 2.3 L2 Integrity Verify (temuan kunci)

Field integritas tidak cocok dengan delapan varian CRC-24 umum (OPENPGP, FLEXRAY-A/B, BLE, LTE-A/B, OS-9, INTERLAKEN) maupun dengan pencarian menyeluruh atas seluruh polinomial 24-bit ganjil pada berbagai bentuk byte dan urutan bit.
Meskipun demikian, terdapat bukti kuat bahwa field tersebut bersifat affine.
Dua perubahan satu bit yang independen pada `set_temp` (LSB, yaitu varian low ke high) menghasilkan delta tail yang identik, yaitu `E6 02 40`, pada dua transmisi yang berbeda.
Sifat ini menunjukkan pemetaan affine dari bit *payload* ke field integritas; penulis *baseline* juga melaporkan tidak menemukan CRC yang cocok dan menduga kode koreksi galat (ECC).
Kendala: dengan 7 pasangan yang tersedia, hanya 13 posisi bit yang bervariasi dan rank delta GF(2) hanya 5, sehingga pemetaan penuh belum dapat direkonstruksi.
Implikasinya, L2 layak tetapi menunggu data: perlu banyak pasangan (*payload*, tail) tambahan dengan variasi satu bit terkontrol melalui *replay* ESP32 agar rank delta mencapai ukuran *payload*, lalu pemetaan diselesaikan dengan aljabar linear atas GF(2).
Risiko: sedang, dengan catatan pemulihan parameter sebagai *milestone* utama pada *bootcamp*.
Kesimpulan: layak, dengan pemulihan field sebagai risiko terbesar.

### 2.4 L3 Atomic Commit Gatekeeper

L3 adalah logika kombinasional dan *latch* untuk menggerbangi `full` dan *latch* enable serta menyetel `fault`.
Implementasinya kecil dan tidak memerlukan *buffer* tambahan.
Pin `uio[6]` atau `uio[7]` tersedia untuk `fault` sesuai `info.yaml` *baseline*.
Kesimpulan: layak dengan risiko rendah.

### 2.5 Timing dan clock

*Baseline* dikalibrasi untuk *clock* 20 kHz dengan half-period 9 tick.
DE10-Nano berjalan pada 50 MHz, sehingga diperlukan pembagi *clock* 2500 atau parameterisasi ulang konstanta *timing*.
Keduanya merupakan pekerjaan standar.
Prototipe S2 memakai *replay* pada laju yang sama dengan capture 20 kHz, sehingga sinyal deterministik.
Kesimpulan: layak.

### 2.6 Area dan pin

*Baseline* menempati 1x1 *tile*.
Tambahan L2 berupa LFSR 24 bit dan pembanding, ditambah L1 dan L3, adalah beberapa puluh *flip-flop* dan sejumlah kecil gerbang logika.
Hasil *hardening* sky130 menempatkan rancangan pada tile 1x2 karena 1x1 melampaui area pada 105.57% utilisasi *placement*.
Area die 0.0363 mm^2, timing terpenuhi (WNS 0.00 ns), dan daya tipikal 1.21 mW.
Pin cukup karena `fault` memakai uio yang belum terpakai.
Kesimpulan: layak, dengan *fallback* 1x2 yang terkonfirmasi.

### 2.7 Prototipe S1 dan S2

S1 memakai cocotb dengan *golden vector* dari capture *baseline*, sehingga pengujian cepat dan deterministik.
S2 memakai ESP32 dengan peripheral RMT untuk me-*replay* capture ke `digital_in` DE10-Nano pada *level 3.3 V*, lalu *host* membaca `uo_out`, `full`, dan `fault` melalui USB-UART.
*Fault injection* *single-bit* flip dilakukan pada *buffer* *replay*.
Keduanya tidak memerlukan tautan RF sehingga dapat diprediksi dan direproduksi.
Kesimpulan: layak dan terukur.

### 2.8 Tooling

Verilator, Icarus, cocotb, Yosys, OpenLane, dan Quartus Prime semuanya diizinkan dan tersedia.
Kesimpulan: layak.

## 3. Kelayakan Verifikasi

Setiap klaim metrik dipetakan ke satu skenario uji.

| Klaim | Skenario uji | Status kelayakan |
| --- | --- | --- |
| Detection rate 100% | Fault injection single-bit flip pada payload dan integritas di S1 dan S2 | Layak, bergantung pada L2 |
| False-reject 0% | Seluruh capture bersih, termasuk start termutilasi valid | Layak, perilaku baseline dipertahankan |
| Latency 1 siklus | Pengukuran siklus commit pada RTL | Layak, terukur |
| Area 1x2 | Laporan OpenLane | Terkonfirmasi (1x1 melampaui 105.57%) |
| Fail-closed | Uji frame korup dan pengecekan `full` dan `fault` | Layak |

Kesenjangan verifikasi: belum ada pengujian *adversarial* berupa *forgery*, yaitu penyerang yang menghitung ulang CRC yang valid.
Pengujian saat ini membuktikan ketahanan terhadap error acak dan *fault injection*, bukan terhadap penyerang aktif.

## 4. Kelayakan Keamanan (kritik)

Temuan kritis: CRC bukan kontrol integritas kriptografis.
CRC bersifat linear dan tanpa kunci, sehingga penyerang yang memiliki akses pada jalur *ingress* dapat mengubah *payload* lalu menghitung ulang CRC yang sah.
*Threat model* pada proposal menyatakan penyerang memiliki akses pada jalur *ingress*.
Konsekuensinya, mitigasi CWE-354 saat ini hanya melindungi dari korupsi acak dan *fault injection*, bukan dari pemalsuan yang disengaja.
Standar ISO/IEC 7816 dan e-KTP melindungi integritas melalui secure messaging dengan MAC berbasis kunci, bukan CRC.
Pemetaan CWE-1245 dan CWE-1264 lebih kuat, karena atomic *commit* dan hardening FSM benar-benar menutup celah de-sinkronisasi kontrol atau data.
Rekomendasi: nyatakan ruang lingkup keamanan secara jujur sebagai integritas terhadap error dan *fault* pada lapis transport, dan tempatkan MAC atau *keyed integrity* sebagai pengembangan lanjutan.
Alternatifnya, tambahkan lapis MAC ringan bila waktu memungkinkan, meskipun ini menambah area dan mengubah format *frame*.

## 5. Kelayakan Kompetisi

Struktur: proposal sudah memuat 5 struktur wajib secara berurutan, yaitu Ringkasan Ide, Latar Belakang dan Rumusan Masalah, Proposed Chip Design, Referensi, dan Lampiran.
Area: pemilihan Area 04 sudah tepat dan selaras dengan laman resmi yang menyebut SerDes dan CDC FIFO.
Aturan teknis: *security-by-design* sudah menjadi fondasi melalui bagian `Security Design` di dalam Proposed Chip Design, bukan tempelan di akhir.
Halaman: proposal berjumlah 12 halaman, sedangkan laman kompetisi menyebut batas 6 halaman di luar cover, daftar pustaka, dan lampiran teknis.
Karena ini adalah risiko kurasi, disarankan menyiapkan versi ringkas 6 halaman inti dengan memindahkan rincian ke lampiran.
*Timeline*: tenggat proposal 8 Oktober 2026 dan *bootcamp* 18 sampai 20 Oktober 2026, sehingga pemulihan CRC harus diselesaikan lebih awal.

## 6. Simulasi Penjurian

Simulasi melibatkan lima *persona* juri profesional dengan latar berbeda.
Rubrik memakai tujuh kriteria dengan bobot sebagai berikut: Relevansi Masalah 15, Kebaruan dan Keunggulan 15, Kualitas Teknis dan Arsitektur 20, Keamanan dan *Threat Model* 20, Kelayakan Implementasi dan Verifikasi 15, Dampak dan Hilirisasi 10, serta Kepatuhan dan Kejelasan 5.

### 6.1 Persona dan catatan

Juri 1, pakar keamanan perangkat keras.
Catatan: mengapresiasi *fail-closed* dan atomic *commit*, tetapi mempertanyakan klaim keamanan berbasis CRC terhadap penyerang aktif.
Skor total: 66.00.

Juri 2, pakar RTL dan ASIC.
Catatan: arsitektur rapi dan hemat, tetapi meminta bukti sintesis area serta rencana *fallback* 1x2.
Skor total: 75.00.

Juri 3, pakar sistem dan FPGA.
Catatan: prototipe S1 dan S2 jelas dan deterministik, tetapi mengingatkan kalibrasi *clock* 20 kHz dan penanganan *timing* pada board.
Skor total: 75.85.

Juri 4, juri produk dan hilirisasi.
Catatan: relevansi dengan *secure element* dan e-KTP kuat secara naratif, namun perlu kejelasan jalur adopsi dan batas antara prototipe dan produk.
Skor total: 71.25.

Juri 5, juri kompetisi dan kepatuhan.
Catatan: struktur lengkap, area tepat, tetapi menyoroti batas 6 halaman dan ketergantungan pada pemulihan CRC.
Skor total: 76.05.

### 6.2 Rekapitulasi skor

| Kriteria | Bobot | J1 | J2 | J3 | J4 | J5 |
| --- | --- | --- | --- | --- | --- | --- |
| Relevansi Masalah | 15 | 80 | 85 | 85 | 80 | 85 |
| Kebaruan dan Keunggulan | 15 | 60 | 65 | 65 | 60 | 68 |
| Kualitas Teknis dan Arsitektur | 20 | 75 | 80 | 78 | 70 | 78 |
| Keamanan dan Threat Model | 20 | 45 | 70 | 70 | 65 | 72 |
| Kelayakan dan Verifikasi | 15 | 70 | 75 | 82 | 75 | 80 |
| Dampak dan Hilirisasi | 10 | 65 | 70 | 72 | 80 | 70 |
| Kepatuhan dan Kejelasan | 5 | 80 | 85 | 85 | 80 | 82 |
| Total tertimbang | 100 | 66.00 | 75.00 | 75.85 | 71.25 | 76.05 |

Rata-rata *panel*: 72.83 dari 100.

### 6.3 Pertanyaan kritis yang akan diajukan

1. Bagaimana Anda membuktikan bahwa field integritas benar-benar CRC dan bukan *checksum* lain?
2. Apa yang terjadi bila penyerang menghitung ulang CRC setelah mengubah *payload*?
3. Berapa area hasil sintesis dan apakah tetap muat 1x1 *tile*? (sudah dijawab: tile 1x2, area die 0.0363 mm^2, 1x1 melampaui 105.57%)
4. Bagaimana kalibrasi *clock* 20 kHz terhadap DE10-Nano 50 MHz dan pengaruhnya pada *latency*?
5. Apa rencana bila polinomial dan *seed* CRC tidak ditemukan sebelum *bootcamp*?
6. Mengapa memakai tt07-bep-decode alih-alih SerDes atau CDC FIFO yang disebut untuk Area 04?

### 6.4 Verdict

Kualitas proposal berada pada kategori layak dengan skor 72.83 dari 100.
Proposal berpotensi melaju ke *bootcamp* apabila tiga hal dikerjakan: memperjelas ruang lingkup keamanan, menyiapkan rencana risiko pemulihan CRC, dan menyiapkan versi ringkas 6 halaman.
Tanpa revisi keamanan, risiko eliminasi pada tahap *bootcamp* oleh juri keamanan cukup tinggi.

## 7. Rekomendasi Perbaikan

P0, wajib sebelum kurasi:
- Nyatakan ruang lingkup integritas sebagai proteksi terhadap error dan *fault*, dan jelaskan bahwa CRC bukan kontrol terhadap penyerang aktif.
- Tambahkan rencana risiko dan *milestone* pemulihan parameter CRC pada Hari 1 *bootcamp*.
- Siapkan versi ringkas 6 halaman inti, dengan rincian dipindahkan ke lampiran.

P1, penting:
- Tambahkan penjelasan singkat mengapa `tt07-bep-decode` dipakai alih-alih SerDes atau CDC FIFO, dengan mengacu pada irisan keamanan Area 04.
- Siapkan rencana *fallback* area 1x2 dan estimasi *resource* setelah sintesis.
- Tambahkan tabel traceability metrik ke test case pada lampiran teknis.

P2, nilai tambah:
- Usulkan MAC atau *keyed integrity* ringan sebagai pengembangan lanjutan.
- Lengkapi skenario *forgery* test untuk menunjukkan kesadaran terhadap batas CRC.
- Perkuat jalur adopsi dan pemisahan antara prototipe dan produk.

## 8. Lampiran

### Lampiran A. Bukti linearitas field integritas

Perubahan satu bit pada `set_temp` (LSB) menghasilkan delta tail yang identik pada dua transmisi berbeda:

| Transmisi | Delta payload | Delta tail |
| --- | --- | --- |
| super_long low ke high | 0x0001 pada set_temp | E6 02 40 |
| repeating low ke high | 0x0001 pada set_temp | E6 02 40 |

Delta yang identik menunjukkan pemetaan affine, yang konsisten dengan CRC atau *checksum* linear.

### Lampiran B. Pasangan data uji yang dipakai

| Sumber | thermostat_id | room_temp | set_temp | state | tail (t1,t2,t3) |
| --- | --- | --- | --- | --- | --- |
| single | 03391F89 | 00F6 | 00B5 | 00 | 94 AE 16 |
| super_long low | 02391F89 | 0116 | 0104 | 00 | B0 86 0E |
| super_long high | 02391F89 | 0116 | 0105 | 00 | 56 84 4E |
| repeating low | 03391F89 | 0112 | 00B4 | 00 | DA FB 46 |
| repeating high | 03391F89 | 0112 | 00B5 | 00 | 3C F9 06 |
| long_turn_off | 02391F89 | 0114 | 0000 | 00 | 48 90 BE |
| start_mangled | 02391F89 | 0110 | 0104 | 00 | AE 87 5A |

### Lampiran C. Rujukan

- Proposal SALARAS-RX, `docs/proposal/salaras-rx-proposal.id.md`.
- *Baseline* `tt07-bep-decode`, `baseline/tt07-bep-decode`.
- Ketentuan kompetisi, `docs/competition/ketentuan-proposal.md`.
- Buku Panduan Peserta PERURI Chip Hackathon 2026.
- Laman resmi Tiny Tapeout 07 untuk `tt_um_serdes` dan `tt_um_pa1mantri_cdc_fifo`.
