# TRI-ARGA: Gerbang *Ingress* Terotentikasi dan Tahan *Replay* untuk Tautan Serial Ringan

Kategori: IC Chip Design & FPGA Implementation

Area Fokus: 04 - *Secure Communication* (*secure framing* & *interface integrity*) [1]

## 1. Ringkasan Ide (*Executive Summary*)

**Masalah yang Diangkat:**

Penerima serial dan RF ringan mengurai *bitstream* tak tepercaya langsung ke dalam register, kemudian meneruskan *field* integritas ke *host* tanpa pernah memeriksanya. Pada *baseline* Manchester Tiny Tapeout 07 `tt07-bep-decode` [4], [5], [6], tim mengukur bahwa *payload* korup dan *field* integritas korup tetap diteruskan dengan `full=1` (CWE-354) [14]. Tanpa kunci dan *counter*, penerima semacam itu juga tidak mampu membedakan *frame* asli dari *frame* palsu maupun *frame* lama yang diputar ulang [12].

**Solusi yang Ditawarkan:**

Gerbang *ingress fail-closed* dengan tiga lapis pertahanan dalam satu inti:

1. L1 pemuat *frame*: menggeser *frame* 128 bit (*counter* + *payload* + *tag*) dan kunci 64 bit secara serial, dengan kunci *write-once* yang terkunci sampai *reset* (CWE-20) [14].
2. L2 autentikasi: MAC berkunci SIMON-32/64 [7] mode CBC-MAC panjang tetap [9], ditambah pemeriksaan *counter* monoton (CWE-345, CWE-354, CWE-294) [14].
3. L3 *commit* atomik: data dan `host_full` dilepas bersamaan dalam satu siklus, hanya jika autentikasi dan kesegaran lulus; jika gagal, `fault` menyala dan bersifat lengket sampai di-*acknowledge* (CWE-1264, CWE-1245) [14].

Selain inti tersebut, sebuah tautan serial 8b/10b (Tier B) telah dibangun [2] dan diuji dengan *loopback* satu *clock* melalui inti L2+L3. Dalam *loopback* tersebut, *frame* bersih berhasil dikomit, sedangkan *forgery*, *replay*, dan *line error* ditolak.

**Chip yang Dirancang:**

IP digital murni, satu domain *clock*, tanpa *block RAM* dan DSP. Inti bersifat agnostik terhadap *front-end*, sehingga dapat dipasang di belakang *baseline* resmi Area 04 TT07 SerDes [2], dekoder Manchester/RF, maupun UART. Target: ASIC sky130 (Tiny Tapeout) [11] dan FPGA DE10-Nano [13].

**Implementasi pada DE10-Nano:**

Prototipe dipetakan ke *fabric* Cyclone V tanpa HPS. *Clock* `CLOCK_50` (50 MHz) digunakan langsung dalam satu domain *clock*. Demonstrasi *on-board* memakai *loopback* internal: `link_tx` mengirim *frame* ke `link_rx` melalui inti L2+L3, dan saklar memilih kasus bersih, korup, atau *replay*. Status `host_full`, `fault`, `auth_ok`, `fresh_ok`, `done`, dan `key_locked` diamati melalui LED dan SignalTap. Tidak ada perangkat eksternal dan tidak ada *clock* kedua.

**Target Pengguna:**

Perancang *secure element* dan perangkat identitas, integrator IP yang membutuhkan blok *ingress-hardening*, serta tim *firmware* yang memerlukan jaminan bahwa *frame* yang dibaca oleh *host* telah terotentikasi.

**Hasil Terukur:**

| Metrik | Hasil | Sumber |
| --- | --- | --- |
| *Single-bit flip* pada *frame* | 128/128 ditolak | Simulasi cocotb |
| *Forgery*, kunci salah, *replay*, *counter* basi | Semua ditolak | Simulasi cocotb |
| *False reject* | 0 dari 20 *frame* bersih | Simulasi cocotb |
| Latensi ujung ke ujung | 108 siklus (2,16 µs pada 50 MHz) | Simulasi |
| *Loopback* tautan serial (Tier B) | *Commit* bersih; *forgery*/*replay*/*line error* ditolak | Simulasi cocotb |
| Properti *fail-closed* | 9 *job* lolos (5 inti, 1 Tier B, 3 lampiran RF) | SymbiYosys |
| *Hardening* sky130 (inti) | Tile 2×2, 0,0756 mm², 2511 sel, DRC 0, LVS 0, WNS 0,00, 2,10 mW | OpenLane |
| *Hardening* sky130 (Tier B) | Tile 2×2, 3220 sel, 2 pelanggaran antena, WNS 0,00, 3,61 mW | OpenLane |
| Sintesis FPGA | 421 ALM, 1029 FF, 0 M10K, 0 DSP, Fmax 97,9 MHz | Quartus 25.1 |
| Daya FPGA | 426,2 mW total, 3,76 mW dinamis inti | PowerPlay |

**Dampak:**

*Frame* yang korup, dipalsukan, atau diputar ulang tidak lagi tampak sah bagi *host*. Pemeriksaan berlangsung di *hardware*, sebelum data melewati batas kepercayaan, dengan biaya kurang dari 0,08 mm² dan 2,1 mW.

## 2. Latar Belakang & Rumusan Masalah (*Problem Statement*)

### 2.1 Latar Belakang

Tautan serial dan RF membawa data antara *transceiver*, terminal, *secure element*, dan *host* pada sistem identitas dan pembayaran. Pada rancangan ringan, *line coding* fisik (Manchester, 8b/10b) sering dianggap sudah memadai, sehingga penerima mengurai *bitstream* tak tepercaya tanpa mengautentikasi *frame* apa pun.

Tiga kelas kegagalan yang mengikuti kondisi tersebut adalah sebagai berikut:

1. Integritas tidak divalidasi (CWE-354, CWE-345) [14]. CRC atau ECC tanpa kunci hanya mendeteksi galat acak. Penyerang aktif dapat menghitung ulang nilai tersebut untuk *frame* palsu. Pemeriksaan yang tidak diimplementasikan sama sekali tidak memberikan jaminan apa pun.
2. *Replay* (CWE-294) [14]. *Frame* lama yang sah tetap diterima jika tidak ada penanda kesegaran. Serangan *replay* dan *jamming-replay* pada *remote* 433 MHz, yang dikenal melalui demonstrasi RollJam (Kamkar, 2015) [12], membuktikan bahwa kelas serangan ini bersifat praktis pada tautan RF murah.
3. *Commit* tidak atomik (CWE-1264), FSM rapuh (CWE-1245), dan masukan tidak tervalidasi (CWE-20) [14]. Data dan sinyal kendali (`full`, *latch enable*) dapat terlepas satu sama lain, sehingga *host* berpotensi membaca data yang belum selesai diperiksa.

Verifikasi melalui *software* tidak menutup celah ini karena *software* berjalan setelah data sudah melewati batas kepercayaan.

### 2.2 Bukti dari Tautan Nyata

Tim menggunakan `tt07-bep-decode` (dekoder Manchester 433 MHz, Tiny Tapeout 07) [4], [5], [6] sebagai contoh terukur, bukan sebagai desain yang cacat untuk tujuan aslinya. Desain tersebut memang tidak mengklaim keamanan, dan justru karena itulah ia mewakili pola umum pada penerima ringan.

- *Baseline* menerima *field* integritas 24 bit (`tail_1..3`) dan meneruskannya ke *host* tanpa pemeriksaan.
- Dalam simulasi, *baseline* meng-*latch* *payload* korup dan *field* integritas korup dengan `full=1` (CWE-354, terukur; rincian di Lampiran F).
- *Field* tersebut merupakan kode pengoreksi galat yang tidak terdokumentasi (dikonfirmasi oleh penulis *baseline*) dan algoritmanya belum berhasil dipecahkan. Oleh karena itu, kasus RF digunakan sebagai bukti kelas kerentanan, bukan sebagai jalur integritas yang diklaim telah diperbaiki.

Bentuk gelombang yang menggambarkan kondisi tersebut tersedia di Lampiran F, Gambar F.1.

### 2.3 Kesenjangan terhadap Solusi yang Tersedia

Saat ini belum ada blok hemat area yang menggabungkan autentikasi, kesegaran, dan *commit* atomik *fail-closed* tepat di batas *ingress*.

| Pendekatan | Yang ditangani | Yang tidak ditangani |
| --- | --- | --- |
| *Parity* atau CRC | Galat acak | *Forgery*, *replay*, *framing* |
| 8b/10b penuh | Keseimbangan DC, sinkronisasi | Integritas konten *frame* |
| Dekoder standar | Validasi awal *frame* | Isi *frame* |
| Verifikasi *software* | Fleksibel | Berjalan setelah batas kepercayaan dilewati |
| MAC tanpa kesegaran | *Forgery* | *Replay* |
| AEAD penuh (mis. Ascon) | *Forgery* dan kerahasiaan | Kesegaran dan *commit gating* tetap perlu dirancang; area lebih besar |
| TRI-ARGA | *Forgery*, *replay*, *commit* atomik *fail-closed* | Kerahasiaan (di luar cakupan, lihat Lampiran G) |

### 2.4 Rumusan Masalah

1. Bagaimana cara mengautentikasi *frame* yang diterima terhadap *forgery* dengan anggaran area yang sesuai untuk Tiny Tapeout (CWE-345) [14]?
2. Bagaimana cara menolak *frame* yang diputar ulang dalam satu sesi daya, tanpa memori *non-volatile* (CWE-294) [14]?
3. Bagaimana cara mengomit data dan kendali secara atomik dan *fail-closed*, sehingga *frame* yang gagal diperiksa tidak pernah terlihat oleh *host* (CWE-1264, CWE-1245) [14]?
4. Bagaimana menjadikan inti ini dapat dipakai ulang di belakang berbagai *front-end*, khususnya *baseline* resmi TT07 SerDes [2], baik pada FPGA maupun ASIC?

## 3. Proposed Chip Design

TRI-ARGA adalah satu inti digital satu *clock* yang berada di antara *front-end* tak tepercaya dan *host*: *frame* masuk, diautentikasi, diperiksa kesegarannya, kemudian dilepas secara atomik atau ditolak.

### 3.1 Solusi & Arsitektur Sistem

<figure class="proto"><img src="assets/block-diagram.svg" alt="Arsitektur boundary autentikasi"><figcaption>Gambar 1. Arsitektur TRI-ARGA: batas kepercayaan, tiga lapis, jalur kunci terpisah. Semua yang datang dari tautan dianggap tak tepercaya; kunci masuk dari *host* melalui jalur terpisah, dan hanya L3 yang diizinkan melepas data ke *host*.</figcaption></figure>

Diagram format *frame* dan rantai CBC-MAC tersedia di Lampiran I, Gambar I.1.

**Format *frame* (128 bit + kunci terpisah):**

| *Field* | Lebar | Fungsi |
| --- | --- | --- |
| *Counter* | 32 bit | Penanda kesegaran; harus lebih besar dari *counter* terakhir yang diterima |
| *Payload* | 64 bit | Data aplikasi |
| *Tag* | 32 bit | CBC-MAC atas *counter* + *payload* |
| Kunci | 64 bit | Tidak ikut *frame*; dimuat *host* melalui *port* tepercaya |

Rantai CBC-MAC atas tiga blok 32 bit (B1 = *counter*, B2–B3 = *payload*), IV = 0, kunci 64 bit:

C1 = E_K(B1), C2 = E_K(C1 ⊕ B2), *tag* = C3 = E_K(C2 ⊕ B3)

*Frame* diterima hanya jika *tag* hasil hitung sama dengan *tag* yang diterima dan *counter* lebih besar dari *counter* terakhir yang diterima.

**Rincian modul:**

| Modul | Lapisan | Fungsi |
| --- | --- | --- |
| `l1_serial_loader.v` | L1 | Menggeser kunci 64 bit dan *frame* 128 bit secara serial; kunci *write-once*, terkunci sampai *reset* |
| `simon32_64.v` | L2 | Blok *cipher* SIMON-32/64 terserialisasi, satu ronde per siklus |
| `l2_auth.v` | L2 | CBC-MAC atas *counter* + *payload* (tiga blok 32 bit), perbandingan *tag*, pemeriksaan kesegaran *counter* |
| `l3_commit_gatekeeper.v` | L3 | *Commit* atomik hanya jika autentikasi dan kesegaran lulus; jika gagal, menahan `host_full` dan menaikkan `fault` yang bersifat lengket |
| `link_enc_8b10b.v`, `link_dec_10b8b.v`, `l1_link_framing.v`, `link_tx.v`, `link_rx.v`, `link_top.v` | Tier B | Tautan serial 8b/10b dengan *running disparity*, *framing* karakter-K, penguncian kata, dan *loopback* melalui L2+L3 |
| `boundary_top.v` | L2+L3 | Integrasi L2 dan L3 |
| `project.v` | *Wrapper* | *Wrapper* Tiny Tapeout: instansiasi L1 + L2+L3 |

**Antarmuka `boundary_top`:**

| Sinyal | Arah | Lebar | Keterangan |
| --- | --- | --- | --- |
| `key` | Masuk (*host*) | 64 | Kunci MAC, dimuat melalui *port* tepercaya |
| `counter`, `payload`, `tag` | Masuk (tautan) | 32, 64, 32 | *Frame* dari *front-end* |
| `host_data` | Keluar | 96 | *Counter* + *payload* yang telah lolos autentikasi |
| `host_full` | Keluar | 1 | Naik hanya jika `auth_ok` dan `fresh_ok` |
| `auth_ok`, `fresh_ok`, `done` | Keluar | 1 | Status per *frame* |
| `fault` | Keluar | 1 | Bersifat lengket sampai di-*acknowledge* oleh *host* |

**Arsitektur pemrosesan dan memori:**

- Aliran *streaming* satu arah; CBC-MAC berjalan sambil blok masuk.
- Tanpa *block RAM* dan tanpa *buffer frame*. *State* hanya berupa register: *state cipher*, *counter* terakhir, dan *flag* status.

**Konsumsi daya:**

- Logika digital *clock* tunggal, tanpa DSP, PLL internal, atau memori besar.
- MAC aktif hanya saat *frame* masuk sehingga aktivitas *switching* minimal saat *idle*. Hasil OpenLane: daya tipikal 2,10 mW untuk inti.
- Sintesis Quartus untuk DE10-Nano (Cyclone V) menghasilkan estimasi PowerPlay *vector-less* untuk *wrapper loopback* Tier B: total 426,2 mW dengan daya dinamis inti 3,76 mW. Estimasi ini memiliki tingkat keyakinan rendah dan didominasi daya statis perangkat, sehingga ditandai sebagai estimasi, bukan hasil pengukuran.

**Estimasi Penggunaan *Resource* FPGA:**

Hasil sintesis Quartus Prime 25.1 untuk DE10-Nano (Cyclone V 5CSEBA6U23I7), pasca-*fit*:

| Komponen | Hasil | Kapasitas DE10-Nano (5CSEBA6U23I7) |
| --- | --- | --- |
| Logika (ALM) | 421 | 41.910 ALM |
| Register (FF) | 1029 | 166.036 |
| *Block RAM* (M10K) | 0 | 5.570 Kbit |
| DSP | 0 | 112 |
| PLL | 0 | 6 |
| Fmax | 97,9 MHz | target 50 MHz |

Angka-angka ini merupakan hasil *wrapper loopback* Tier B (`link_demo_top`: `link_tx` + `link_rx` + `boundary_top`), yaitu desain yang didemonstrasikan. Desain memetakan tanpa *block RAM*, DSP, maupun PLL, dan menutup *timing* pada 50 MHz dengan margin (WNS +9,785 ns).

**Perangkat Lunak dan *Tools* Perancangan:**

- Intel Quartus Prime (sintesis, *fit*, *timing*, SignalTap) untuk DE10-Nano [13].
- OpenLane/OpenROAD dan Yosys untuk jalur ASIC sky130.
- Verilator dan Icarus Verilog untuk simulasi dan *lint*.
- cocotb dan pytest untuk *testbench* otomatis.
- SymbiYosys (pembuktian formal, mesin smtbmc z3).

Target ASIC: Tiny Tapeout sky130 130 nm via OpenLane [11].

- *Hardening* sky130 inti (hasil nyata): tile 2×2, die 0,0756 mm², 2511 sel, DRC 0, LVS 0, antena 0, WNS 0,00, daya tipikal 2,10 mW.
- *Hardening* sky130 tautan serial Tier B (hasil nyata): tile 2×2, 3220 sel, 2 pelanggaran antena, WNS 0,00, daya tipikal 3,61 mW. Angka ini merupakan hasil `tt_um_link`, bukan inti L2+L3 saja.
- Lampiran RF memiliki hasil tersendiri: tile 1×2, die 0,0363 mm², WNS 0,00, daya tipikal 1,21 mW. Angka ini bukan angka inti TRI-ARGA (lihat Lampiran F).

Laju pemrosesan: 108 siklus per *frame* pada 50 MHz = 2,16 µs, setara sekitar 29 Mbit/s *payload*. Angka ini jauh melampaui laju tautan RF 433 MHz, sehingga proses autentikasi tidak menjadi *bottleneck*.

### 3.2 Rencana Pengujian

**Simulasi RTL (S1, terukur):**

- *Testbench* cocotb menguji L1, L2, dan *commit* dengan matriks keberhasilan: *frame* bersih diterima; *forgery*, kunci salah, *replay*, dan *counter* basi ditolak; serta 128 dari 128 *single-bit flip* ditolak.
- *Testbench* tautan menguji *loopback* Tier B: *frame* bersih dikomit, sedangkan *forgery*, *replay*, dan *line error* ditolak.
- Latensi diukur per tahap: 33 siklus per blok SIMON, 107 siklus untuk MAC dan kesegaran, 108 siklus ujung ke ujung.

Bentuk gelombang autentikasi dan *commit* yang terukur (*frame* pertama lolos, *frame* kedua ditolak) tersedia di Lampiran I, Gambar I.2.

**Pembuktian Formal (SymbiYosys):**

Sembilan properti lolos: lima untuk inti (`auth_top`, `auth_data_integrity`, `l3_commit_core`, `simon32_64`, `l1_link`), satu untuk tautan Tier B (`link_framing`), dan tiga untuk lampiran RF (`l1_framing`, `l2_integrity`, `l3_commit`). Rincian per *job* tersedia di Lampiran K.

**Uji *Hardware Board* FPGA DE10-Nano (S2, rencana):**

- Prosedur sintesis: proyek Quartus dengan *wrapper* papan, SDC, dan *pin assignment*.
- Implementasi *bitstream* (.sof/.rbf) dan pengujian *on-board* secara *real-time*.
- Demonstrasi *on-board* menggunakan *loopback* internal `link_tx` ke `link_rx` melalui inti L2+L3. Saklar memilih kasus: *frame* bersih, *frame* korup (satu bit *payload*/tag dibalik), dan *replay* (*frame* yang sama dikirim ulang).
- Verifikasi sinyal internal dengan SignalTap pada `auth_ok`, `fresh_ok`, `done`, `host_full`, dan `fault`.
- Tidak ada perangkat eksternal dan tidak ada *clock* kedua; CDC di luar cakupan.

**Metrik Keberhasilan Target:**

| Metrik | Target | Bukti |
| --- | --- | --- |
| Deteksi galat satu bit | 128/128 teramati; peluang lolos teoretis ~2^-32 | Simulasi |
| *False reject* | 0% | Simulasi (20 *frame* bersih) |
| *Forgery* dan *replay* | Ditolak | Simulasi, kemudian *on-board* |
| Latensi ujung ke ujung | 108 siklus | Simulasi, kemudian SignalTap |
| *Fail-closed* | 9 *job* lolos | SymbiYosys |
| Fmax FPGA | 97,9 MHz terukur (target minimal 50 MHz) | Quartus Timing Analyzer |

### 3.3 *Security Design* (Model Ancaman)

Keamanan merupakan titik awal perancangan ini, bukan fitur tambahan: setiap modul ada karena satu ancaman spesifik dalam tabel di bawah.

**Aset yang dilindungi:** integritas dan keaslian *frame* yang sampai ke *host*, kesegaran *frame*, dan kerahasiaan kunci MAC.

**Batas kepercayaan:**

- Tidak tepercaya: semua yang datang dari tautan (*front-end* SerDes, Manchester/RF, UART), termasuk *counter*, *payload*, dan *tag*.
- Tepercaya: *host* dan *port* pemuatan kunci. Kunci tidak pernah melewati tautan.

**Kemampuan penyerang:** dapat menyadap, menyisipkan, mengubah, menghapus, dan memutar ulang *frame* pada tautan; dapat membuat galat bit acak. Tidak memiliki kunci, tidak dapat membaca register internal, dan tidak melakukan serangan *side-channel* atau *glitch* fisik (di luar cakupan, Lampiran G).

**Ancaman, mitigasi, dan bukti:**

| Ancaman | CWE | Mitigasi di *hardware* | Bukti |
| --- | --- | --- | --- |
| *Frame* palsu | CWE-345 [14] | CBC-MAC SIMON-32/64, *tag* 32 bit | *Forgery* ditolak (simulasi) |
| Integritas tidak dicek | CWE-354 [14] | *Tag* selalu dihitung ulang dan dibandingkan sebelum *commit* | 128/128 *bit flip* ditolak |
| *Replay frame* lama | CWE-294 [14] | *Counter* harus naik secara ketat | *Replay* dan *counter* basi ditolak |
| Data dan kendali terlepas | CWE-1264 [14] | *Commit* satu siklus: `host_data` dan `host_full` dilepas bersamaan dari salinan *frame* yang di-*latch* saat MAC dimulai | Properti formal |
| FSM macet atau *state* ilegal | CWE-1245 [14] | FSM terenumerasi penuh, *timeout*, `fault` bersifat lengket | Properti formal, uji *timeout* |
| *Framing* tidak sah | CWE-20 [14] | *Frame* dengan panjang atau struktur salah ditolak di pemuat | Uji *timeout* (Lampiran RF) |

Keputusan desain kriptografi dan batasannya diuraikan di Lampiran J. Secara ringkas: *tag* 32 bit memberikan peluang *forgery* sekitar 2^-32 per percobaan [8], [9]; CBC-MAC aman hanya untuk panjang tetap [8]; blok 32 bit memiliki batas *birthday* sehingga kunci wajib dirotasi; dan keputusan terima/tolak keluar pada siklus yang sama untuk semua *frame*.

## 4. Referensi

1. PERURI. "Buku Panduan Peserta PERURI Chip Hackathon 2026." 2026. https://summit.peruri.co.id/docs/Buku-Panduan-PERURI-Chip-Hackathon.pdf
2. Santeep G, M. dan N. Shylashree. "TT_UM_SERDES, Tiny Tapeout 07." https://github.com/Santeep/TT_UM_SERDES
3. Pa1mantri. "tt07_cdc_fifo, Tiny Tapeout 07." https://github.com/Pa1mantri/tt07_cdc_fifo
4. DusterTheFirst. "tt07-bep-decode, Tiny Tapeout 07." https://github.com/DusterTheFirst/tt07-bep-decode
5. Z. Kohnen. "Decoding Manchester coded transmissions in a fully digital ASIC." Skripsi S1, 2024.
6. Z. Kohnen dan A. Alvarado. "Manchester decoder of a home thermostat's wireless protocol." FSiC, 2025.
7. R. Beaulieu et al. "The SIMON and SPECK Families of Lightweight Block Ciphers." IACR ePrint 2013/404, 2013.
8. M. Bellare, J. Kilian, dan P. Rogaway. "The Security of the Cipher Block Chaining Message Authentication Code." *Journal of Computer and System Sciences*, vol. 61, no. 3, 2000.
9. NIST. SP 800-38B, "Recommendation for Block Cipher Modes of Operation: The CMAC Mode for Authentication." 2016. https://csrc.nist.gov/
10. NIST. SP 800-232, "Ascon-Based Lightweight Cryptography Standards for Constrained Devices." 2024. https://csrc.nist.gov/
11. Tiny Tapeout. "Tiny Tapeout — Make Your Own Chip." 2024. https://tinytapeout.com/
12. S. Kamkar. "Drive It Like You Hacked It" (RollJam). DEF CON 23, 2015.
13. Terasic. "DE10-Nano — Cyclone V FPGA User Manual." 2019. https://www.terasic.com.tw/
14. MITRE. "Common Weakness Enumeration (CWE): CWE-20, CWE-294, CWE-345, CWE-354, CWE-1245, CWE-1264." 2024. https://cwe.mitre.org/

## 5. Lampiran

### Lampiran A. Identitas Tim dan Pembagian Peran

Tim Tri Arga, Universitas Telkom.

| Nama Anggota | Keahlian Utama | Tanggung Jawab & Peran |
| --- | --- | --- |
| Ibrahim Fauzi Rahman | *Embedded Hardware*/Sistem, IoT, Desain PCB, RS485/CAN Bus Terisolasi | RTL: desain dan integrasi L1–L3 |
| Idris Syaifulloh | *DevOps*, *Machine Learning*, Peneliti Malware, CI/CD | Verifikasi: cocotb, *fault injection*, metrik, CI, analisis |

Dosen Pembimbing: Dr. Setia Juli Irzal Ismail, S.T., M.T. — Universitas Telkom

### Lampiran B. Luaran dan Demo

- Kode RTL Verilog, *testbench* cocotb, dan properti formal SymbiYosys.
- Hasil *hardening* sky130 (GDS, laporan DRC/LVS/*timing*/daya).
- *Bitstream* FPGA (.sof/.rbf) yang dapat dibangun dari repositori ini.
- Repositori sumber: https://github.com/bokumentation/hackathon-2026-01, beserta laporan teknis singkat.

### Lampiran C. Rencana *Bootcamp* (18–20 Oktober 2026)

| Hari | Fokus | *Deliverable* |
| --- | --- | --- |
| 1 (18 Okt) | Integrasi tautan Tier B dengan inti L2+L3; uji korupsi multi-bit acak dan *replay* | RTL terintegrasi lolos simulasi |
| 2 (19 Okt) | Sintesis Quartus *wrapper loopback*, SignalTap, uji *forgery* dan *replay on-board* | *Bitstream*, laporan *resource* dan *timing* |
| 3 (20 Okt) | Pengukuran akhir, pemolesan *hardening*, demo, presentasi seleksi Top 3 | Demo dan materi presentasi |

### Lampiran D. Anggaran Latensi (Terukur)

| Tahap | Siklus |
| --- | --- |
| Satu blok SIMON-32/64 (32 ronde + 1) | 33 |
| Tiga blok CBC-MAC | 99 |
| *Overhead* FSM: 2 siklus *handshake start/done* per blok (×3), 1 siklus *latch* masukan, 1 siklus keputusan | 8 |
| MAC dan kesegaran | 107 |
| *Commit* | 1 |
| Ujung ke ujung | 108 |

### Lampiran E. Perbandingan Integritas (Terukur)

| Properti | CRC tanpa kunci | MAC berkunci | MAC + *counter* (TRI-ARGA) |
| --- | --- | --- | --- |
| Latensi | 73 siklus (CRC serial 72 bit) | 107 siklus | 108 siklus |
| Deteksi galat acak | Ya | Ya | Ya |
| Tahan *forgery* | Tidak | Ya | Ya |
| Tahan *replay* | Tidak | Tidak | Ya |

Penambahan satu siklus untuk kesegaran dan *commit* memberikan ketahanan *replay*; penambahan 34 siklus dibanding CRC memberikan ketahanan *forgery*.

### Lampiran F. Bukti Masalah (RF)

*Baseline* `tt07-bep-decode` menerima *payload* dan *field* integritas yang korup dengan `full=1` (CWE-354, terukur) [4], [5]. Rincian tersedia pada `sim/RESULTS.md`; bentuk gelombang *timeout* L1 ada di `appendix/rf/figures/sim-boundary-timeout.png`.

<figure class="proto"><img src="assets/sim-baseline-vulnerability.png" alt="Vulnerabilitas baseline"><figcaption>Gambar F.1. Baseline tt07-bep-decode: full naik untuk frame bersih, payload korup, dan field integritas korup.</figcaption></figure>

Hasil *hardening* sky130 desain lampiran RF (*front-end baseline* ditambah L1 *framing*, L2 integritas CRC terparametrisasi, dan gerbang L3 yang sama dengan inti): tile 1×2, die 0,0363 mm², 1233 sel, WNS 0,00, daya tipikal 1,21 mW. Angka ini bukan angka inti TRI-ARGA (lihat 3.1).

### Lampiran G. Batasan

| Batasan | Dampak | Mitigasi atau Rencana |
| --- | --- | --- |
| Tidak ada kerahasiaan *payload* | *Payload* dapat dibaca penyadap | Di luar cakupan; dapat ditambah dengan AEAD (mis. Ascon) [10] |
| *Tag* 32 bit | Peluang *forgery* ~2^-32 per percobaan | Cukup untuk tautan ringan; *tag* lebih panjang dengan *cipher* 64 bit |
| Blok 32 bit (batas *birthday*) | Keamanan turun setelah ~2^16 blok per kunci | Rotasi kunci wajib; rekomendasi setiap 2^12 *frame* |
| CBC-MAC hanya panjang tetap | Tidak aman untuk *frame* berpanjang variabel | Format dikunci pada tiga blok; ganti ke CMAC jika variabel [9] |
| *Counter* kembali ke 0 setelah *reset* | *Frame* lama dapat diterima kembali setelah *power cycle* | Kunci sesi baru setiap *boot* |
| Provisi kunci | Inti tidak mengatur sumber kunci | Tanggung jawab *host* atau *secure element* |
| *Side-channel* dan *glitch* fisik | Tidak dianalisis | Properti formal hanya membuktikan logika, bukan ketahanan fisik |
| CDC | Inti saat ini satu domain *clock* | Di luar cakupan; *clock* kedua hanya melalui FIFO CDC pada Tier C [3] |
| Daya FPGA | *Resource* dan *timing* terukur Quartus; daya masih estimasi *vector-less* | Ukur daya *on-board* di *bootcamp* |

### Lampiran H. Uji *Hardware* FPGA DE10-Nano

- Papan: Terasic DE10-Nano, Cyclone V SoC (5CSEBA6U23I7), Quartus Prime [13].
- *Clock*: `CLOCK_50` (50 MHz) langsung, satu domain *clock*.
- Prosedur: sintesis (`quartus_sh --flow compile`), unggah *bitstream* (.sof/.rbf), uji *on-board* secara *real-time*.
- Demonstrasi: *wrapper loopback* menginstansiasi `link_tx` dan `link_top` (`link_rx` + `boundary_top`). Saklar memilih kasus bersih, korup, atau *replay*; `fault_ack` mereset *fault* yang bersifat lengket.
- SignalTap (disiapkan, menunggu papan): *taps* `host_full`, `fault`, `auth_ok`, `fresh_ok`, `done`, `key_locked`; *sample clock* `CLOCK_50`, kedalaman 2048, posisi *pre-trigger*; pemicu tepi naik `host_full` untuk kasus terima dan `fault` untuk kasus tolak. Berkas `.stp` dibuat di GUI Quartus, kemudian `quartus_stp ... --enable` menambah *wiring* SLD dan kompilasi diulang; skrip akuisisi dan prosedur tersedia di repositori.
- Skenario uji: *frame* bersih dikomit (`host_full` naik); *frame* korup ditolak (`host_full` tetap rendah, `fault` naik); *replay* tidak dikomit; *fault* bersifat lengket sampai di-*acknowledge*.
- Laporan *wrapper loopback* Tier B (`link_demo_top`): Fitter 421 ALM/1029 FF, Timing Analyzer Fmax 97,9 MHz (WNS +9,785 ns), PowerPlay 426,2 mW *vector-less* (3,76 mW dinamis inti).
- Sebagai pembanding, *wrapper* Tier A (`de10nano_top`, pemuat serial L1) sebelumnya terukur 242 ALM/654 FF, Fmax 136,37 MHz.
- Fasilitas: FPGA/*sandbox* penyelenggara saat *bootcamp*.

### Lampiran I. Gambar Pendukung

<figure class="proto"><img src="assets/frame-link.svg" alt="Format frame dan rantai CBC-MAC"><figcaption>Gambar I.1. Format frame 128 bit (counter + payload + tag) dan rantai CBC-MAC SIMON-32/64.</figcaption></figure>

<figure class="proto"><img src="assets/sim-auth-commit.png" alt="Autentikasi dan commit"><figcaption>Gambar I.2. Inti TRI-ARGA: frame pertama lolos (auth_ok, fresh_ok, host_full naik); frame kedua ditolak (host_full tetap rendah, fault naik).</figcaption></figure>

### Lampiran J. Catatan Kriptografi

- **Alasan pemilihan SIMON-32/64.** *Cipher* ini dirancang untuk *hardware* sangat kecil dan dapat diserialisasi satu ronde per siklus, sehingga muat di tile Tiny Tapeout 2×2 [7]. Tim menyadari bahwa SIMON/SPECK ditolak sebagai standar ISO pada 2018 dan bahwa standar NIST untuk kriptografi ringan saat ini adalah Ascon [10]. Oleh karena itu, *cipher* dibungkus antarmuka blok yang modular: dapat diganti ke SIMON-64/128 atau Ascon tanpa mengubah L2 dan L3, dengan konsekuensi area yang lebih besar.
- **CBC-MAC hanya untuk panjang tetap.** CBC-MAC aman hanya jika semua pesan berpanjang sama [8]. Format *frame* dikunci pada tiga blok; jika suatu saat panjang *frame* bervariasi, mode perlu diganti ke CMAC [9].
- **Batas *birthday* blok 32 bit.** Dengan blok 32 bit, keamanan CBC-MAC menurun setelah sekitar 2^16 blok di bawah kunci yang sama, kira-kira 2×10^4 *frame*. Kebijakan integrasi: kunci wajib dirotasi jauh di bawah batas ini (rekomendasi: setiap 2^12 *frame*).
- **Peluang *forgery* per percobaan** sekitar 2^-32 karena *tag* 32 bit [8], [9].
- **Waktu keputusan tetap.** Keputusan terima/tolak keluar pada siklus yang sama untuk semua *frame*. L2 selalu memproses ketiga blok tanpa jalan keluar lebih awal.
- **Perilaku setelah *reset*.** *Counter* terakhir kembali ke 0 setelah *reset*. Rekomendasi integrasi: *host* memuat kunci sesi baru setiap *boot*. Kunci juga bersifat *write-once*: dimuat sekali setelah *reset* melalui mode pemuatan kunci terpisah, kemudian terkunci sampai *reset*.

### Lampiran K. Rincian Pembuktian Formal

| *Job* SymbiYosys | Properti | Lingkup |
| --- | --- | --- |
| `auth_top` | `host_full` hanya tinggi jika *frame* terakhir yang selesai lolos `auth_ok` dan `fresh_ok` | Inti |
| `auth_data_integrity` | Data yang dikomit sama dengan *frame* yang diautentikasi (BMC *depth* 20, *cipher* diabstraksi) | Inti |
| `l3_commit_core` | `host_full` hanya tinggi jika keputusan *commit* terakhir menerima *frame* | Inti |
| `simon32_64` | `done` hanya naik setelah tepat 32 ronde | Inti |
| `l1_link` | 8 properti: *key_load*/*start* saling eksklusif, *start* hanya setelah kunci terkunci, *key_load* hanya sebelum kunci terkunci, *key_locked* bersifat lengket, pulsa satu siklus, dan *framing fault* | L1 |
| `link_framing` | *Framing* dan penguncian kata tautan 8b/10b tidak naik bersamaan dengan *fault* | Tier B |
| `l1_framing` | `framing_ok` tidak pernah tinggi bersamaan dengan `timing_fault` atau `timeout_fault` | Lampiran RF |
| `l2_integrity` | Register CRC selalu dimulai dari nilai awal saat *frame* dimulai | Lampiran RF |
| `l3_commit` | `host_full` hanya tinggi jika keputusan *commit* terakhir menerima *frame* | Lampiran RF |
