# Ide-06: Outline Proposal SALARAS-SERDES (CRC)

Kerangka proposal mengikuti 5 struktur resmi PERURI Chip Hackathon 2026

*Baseline*: `TT_UM_SERDES` (`tt_um_serdes`)
Area Fokus: 04 - Secure Communication (*secure framing*, protocol security, *interface integrity*)
Integritas: CRC (bukan MAC), untuk biaya area rendah
Status: outline, siap dikembangkan menjadi proposal penuh
Induk: `ideas-01-salaras-serdes.md`

Dokumen ini adalah kerangka proposal, bukan proposal final.
Setiap bagian memuat poin isi, draft kalimat kunci, dan penanda pekerjaan.
Relevansi CWE ditonjolkan pada Bagian 2 untuk memperkuat *problem statement* dan *latar belakang*.

## Pemetaan Struktur Proposal

| Bagian resmi | Isi utama | Status pada outline |
| --- | --- | --- |
| 1. Ringkasan Ide | masalah, solusi, chip, target pengguna, dampak | draft siap |
| 2. Latar Belakang dan Rumusan Masalah | mengapa, masalah, gap, CWE | draft siap |
| 3. Proposed Chip Design | arsitektur, RTL, verifikasi, pengujian | kerangka rinci |
| 4. Referensi | rujukan desain dan CWE | draft siap |
| 5. Lampiran | glosarium, daftar CWE, peran tim | kerangka |

## 1. Ringkasan Ide (Executive Summary)

Masalah yang Diangkat:
Tautan serial pada terminal aman sering mengirim byte tanpa batas *frame* dan tanpa pemeriksaan integritas.
*Baseline* `tt_um_serdes` hanya mengubah data paralel ke serial memakai pengkodean 8b/10b sederhana, tanpa framing, tanpa *running disparity*, dan tanpa nilai pemeriksa.
Akibatnya penerima tidak dapat memastikan batas data dan tidak dapat menolak data yang berubah, yang merupakan kelas kelemahan CWE-353 (Missing Support for Integrity Check) dan CWE-354 (Improper Validation of Integrity Check Value).
Mesin penyelaras dan penanda status juga rawan pada CWE-1245 (Improper Finite State Machines in *Hardware* Logic) dan CWE-1264 (Insecure De-Synchronization between Control and Data Channels).

Solusi yang Ditawarkan:
SALARAS-SERDES adalah *boundary* tiga lapis yang memakai teknik SALARAS-RX pada tautan serial, dengan CRC sebagai mekanisme integritas.
Lapisan L1 menambahkan framing dan penyelarasan word beserta status *lock*.
Lapisan L2 menghitung dan memeriksa CRC atas *frame* secara *streaming* memakai LFSR.
Lapisan L3 melakukan *commit* atomik yang *fail-closed* dan menaikkan *fault* lengket bila CRC gagal.

Chip yang Dirancang:
IP block digital murni berukuran kecil, target 1x1 *tile* Tiny Tapeout, dengan *clock* tunggal dan tanpa *buffer* besar.
*Boundary* disisipkan pada jalur antara PISO dan SIPO pada *baseline* SerDes.

Target Pengguna:
Perancang terminal pembaca identitas, *smart card*, dan perangkat pembayaran yang memakai tautan serial.
Integrator IP yang membutuhkan tautan serial berintegritas siap pakai.
Tim *firmware* *host* yang membutuhkan jaminan bahwa data yang diterima sudah melewati pemeriksaan integritas.

Implementasi pada FPGA:
Prototipe memakai DE10-Nano dengan *loopback* on-chip antara *serializer* dan *deserializer*, ditambah *host* PC melalui USB-UART untuk membaca hasil dan *fault*.

Kebaruan dan Keunggulan:
Mengangkat integritas dari sekadar keandalan menjadi mekanisme yang eksplisit dan *fail-closed* pada *boundary*.
Menambahkan framing dan penyelarasan yang belum ada pada *baseline*.
Memberi CRC yang terukur dan terverifikasi, dengan pengukuran *detection* rate dan *latency*.
Jalur peningkatan ke MAC tetap terbuka sebagai pengembangan lanjutan.

Dampak:
Mengurangi risiko data rusak atau tidak selaras diterima sebagai data sah.
Memberi observabilitas melalui penghitung error dan status *lock*.

## 2. Latar Belakang dan Rumusan Masalah (Problem Statement)

*Latar Belakang*:
Tautan serial adalah tulang punggung komunikasi antara *secure element*, terminal, dan *host*.
Pada banyak implementasi ringan, lapis pengkodean fisik dianggap cukup, padahal kode 8b/10b hanya membantu keseimbangan DC dan bukan autentikasi.
*Baseline* `tt_um_serdes` memperlihatkan pola ini: *encoder* dan *decoder* berbasis tabel, cabang default yang memetakan kode tidak sah menjadi nol, dan tidak ada nilai pemeriksa.
Pola ini memunculkan tiga risiko utama, yaitu tidak ada dukungan integritas (CWE-353), integritas tidak divalidasi bila ada (CWE-354), dan desinkronisasi antara kendali dan data (CWE-1264).

Relevansi CWE untuk Hardening (bagian inti penguatan):

| CWE | Nama | Celah pada baseline | Mitigasi SALARAS-SERDES |
| --- | --- | --- | --- |
| CWE-353 | Missing Support for Integrity Check | Tidak ada nilai pemeriksa sama sekali | L2 menambahkan CRC atas frame |
| CWE-354 | Improper Validation of Integrity Check Value | Tidak ada pemeriksaan, karena tidak ada nilai | L2 memeriksa CRC sebelum commit |
| CWE-345 | Insufficient Verification of Data Authenticity | CRC tidak berkunci, sehingga bukan autentikasi | Dicatat sebagai batas; MAC sebagai pengembangan lanjutan |
| CWE-1245 | Improper FSM in Hardware Logic | Tidak ada FSM lock atau recovery yang kokoh | L1 menambahkan lock, timeout, dan recovery |
| CWE-1264 | Insecure De-Synchronization between Control and Data | Data dan status tidak dikomit bersama | L3 commit atomik fail-closed |
| CWE-20 | Improper Input Validation | Kode 10b tidak sah menjadi nol tanpa laporan | L1 menandai kode tidak sah sebagai error |

Catatan penting: CRC menutup CWE-353 dan CWE-354, tetapi tidak menutup CWE-345 secara penuh, karena CRC tidak berkunci.
Batasan ini harus dinyatakan jujur dan dijadikan alasan pengembangan lanjutan ke MAC.

Gap terhadap Solusi yang Tersedia:
Solusi keandalan sederhana menambahkan *parity* pada byte, tetapi tidak memeriksa batas *frame*.
Solusi pengkodean penuh menambahkan *running disparity*, tetapi tetap tanpa nilai integritas.
Solusi MAC memberi autentikasi, tetapi biaya area dan manajemen kunci lebih tinggi.
SALARAS-SERDES mengisi celah integritas dengan CRC yang murah, dan menyiapkan jalur ke MAC.

Rumusan Masalah dan Perancangan:
1. Bagaimana menambahkan framing dan penyelarasan word yang kokoh pada SerDes tanpa mengubah antarmuka dasar?
2. Bagaimana membangun dan memeriksa CRC atas *frame* secara *streaming* dengan biaya area rendah?
3. Bagaimana menjamin *commit* atomik yang *fail-closed* pada tautan serial berclock tunggal?

Batasan Desain:
Hemat area, target 1x1 *tile*, *fallback* 1x2.
Tanpa *buffer* besar dan tanpa block RAM tambahan.
Kompatibel dengan *baseline* dan tidak mengubah pengkodean fisik 8b/10b.

## 3. Proposed Chip Design

### 3.1 Solusi dan Arsitektur Sistem

Fungsi Utama:
Menerima aliran serial, menyelaraskan word, memeriksa CRC, lalu menyajikan data paralel yang sah ke *host*, dengan *fault* bila pemeriksaan gagal.

Diagram Blok Sistem (deskripsi teks):
`ser_in -> SIPO 10b -> L1 alignment dan lock -> L2 CRC check -> L3 atomic commit -> data_out ke host`, dengan jalur `fault` ke *host*.
Sisi kirim: `data_in -> L2 CRC append -> PISO 10b -> ser_out`.

Rincian Modul RTL:
- L1 framing dan *lock*: deteksi penanda koma atau pola *K-code*, penghitung pergeseran word, status *lock*, *timeout*, dan recovery.
- L2 CRC: LFSR 24 bit atau lebih, menghitung CRC atas *payload* per *frame* atau per blok, lalu membandingkan dengan nilai yang diterima.
- L3 *commit*: gerbang *valid* dan *latch* data secara bersamaan, reset saat CRC gagal, *fault* lengket.

Input/Output (kerangka tabel):
| Sinyal | Arah | Lebar | Fungsi |
| --- | --- | --- | --- |
| ser_in | Input | 1 | aliran serial masuk |
| data_in | Input | 8 | data paralel sisi kirim |
| en | Input | 1 | aktifkan kirim atau terima |
| clk, rst_n | Input | 1 | clock dan reset |
| ser_out | Output | 1 | aliran serial keluar |
| data_out | Output | 8 | data paralel tervalidasi |
| valid | Output | 1 | data sah dan siap |
| fault | Output | 1 | kegagalan CRC atau lock |

Arsitektur Pemrosesan:
Aliran satu arah dan *streaming*.
L1 berjalan pada saat penyelarasan, L2 menghitung CRC bersamaan dengan masuknya bit, L3 bersifat kombinasional untuk gerbang dan *latch* untuk *fault*.
Kompleksitas O(n) terhadap panjang *frame*.

Arsitektur Memori:
Tanpa block RAM.
State hanya berupa register geser CRC, penghitung word, status *lock*, dan *fault*.

Interface dan Komunikasi:
Antarmuka *host* 8 bit dengan *handshake* *valid* dan *fault*.
Satu pin input serial dan satu pin output serial.
Protokol *frame*: penanda awal, *payload*, dan CRC.

Security Design:
Prinsip: verifikasi sebelum *commit*, *fail-closed*, dan tidak bergantung pada *software* *host*.
Model ancaman: penyerang dapat menyuntik atau mengubah aliran serial.
Tabel CWE ke mitigasi mengacu pada Bagian 2.
Batasan: CRC mendeteksi error acak dan *fault*, tidak melindungi dari pemalsuan berkunci.

Konsumsi Daya:
Rendah, seluruhnya logika digital *clock* tunggal, CRC aktif hanya saat *frame* datang.

Pendekatan RTL:
Verilog atau SystemVerilog, tersintesiskan penuh, modul terpisah untuk L1, L2, dan L3, parameter untuk mengaktifkan atau mematikan *boundary*.

ISA:
Tidak relevan, desain hardwired tanpa instruksi.

IP yang Digunakan:
Tidak ada IP komersial, memakai *baseline* open source dan pustaka standar.

Target FPGA/ASIC dan Technology Node:
FPGA DE10-Nano Cyclone V SoC.
ASIC Tiny Tapeout 07, sky130 melalui OpenLane, target 1x1 *tile*.

Estimasi Penggunaan *Resource* FPGA:
| Komponen | Estimasi | Kapasitas DE10-Nano |
| --- | --- | --- |
| LUT | [isi setelah sintesis] | 110,000 LE |
| FF | [isi setelah sintesis] | 415,000 |
| Block RAM | 0 | 5,570 Kbit |
| DSP | 0 | 112 |

Perangkat Lunak dan Tools:
Verilog, cocotb, Verilator atau Icarus, Yosys, OpenLane, Quartus Prime, Python.

### 3.2 Rencana Pengujian

Simulasi RTL:
*Testbench* cocotb dengan *loopback* on-chip, *frame* bersih, *frame* dengan bit flip, dan *frame* dengan sinkronisasi terganggu.

Strategi Verifikasi:
*Self-checking* *testbench* dengan assertion.
Uji kesetaraan dengan *baseline* untuk *frame* bersih.
Lint Verilator dan cek sintesis Yosys.
Traceability setiap klaim metrik ke satu test case.

*Prototype* *Hardware*:
Mode S1 simulasi sebagai jalur CI.
Mode S2 wired pada DE10-Nano dengan *loopback* dan *host* melalui USB-UART.

Uji *Hardware* Board:
Sintesis Quartus, verifikasi SignalTap, pengujian on-board *frame* bersih diterima dan *frame* korup ditolak.

Metrik Keberhasilan Target:
*Detection* rate 100 persen pada set *fault injection* yang ditentukan.
False-reject 0 persen pada *frame* bersih.
*Latency* *overhead* 1 sampai 3 siklus *clock*.
Area target 1x1 *tile*, *fallback* 1x2.

## 4. Referensi

- Santeep G, M., dan Shylashree N. "SerDes (tt_um_serdes), Tiny Tapeout 07." https://github.com/Santeep/TT_UM_SERDES (halaman resmi: https://tinytapeout.com/chips/tt07/tt_um_serdes)
- MITRE. "CWE-20: Improper Input Validation." https://cwe.mitre.org/data/definitions/20.html
- MITRE. "CWE-345: Insufficient Verification of Data Authenticity." https://cwe.mitre.org/data/definitions/345.html
- MITRE. "CWE-353: Missing Support for Integrity Check." https://cwe.mitre.org/data/definitions/353.html
- MITRE. "CWE-354: Improper Validation of Integrity Check Value." https://cwe.mitre.org/data/definitions/354.html
- MITRE. "CWE-1245: Improper Finite State Machines (FSM) in *Hardware* Logic." https://cwe.mitre.org/data/definitions/1245.html
- MITRE. "CWE-1264: *Hardware* Logic with Insecure De-Synchronization between Control and Data Channels." https://cwe.mitre.org/data/definitions/1264.html
- The OpenROAD Project. "OpenLane." https://github.com/The-OpenROAD-Project/OpenLane
- Google. "SkyWater PDK (sky130)." https://github.com/google/skywater-pdk
- cocotb. "cocotb: coroutine based cosimulation library." https://github.com/cocotb/cocotb
- Altera. "Cyclone V FPGA and SoC FPGA." https://www.altera.com/products/fpga/cyclone/v
- Terasic. "DE10-Nano - Cyclone V FPGA Guide." https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=167&No=1046&PartNo=1#contents

## 5. Lampiran

Identitas dan Peran Tim:
Tabel nama, institusi, dan peran, diisi saat finalisasi.

Glosarium:
- 8b/10b: pengkodean 8 bit menjadi 10 bit.
- CRC: nilai pemeriksa linear tanpa kunci.
- *Frame*: satuan data dengan batas jelas.
- LFSR: register geser umpan balik linear, mesin CRC.
- *Lock*: status penyelarasan yang mantap.
- MAC: nilai pemeriksa berkunci.
- *Fail-closed*: kegagalan menahan data.

Daftar CWE yang Relevan:
CWE-20, CWE-345, CWE-353, CWE-354, CWE-1245, CWE-1264, dengan catatan mitigasi pada Bagian 2.

Pertanyaan Terbuka:
- Apakah CRC cukup untuk prototipe, atau perlu langsung MAC?
- Bagaimana ambang *fault* ditetapkan agar tidak false alarm?
- Apakah perlu ECC pada *buffer* internal bila ditambahkan nanti?
