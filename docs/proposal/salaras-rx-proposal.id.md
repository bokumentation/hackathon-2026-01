# A Reusable, Fail-Closed Authenticated Ingress Boundary for Serial/RF Links

Kategori: IC Chip Design & FPGA Implementation

Area Fokus: 04 - Secure Communication (secure framing & interface integrity)

## 1. Ringkasan Ide (Executive Summary)

Masalah yang Diangkat:

Penerima *serial*/RF ringan menguraikan *bitstream* yang tidak tepercaya langsung ke *shift register* dan mengekspos *field* integritas ke *host* tanpa memvalidasinya.

Celah ini terukur pada *baseline* Manchester Tiny Tapeout 07, `tt07-bep-decode`: *field* integritas 24 bit (`tail_1..3`) diterima tetapi tidak pernah dicek, sehingga *payload* yang korup atau hasil *fault injection* tetap tampil sah bagi *host* (CWE-354).

Solusi yang Ditawarkan:

Sebuah *boundary* ingress yang *fail-closed* dan dapat dipakai ulang: MAC berkunci (SIMON-32/64, CBC-MAC panjang tetap) ditambah *counter* kesegaran, dan *commit* atomik.

*Boundary* menutup forgery (CWE-345), replay (CWE-294), de-sinkronisasi kendali/data (CWE-1264), *framing* tak sah (CWE-20), dan FSM yang macet (CWE-1245).

Chip yang Dirancang:

IP digital murni berukuran kecil dengan satu *clock* untuk cakupan yang dikomit, target ASIC sky130 dan FPGA DE10-Nano.

Target Pengguna:

Perancang *secure element* dan *smart card* *contactless*, *integrator* IP yang memerlukan blok *ingress-hardening*, serta tim *firmware* yang membutuhkan jaminan bahwa *frame* yang dibaca sudah terautentikasi.

Hasil Terukur:

- Verifikasi bit: 128 dari 128 *single-bit flip* ditolak.
- Forgery, kunci salah, replay, dan *counter* basi ditolak; 20 *frame* bersih diterima (false reject 0).
- Latensi ujung ke ujung 108 siklus *clock* (107 untuk MAC dan kesegaran, 1 untuk commit).
- Lima properti formal lolos, membuktikan sifat *fail-closed*.
- Lampiran RF: *hardening* sky130 nyata pada tile 1x2, die 0,0363 mm persegi, WNS 0,00, daya tipikal 1,21 mW.

Dampak:

*Frame* yang korup, dipalsukan, atau diputar ulang tidak lagi terlihat valid oleh *host*, dengan jaminan yang terukur dan dapat ditelusuri.

## 2. Latar Belakang & Rumusan Masalah (Problem Statement)

Latar Belakang:

Tautan *serial* dan RF membawa data antara *transceiver*, terminal, dan *host* pada sistem identitas dan pembayaran.

Pada rancangan ringan, *line coding* fisik (Manchester, 8b/10b) dianggap memadai, sehingga penerima memparsing *bitstream* yang tidak tepercaya dan tidak mengautentikasi *frame* apa pun.

Dua kelas kegagalan mengikuti.

Pertama, tidak ada validasi nilai integritas yang diterima (CWE-354): CRC atau ECC tanpa kunci mendeteksi error acak tetapi dapat dipalsukan oleh penyerang aktif, dan pemeriksaan yang tidak diimplementasikan tidak memberi jaminan apa pun.

Kedua, *commit* tidak atomik (CWE-1264): data dan kendali (`full`, *latch enable*) dapat terlepas di bawah *glitch* atau *jitter*.

FSM yang rapuh (CWE-1245) dan *input* tak tervalidasi (CWE-20) memperburuk keduanya.

Bukti dari Tautan Nyata:

*Baseline* `tt07-bep-decode` (Manchester 433 MHz, Tiny Tapeout 07) menerima *field* integritas 24 bit dan mengeksposnya ke *host* tanpa pemeriksaan.

Kami mereproduksi konsekuensinya dalam simulasi: *baseline* meng-*latch* *payload* yang korup dan *field* integritas yang korup dengan `full=1` (CWE-354, terukur).

*Field* tersebut bukan CRC standar, melainkan kode pengoreksi galat yang tidak terdokumentasi; hal ini dikonfirmasi penulis *baseline*, dan algoritmanya belum dipecahkan.

Kasus RF karena itu menjadi bukti kelas kerentanan, bukan jalur integritas kami yang sudah terpecahkan.

<figure class="proto"><img src="assets/sim-baseline-vulnerability.png" alt="Vulnerabilitas baseline"><figcaption>Gambar: `full` tetap tinggi untuk frame bersih, payload korup, dan field integritas korup (baseline `tt07-bep-decode`).</figcaption></figure>

Gap terhadap Solusi yang Tersedia:

| Pendekatan | Batas |
| --- | --- |
| *Parity* atau CRC byte | Mendeteksi error acak; tanpa framing; dapat dipalsukan |
| 8b/10b penuh | Hanya keseimbangan DC; tanpa integritas |
| Verifikasi *software* | Berjalan setelah data melewati batas kepercayaan |
| Dekoder standar | Memvalidasi hanya awal frame |
| MAC tanpa kesegaran | Tahan forgery tetapi dapat diputar ulang |

Tidak ada yang menggabungkan autentikasi, kesegaran, dan *commit* atomik *fail-closed* pada *boundary* secara hemat area.

Rumusan Masalah:

1. Bagaimana mengautentikasi *frame* yang diterima terhadap forgery (CWE-345)?
2. Bagaimana menolak *frame* yang diputar ulang tanpa state persisten (CWE-294)?
3. Bagaimana mengomit data dan kendali secara atomik *fail-closed*, sehingga pemeriksaan gagal tidak pernah mencapai *host* (CWE-1264, CWE-1245)?
4. Bagaimana menjadikannya inti yang dapat dipakai ulang pada *front-end* berbeda (Manchester/RF, SerDes, UART) dan pada FPGA maupun ASIC?

## 3. Proposed Chip Design

### 3.1 Arsitektur Sistem

<figure class="proto"><img src="assets/block-diagram-link.svg" alt="Arsitektur boundary autentikasi"><figcaption>Gambar: arsitektur boundary autentikasi (Tier A, satu clock).</figcaption></figure>

<figure class="proto"><img src="assets/frame-link.svg" alt="Format frame tautan"><figcaption>Gambar: format frame tautan dan rantai CBC-MAC.</figcaption></figure>

Rincian modul:

- `simon32_64.v`: blok cipher SIMON-32/64 terserialisasi, satu ronde per siklus.
- `l2_auth.v`: menghitung CBC-MAC atas counter ditambah payload (tiga blok 32 bit), membandingkan tag, dan memeriksa kesegaran counter.
- `l3_commit_gatekeeper.v`: mengomit secara atomik hanya saat autentikasi dan kesegaran lulus; jika gagal, menahan `host_full` dan menaikkan `fault` lengket.
- `salaras_auth_top.v`: integrasi L2 dan L3.
- `project.v`: pembungkus Tiny Tapeout dengan pemuat *frame* serial.

Antarmuka:

- Masukan: kunci 64 bit, counter 32 bit, payload 64 bit, tag 32 bit.
- Keluaran: `host_full`, `host_data`, `fault`, `auth_ok`, `fresh_ok`, `done`.
- *Handshake* `full` dan notifikasi `fault`; `fault` lengket hingga di-*acknowledge*.

Arsitektur Pemrosesan dan Memori:

- Aliran *streaming* satu arah; CBC-MAC berjalan sambil blok masuk.
- Tidak memerlukan *block RAM*; state hanya register (LFSR/MAC, counter, flag).

Konsumsi Daya:

- Logika digital *clock* tunggal, tanpa DSP, PLL internal, atau memori besar.
- MAC aktif hanya saat *frame* datang, sehingga aktivitas *switching* minimal saat *idle*.

### 3.2 Estimasi Penggunaan Resource

Estimasi FPGA (Yosys, sebelum sintesis Quartus):

| Komponen | Estimasi | Kapasitas DE10-Nano |
| --- | --- | --- |
| *Logic elements* / LUT | sekitar 360 LUT-setara | 41.910 ALM |
| Register / flip-flop | 500 | 415.000 |
| *Block RAM* (M10K) | 0 | 5.570 Kbit |
| DSP | 0 | 112 |

Target ASIC: Tiny Tapeout sky130 130nm via OpenLane.

Lampiran RF memiliki hasil nyata: tile 1x2, die 0,0363 mm persegi, WNS 0,00, daya tipikal 1,21 mW.

*Hardening* sky130 untuk tautan baru: tile 2x2, die 0,0756 mm persegi, 2354 sel, DRC 0, LVS 0, WNS 0,00, daya tipikal 1,87 mW.

Perangkat Lunak dan Tools:

- Intel Quartus Prime (sintesis, fit, *timing*, SignalTap) untuk DE10-Nano.
- OpenLane dan Yosys untuk jalur ASIC sky130.
- Verilator dan Icarus Verilog untuk simulasi dan lint.
- cocotb dan pytest untuk testbench otomatis.
- SymbiYosys untuk pembuktian formal.

### 3.3 Rencana Pengujian

Simulasi RTL (S1, terukur):

- Testbench cocotb men-*drive* MAC, L2, dan *commit* dengan matriks keberhasilan: *frame* bersih diterima, forgery, kunci salah, replay, dan *counter* basi ditolak, serta 128 dari 128 *single-bit flip* ditolak.
- Latensi diukur per tahap: 33 siklus per blok SIMON, 107 siklus untuk MAC dan kesegaran, 108 siklus ujung ke ujung.

<figure class="proto"><img src="assets/sim-auth-commit.png" alt="Autentikasi dan commit"><figcaption>Gambar: satu frame bersih diterima dan satu frame korup ditolak pada boundary autentikasi.</figcaption></figure>

<figure class="proto"><img src="assets/sim-boundary-timeout.png" alt="Timeout L1"><figcaption>Gambar: fault timeout pada jalur batas (bukti lampiran RF).</figcaption></figure>

Uji Hardware Board FPGA DE10-Nano (S2, rencana):

- *Prosedur sintesis*: proyek Quartus dengan pembungkus board, SDC, dan pin assignment.
- *Implementasi bitstream* (.sof/.rbf) dan pengujian *on-board real-time*.
- Verifikasi sinyal internal dengan SignalTap pada `auth_ok`, `fresh_ok`, `done`, `host_full`, dan `fault`.
- Pengujian *on-board* menunjukkan *frame* bersih diterima dan *frame* korup ditolak.
- Fasilitas FPGA/sandbox dari penyelenggara dipakai pada *bootcamp* untuk menjalankan tahap ini.

Metrik Keberhasilan Target:

| Metrik | Target | Bukti |
| --- | --- | --- |
| Deteksi error satu bit | 100 persen | Simulasi (128/128) |
| False reject | 0 persen | Simulasi (20 frame bersih) |
| Forgery dan replay | ditolak | Simulasi |
| Latensi ujung ke ujung | terukur 108 siklus | Simulasi |
| *Fail-closed* | terbukti formal | SymbiYosys |

## 4. Referensi

- PERURI. "Buku Panduan Peserta PERURI Chip Hackathon 2026." https://summit.peruri.co.id/docs/Buku-Panduan-PERURI-Chip-Hackathon.pdf
- Kohnen, Z. "Decoding Manchester coded transmissions in a fully digital ASIC." Skripsi, 2024.
- Kohnen, Z. dan Alvarado, A. "Manchester decoder of a home thermostat's wireless protocol." FSiC, 2025.
- Beaulieu, R. et al. "The SIMON and SPECK Families of Lightweight Block Ciphers." IACR ePrint 2013/404.
- Tiny Tapeout. https://tinytapeout.com/
- MITRE. CWE-354, CWE-345, CWE-294, CWE-1264, CWE-1245, CWE-20.
- Terasic. "DE10-Nano - Cyclone V FPGA Guide."

## 5. Lampiran

### Lampiran A. Tim & Pembagian Peran

| Nama | Keahlian | Peran |
| --- | --- | --- |
| Ibrahim Fauzi Rahman | RTL / Verilog | Perancang RTL, integrasi, sintesis |
| Idris Syaifulloh | Verifikasi / Python | cocotb, *fault injection*, metrik |
| Dr. Setia Jul Ismail, S.T., M.T. | Arsitektur / Metodologi | Pembimbing, validasi klaim |

### Lampiran B. Luaran & Demo

- Kode RTL Verilog, *script* testbench cocotb, dan properti formal.
- Bitstream FPGA (.sof/.rbf) dan demo *on-board* (rencana *bootcamp*).
- Repository sumber dan laporan teknis singkat.

### Lampiran C. Rencana Bootcamp (18-20 Oktober 2026)

| Hari | Fokus | Deliverable |
| --- | --- | --- |
| Hari 1 | Finalisasi RTL tautan, integrasi SerDes, mulai analisis kriptografi lanjutan | RTL dapat disimulasikan |
| Hari 2 | Sintesis Quartus, SignalTap, uji *fault injection* dan replay *on-board* | Bitstream dan laporan resource/timing |
| Hari 3 | Pengukuran akhir, poles *hardening*, demo, presentasi Top 5 ke Top 3 | Demo dan materi presentasi |

### Lampiran D. Anggaran Latensi (terukur)

| Tahap | Nilai |
| --- | --- |
| Blok SIMON | 33 siklus |
| MAC dan kesegaran | 107 siklus |
| Commit | 1 siklus |
| Ujung ke ujung | 108 siklus |

### Lampiran E. Perbandingan Integritas (terukur)

| Properti | CRC tanpa kunci | MAC berkunci | MAC + counter |
| --- | --- | --- | --- |
| Latensi | 73 siklus | 107 siklus | 108 siklus |
| Deteksi error acak | ya | ya | ya |
| Ketahanan forgery | tidak | ya | ya |
| Ketahanan replay | tidak | tidak | ya |

### Lampiran F. Bukti Masalah (RF)

*Baseline* `tt07-bep-decode` menerima `payload` dan *field* integritas yang korup dengan `full=1` (CWE-354, terukur). Rincian pada `sim/RESULTS.md`.

### Lampiran G. Batasan

- Tidak ada provisi kunci, ketahanan replay lintas siklus daya, atau ketahanan kanal samping.
- Tidak ada klaim kriptografis penuh; tag 32 bit memberi peluang forgery sekitar 2 pangkat -32.
- Tautan serial dan CDC adalah tahap berikutnya; angka FPGA menunggu sintesis Quartus.

### Lampiran H. Uji Hardware Board FPGA DE10-Nano

- Papan: Terasic DE10-Nano, Cyclone V SoC (5CSEBA6U23I7), dengan Quartus Prime.
- *Clock*: `CLOCK_50` 50 MHz secara langsung, satu *clock domain*.
- Prosedur: sintesis (`quartus_sh --flow compile`), unggah *bitstream* (.sof/.rbf), dan pengujian *on-board real-time*.
- Pemuatan *frame*: geser 192 bit (kunci 64, counter 32, payload 64, tag 32) melalui GPIO; inti memuat kunci lalu memulai MAC.
- SignalTap: `auth_ok`, `fresh_ok`, `done`, `host_full`, `fault`.
- Uji *on-board*: *frame* bersih diterima (`host_full` naik), *frame* korup ditolak (`host_full` rendah, `fault` naik), replay tidak dikomit.
- Laporan: Fitter (ALM/FF/M10K/DSP), Timing Analyzer (Fmax, WNS), dan PowerPlay.
- Fasilitas FPGA/sandbox penyelenggara dipakai pada *bootcamp*.
