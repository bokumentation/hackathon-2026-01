# PROPOSAL PESERTA PERURI CHIP HACKATHON 2026

Kategori: IC Chip Design & FPGA Implementation

Area Fokus: 04 - Secure Communication (secure framing, protocol security, interface integrity)

## Identitas Tim

Judul Ide Desain Chip: SALARAS-SERDES - Secure Framed Serial Link dengan CRC

Nama Tim: dinotice

Anggota Tim:

- Ketua: Ibrahim Fauzi Rahman - Universitas Telkom - +62 857-2774-6841
- Anggota 1: Idris Syaifulloh - Universitas Telkom - +62 895-3309-78461

Dosen Pembimbing: Dr. Setia Jul Ismail, S.T., M.T. - Universitas Telkom

## 1. Ringkasan Ide (Executive Summary)

**Masalah yang Diangkat:**

Tautan serial 8b/10b pada terminal identitas dan pembayaran sering diperlakukan sebagai kanal tepercaya, padahal *baseline* `tt_um_serdes` tidak memiliki *framing*, tidak memiliki nilai integritas, dan memetakan kode 10b tidak sah menjadi nol.
Akibatnya data yang rusak, tidak selaras, atau hasil *fault injection* dapat diterima *host* sebagai data sah (CWE-353, CWE-354, CWE-20), diperparah FSM *lock* yang rapuh (CWE-1245) dan de-sinkronisasi kendali/data (CWE-1264).

**Solusi yang Ditawarkan:**

SALARAS-SERDES adalah *boundary* tiga lapis: L1 *framing*, *alignment*, *lock*, *timeout*, dan recovery; L2 CRC-24 *streaming* berbasis LFSR; L3 *atomic commit* *fail-closed* dengan *fault* lengket.
*Boundary* disisipkan antara PISO dan SIPO tanpa mengubah pengkodean fisik 8b/10b.
Target area 1x1 *tile* sky130 (kurang dari 60 FF tambahan, tanpa BRAM/DSP), *latency* *overhead* 1-3 siklus, *detection rate* minimal 99,9 persen pada *fault injection* *single-bit flip*, *false-reject* 0 persen pada *frame* bersih.

**Chip & Target Pengguna:**

IP block digital murni berclock tunggal, tanpa *buffer* besar.
Target pengguna: perancang terminal pembaca identitas, *smart card*, dan perangkat pembayaran yang memakai tautan serial; integrator IP yang membutuhkan *ingress* berintegritas; tim *firmware* yang ingin jaminan data sudah lolos verifikasi sebelum masuk *host*.

**Verifikasi & Prototipe:**

Verifikasi utama adalah simulasi cocotb dan Verilator dengan *loopback* *on-chip* (S1, jalur CI).
Jika FPGA tersedia, S2 *wired* *hardware-in-the-loop* pada DE10-Nano dipakai untuk demo *real-time*; sinyal *fault* dapat dipetakan ke *interrupt* *host*.
Autentikasi berkunci (MAC) tidak termasuk lingkup saat ini dan disiapkan sebagai *future work*.

**Kebaruan & Dampak:**

Pertama, integritas dibangun dan diverifikasi di *boundary* sebelum data mencapai *host*.
Kedua, *commit* atomik mencegah de-sinkronisasi kendali/data.
Ketiga, CRC-24 memberi keseimbangan deteksi *burst error* hingga 24 bit dengan biaya area rendah.
Dampaknya, data korup atau tidak sah tidak pernah dipakai *host*, dan sistem memperoleh observabilitas melalui *lock*, *error counter*, dan *fault*.

## 2. Latar Belakang & Rumusan Masalah (Problem Statement)

### 2.1 Baseline tt_um_serdes

*Baseline* menyediakan konversi paralel ke serial dan sebaliknya, serta pengkodean 8b/10b sederhana, tetapi belum memiliki lapis integritas dan *framing*.
Tabel berikut memetakan fitur yang ada dan yang belum ada pada *baseline*.

| Fitur | Ada di *baseline*? |
| --- | --- |
| *Encoder* dan *decoder* 8b/10b | Ya |
| PISO dan SIPO | Ya |
| *Latch* data | Ya |
| *Running disparity* | Tidak |
| *K-code* dan *comma* | Tidak |
| *Framing* dan batas *frame* | Tidak |
| Integritas (CRC atau MAC) | Tidak |
| Deteksi kode 10b tidak sah | Tidak |
| *Fail-closed* dan *fault* | Tidak |

Celah inilah yang menjadi dasar perancangan SALARAS-SERDES.

Latar Belakang:

Tautan serial adalah tulang punggung komunikasi antara *secure element*, terminal, dan *host*.
Pada banyak implementasi ringan, lapis pengkodean fisik dianggap memadai, padahal kode 8b/10b hanya membantu keseimbangan DC dan bukan autentikasi.
Tanpa batas *frame*, penerima tidak tahu di mana data mulai dan berakhir.
Tanpa nilai pemeriksa, perubahan bit akibat noise, jitter, atau gangguan fisik tidak terdeteksi.
Tanpa *commit* atomik, data yang rusak dapat terlanjur dipakai sebelum diperiksa.

Relevansi CWE (Hardening Problem Statement):

| CWE | Nama | Celah pada *baseline* | Mitigasi SALARAS-SERDES |
| --- | --- | --- | --- |
| CWE-353 | Missing Support for Integrity Check | Tidak ada nilai pemeriksa sama sekali | L2 menambahkan CRC-24 atas *frame* |
| CWE-354 | Improper Validation of Integrity Check Value | Tidak ada pemeriksaan | L2 memeriksa CRC-24 sebelum *commit* |
| CWE-345 | Insufficient Verification of Data Authenticity | CRC tidak berkunci | Dicatat sebagai batas; MAC sebagai future work |
| CWE-1245 | Improper Finite *State* Machines in *Hardware* Logic | Tidak ada *lock* dan recovery yang kokoh | L1 menambahkan *lock*, *timeout*, dan recovery |
| CWE-1264 | Insecure De-Synchronization between Control and Data Channels | Data dan *status* tidak dikomit bersama | L3 *commit* atomik *fail-closed* |
| CWE-20 | Improper Input Validation | Kode 10b tidak sah dipetakan menjadi nol | L1 menandai kode tidak sah sebagai error |

Catatan kejujuran: CRC menutup CWE-353 dan CWE-354, tetapi tidak menutup CWE-345 secara penuh karena CRC tidak berkunci.
Batasan ini dinyatakan terbuka dan menjadi alasan pengembangan lanjutan ke MAC.

Gap terhadap Solusi yang Tersedia:

| Solusi | Kelemahan |
| --- | --- |
| *Parity* byte | Tidak memeriksa batas *frame* dan tidak mendeteksi *burst error* |
| 8b/10b penuh | Menjaga keseimbangan DC, tetapi tanpa integritas |
| MAC | Area besar dan membutuhkan manajemen kunci |
| SALARAS-SERDES | CRC murah, ditambah *framing*, *lock*, dan *fail-closed* |

Rumusan Masalah & Perancangan:

1. Bagaimana menambahkan *framing* dan penyelarasan *word* yang kokoh pada SerDes tanpa mengubah antarmuka dasar?
2. Bagaimana membangun dan memeriksa CRC atas *frame* secara *streaming* dengan biaya area rendah?
3. Bagaimana menjamin *commit* atomik yang *fail-closed* pada tautan serial berclock tunggal?

Batasan Desain:

Hemat area, target 1x1 *tile*, *fallback* 1x2.
Tanpa *buffer* besar dan tanpa block RAM tambahan.
Kompatibel dengan *baseline* dan tidak mengubah pengkodean fisik 8b/10b.
Autentikasi berkunci (MAC) berada di luar lingkup dan menjadi future work.

## 3. Proposed Chip Design

### 3.1 Solusi & Arsitektur Sistem

Fungsi Utama:

Menerima aliran serial, menyelaraskan *word*, memeriksa CRC, lalu menyajikan data paralel yang sah ke *host*, dengan *fault* bila pemeriksaan gagal.
Pada sisi kirim, *boundary* menyisipkan nilai CRC ke dalam *frame* sebelum transmisi.

Diagram Blok Sistem:

<figure class="proto"><img src="assets/serdes-block-diagram.svg" alt="Diagram blok SALARAS-SERDES"><figcaption>Gambar: diagram blok SALARAS-SERDES.</figcaption></figure>

Format *Frame*:

*Frame* didefinisikan pada level *word* terenkode.
Setiap byte data dikodekan 8b/10b menjadi 10 bit.

| *Field* | Lebar terenkode | Deskripsi |
| --- | --- | --- |
| *K-code* start | 10b | penanda awal *frame* (*comma*-like) |
| *Payload* | N x 10b | N byte data, tiap byte 8b/10b |
| CRC-24 | 3 x 10b | CRC atas N byte *payload*, dikirim sebagai 3 byte |
| *K-code* end (opsional) | 10b | penanda akhir *frame* |

*Payload* default adalah N = 8 byte (64 bit), dan bersifat parameterizable dalam rentang 4 sampai 32 byte.
Dengan N = 8, panjang *frame* adalah 120 bit tanpa *K-code* end, atau 130 bit dengan *K-code* end.
N = 8 dipilih karena selaras dengan lebar jalur paralel 8 bit, cukup panjang agar CRC-24 bermakna, dan tetap pendek untuk *latency* rendah serta simulasi cepat.

Rincian Modul RTL:

- L1 *framing* dan *lock*: deteksi *K-code* sebagai penanda awal *frame*, penghitung pergeseran *word* untuk penyelarasan, *status* *lock*, *timeout*, dan recovery. Kode 10b yang tidak sah ditandai sebagai error.
- L2 CRC: LFSR 24 bit menghitung CRC atas N byte *payload*. Pada sisi kirim, nilai CRC disisipkan ke *frame*. Pada sisi terima, nilai CRC dihitung ulang dan dibandingkan dengan nilai yang diterima.
- L3 *commit*: gerbang *valid* dan *latch* data secara bersamaan. Bila CRC gagal atau *lock* hilang, *commit* ditahan, data lama dipertahankan, dan *fault* lengket dinaikkan.

Justifikasi CRC-24:

CRC-24 dipilih karena menyeimbangkan kemampuan deteksi error dengan biaya area.
CRC-24 mendeteksi seluruh error satu bit dan seluruh *burst error* sampai 24 bit, sehingga cocok untuk *fault* injection *single-bit flip*.
CRC-16 terlalu lemah untuk *frame* dengan *payload* menengah dan panjang, karena kemungkinan error tak terdeteksi meningkat.
CRC-32 menambah sekitar 8 *flip-flop* dan logika tanpa manfaat signifikan untuk *frame* pendek seperti 120 bit, sehingga biaya areanya tidak sepadan.
Dengan demikian CRC-24 memberi titik seimbang antara deteksi dan area.

Input/Output:

| Sinyal | Arah | Lebar | Fungsi |
| --- | --- | --- | --- |
| ser_in | Input | 1 | aliran serial masuk |
| data_in | Input | 8 | data paralel sisi kirim |
| *mode* | Input | 1 | pilih kirim atau terima |
| data_en | Input | 1 | aktifkan pemuatan data |
| clk | Input | 1 | *clock* sistem |
| rst_n | Input | 1 | reset aktif rendah |
| ser_out | Output | 1 | aliran serial keluar |
| data_out | Output | 8 | data paralel tervalidasi |
| *valid* | Output | 1 | data sah dan siap dibaca |
| *lock* | Output | 1 | *status* penyelarasan *word* |
| *fault* | Output | 1 | kegagalan CRC, *lock*, atau kode tidak sah |

Arsitektur Pemrosesan:

Aliran satu arah dan *streaming*.
L1 bekerja saat penyelarasan, L2 menghitung CRC bersamaan dengan masuknya byte, dan L3 bersifat kombinasional untuk gerbang serta *latch* untuk *fault*.
Kompleksitas O(n) terhadap jumlah bit *frame*.

Arsitektur Memori:

Tanpa block RAM.
*State* hanya berupa *register* geser CRC, penghitung *word*, *status* *lock*, dan *register* *fault*.
*Payload* tidak disimpan dalam *buffer* besar, melainkan dialirkan dan hanya dikomit bila CRC *valid*.

Interface & Komunikasi:

Antarmuka *host* 8 bit dengan *handshake* *valid* dan *fault*.
Satu pin input serial dan satu pin output serial.
Protokol *frame*: *K-code* start, *payload* N byte, dan CRC-24, dengan *K-code* end opsional.
Sinyal *fault* dapat dipetakan ke *interrupt* *host*.

Konsumsi Daya:

Rendah, seluruhnya logika digital dengan *clock* tunggal.
LFSR CRC aktif hanya saat *frame* datang, sehingga aktivitas switching minimal saat idle.
Estimasi daya diisi setelah sintesis (power analysis Quartus).

Pendekatan RTL:

Verilog atau SystemVerilog, gaya RTL tersintesiskan penuh, tanpa primitif *vendor*.
*Clock* tunggal dengan reset sinkron atau asinkron yang konsisten.
*Boundary* dibuat sebagai modul terpisah `salaras_serdes_l1`, `salaras_serdes_l2`, `salaras_serdes_l3` yang dapat diaktifkan atau dimatikan lewat parameter.

ISA:

Tidak relevan, ini desain hardwired tanpa instruksi.

IP yang Digunakan:

Tidak menggunakan IP komersial, memakai *baseline* open source dan pustaka standar.

Target FPGA/ASIC & Technology Node:

Target FPGA: Intel Cyclone V SoC (DE10-Nano), 110.000 LE, 1.100 Kbit M10K, 112 DSP.
Target ASIC: Tiny Tapeout 07 flow, PDK open-source SkyWater sky130 (130nm) melalui OpenLane, target 1x1 *tile*.
Satu sumber RTL dipakai untuk FPGA maupun ASIC.

Estimasi Penggunaan *Resource* FPGA:

| Komponen | Estimasi Penggunaan | Kapasitas DE10-Nano |
| --- | --- | --- |
| Logic Elements / LUT | [isi setelah sintesis] | 110,000 LE / 41,910 ALM |
| Registers / Flip-Flops (FF) | [isi setelah sintesis] | 415,000 |
| Block RAM (M10K) | 0 | 5,570 Kbit |
| DSP Blocks | 0 | 112 |

Estimasi area tambahan *boundary*:

| Blok | Perkiraan |
| --- | --- |
| LFSR CRC-24 | sekitar 24 FF dan 10 gerbang XOR |
| *Alignment* *counter* | sekitar 4 FF |
| *Lock* FSM | sekitar 4 *state* |
| *Fault* *register* | sekitar 2 FF |
| *Framing* dan validasi kode | sekitar 10 sampai 20 gerbang |
| Total tambahan | sekitar 40 sampai 60 FF, tanpa BRAM dan tanpa DSP |

Kesimpulan area: estimasi tetap berada pada 1x1 *tile* sky130, dengan *fallback* 1x2 bila placement OpenLane memerlukan ruang tambahan.

Perangkat Lunak & Tools Perancangan:

RTL: Verilog atau SystemVerilog.
Simulasi: Verilator dan Icarus Verilog, cocotb dan pytest.
Sintesis ASIC: Yosys dan OpenLane pada SkyWater sky130.
FPGA: Intel Quartus Prime dan SignalTap.
Board: DE10-Nano Cyclone V SoC.

### 3.2 Security Design

Prinsip: verifikasi di *boundary* sebelum *commit*, *fail-closed*, dan tidak bergantung pada *software* *host*.
Model ancaman: penyerang atau gangguan dapat menyuntik, mengubah, atau menghilangkan bit pada aliran serial.
Tabel berikut memetakan ancaman ke mitigasi.

| Kode | Ancaman | CWE | Mitigasi SALARAS-SERDES |
| --- | --- | --- | --- |
| T1 | Bit flip acak pada *payload* | CWE-354 | L2 mendeteksi ketidakcocokan CRC |
| T2 | Bit flip pada *field* CRC itu sendiri | CWE-354 | L2 membandingkan CRC hitung ulang dengan CRC terima |
| T3 | Kehilangan sinkronisasi *word* | CWE-1264 | L1 *lock* dan recovery, L3 menahan *commit* |
| T4 | Kode 10b tidak sah akibat glitch | CWE-20 | L1 menandai kode tidak sah sebagai error |
| T5 | Pemalsuan data oleh penyerang aktif | CWE-345 | Di luar lingkup CRC; MAC sebagai future work |

Batasan: CRC melindungi dari error acak dan *fault* injection, tetapi tidak melindungi dari pemalsuan berkunci.
MAC direncanakan sebagai pengembangan lanjutan tanpa mengubah kerangka L1/L2/L3.

### 3.3 Rencana Pengujian

Simulasi RTL:

*Testbench* otomatis berbasis cocotb dengan *loopback* *on-chip* antara *serializer* dan *deserializer*.
Skenario:
- *Frame* bersih harus diterima tanpa regresi.
- *Frame* dengan *single-bit flip* pada *payload* harus ditolak.
- *Frame* dengan *single-bit flip* pada *field* CRC harus ditolak.
- Gangguan sinkronisasi *word* harus terdeteksi dan *commit* ditahan.
- Kode 10b tidak sah harus ditandai sebagai error.

Strategi Verifikasi:

*Self-checking* *testbench* dengan assertion, bukan inspeksi *waveform*.
Uji kesetaraan dengan perilaku *baseline* untuk *frame* bersih.
Lint Verilator dan cek sintesis Yosys sebelum implementasi.
Traceability setiap klaim metrik ke satu test case.

Setup *Prototype* (*Loopback*, S1, dan S2):

*Loopback* *on-chip* menghubungkan ser_out ke ser_in untuk verifikasi internal.
S1 adalah jalur simulasi CI memakai cocotb.
S2 adalah jalur wired pada DE10-Nano, dengan *host* PC melalui USB-UART untuk membaca data_out, *valid*, *lock*, dan *fault*, serta untuk memicu *fault* injection pada *buffer* kirim.

Uji *Hardware* Board FPGA DE10-Nano:

Sintesis *bitstream* di Quartus Prime dan unggah ke board.
Verifikasi sinyal internal dengan SignalTap Logic Analyzer.
Pengujian on-board *real-time*: *frame* bersih diterima, *frame* korup ditolak, *fault* naik.

Metrik Keberhasilan Target:

*Detection* rate minimal 99,9 persen pada set *fault* injection (*single-bit flip* pada *payload* dan CRC).
False-reject 0 persen pada *frame* bersih.
*Latency* *overhead* 1 sampai 3 siklus *clock*.
Area target 1x1 *tile*, *fallback* 1x2.
Catatan: CRC-24 secara teori mendeteksi seluruh error satu bit dan seluruh *burst error* sampai 24 bit, sehingga *detection* rate untuk *fault* injection *single-bit flip* diharapkan 100 persen; angka 99,9 persen dipakai sebagai target konservatif pada seluruh set uji, termasuk gangguan *timing*.
Angka final dikonfirmasi setelah simulasi.

## 4. Referensi

- Santeep G, M., dan Shylashree N. "SerDes (tt_um_serdes), Tiny Tapeout 07." Tautan: https://github.com/Santeep/TT_UM_SERDES (halaman resmi: https://tinytapeout.com/chips/tt07/tt_um_serdes)
- PERURI. "Datasheet Tiny Tapeout 7 (Peruri Chip Design)." Tautan: https://chip.peruri.co.id/datasheet.pdf
- MITRE. "CWE-20: Improper Input Validation." Tautan: https://cwe.mitre.org/data/definitions/20.html
- MITRE. "CWE-345: Insufficient Verification of Data Authenticity." Tautan: https://cwe.mitre.org/data/definitions/345.html
- MITRE. "CWE-353: Missing Support for Integrity Check." Tautan: https://cwe.mitre.org/data/definitions/353.html
- MITRE. "CWE-354: Improper Validation of Integrity Check Value." Tautan: https://cwe.mitre.org/data/definitions/354.html
- MITRE. "CWE-1245: Improper Finite State Machines (FSM) in Hardware Logic." Tautan: https://cwe.mitre.org/data/definitions/1245.html
- MITRE. "CWE-1264: Hardware Logic with Insecure De-Synchronization between Control and Data Channels." Tautan: https://cwe.mitre.org/data/definitions/1264.html
- The OpenROAD Project. "OpenLane." Tautan: https://github.com/The-OpenROAD-Project/OpenLane
- Google. "SkyWater PDK (sky130)." Tautan: https://github.com/google/skywater-pdk
- cocotb. "cocotb: coroutine based cosimulation library." Tautan: https://github.com/cocotb/cocotb
- Altera. "Cyclone V FPGA and SoC FPGA." Tautan: https://www.altera.com/products/fpga/cyclone/v
- Terasic. "DE10-Nano - Cyclone V FPGA Guide." Tautan: https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=167&No=1046&PartNo=1#contents

## 5. Lampiran

### Glosarium

- 8b/10b: pengkodean 8 bit menjadi 10 bit untuk keseimbangan DC dan deteksi error.
- *Alignment*: penyelarasan batas *word* pada aliran serial.
- *Burst error*: deretan bit yang berubah secara berurutan.
- *Commit*: menetapkan data dan kendali sebagai sah dan siap dipakai.
- CRC: nilai pemeriksa linear tanpa kunci.
- *Fail-closed*: kegagalan verifikasi menahan data, bukan meloloskannya.
- *Fault*: penanda kegagalan yang dapat dilihat *host*.
- *Frame*: satuan data dengan batas awal dan akhir yang jelas.
- *K-code*: kode kontrol khusus pada 8b/10b.
- LFSR: *register* geser umpan balik linear, mesin CRC.
- *Lock*: *status* penyelarasan yang mantap.
- MAC: nilai pemeriksa berkunci yang tahan pemalsuan.
- PISO: Parallel-In Serial-Out.
- SIPO: Serial-In Parallel-Out.
- *Word*: satuan 10 bit terenkode pada tautan serial.

### Daftar CWE yang Relevan

CWE-20, CWE-345, CWE-353, CWE-354, CWE-1245, dan CWE-1264, dengan catatan mitigasi pada Bagian 2.

### Pembagian Peran dalam Tim

| Nama Anggota | Keahlian Utama | Tanggung Jawab & Peran |
| --- | --- | --- |
| Ibrahim Fauzi Rahman | RTL / Verilog | RTL Designer: desain L1-L3 dan integrasi *baseline* |
| Idris Syaifulloh | Verifikasi / Python | Verification: cocotb, *fault* injection, metrik |
| Dr. Setia Jul Ismail, S.T., M.T. | Arsitektur / Metodologi | Pembimbing: review arsitektur dan metodologi verifikasi |

### Rencana Perubahan saat Bootcamp 3 Hari

| Hari | Fokus Kegiatan | Target Deliverables |
| --- | --- | --- |
| Hari 1 | Finalisasi RTL L1-L3 dan integrasi *baseline* | RTL dapat disimulasikan |
| Hari 2 | *Fault* injection dan verifikasi cocotb | Laporan *detection* rate dan *latency* |
| Hari 3 | Sintesis Quartus, SignalTap, dan demo DE10-Nano | *Bitstream* dan demo on-board |

### Luaran & Demo (Opsional)

Demo Live: pengujian langsung pada board FPGA DE10-Nano: *frame* bersih diterima, *frame* korup ditolak, *fault* naik.
Video Demo: video 3-5 menit yang menunjukkan alur kerja.
Repository Source Code: kode RTL, *testbench* cocotb, skrip *fault* injection, dan *bitstream*.
Laporan Teknis Singkat: spesifikasi arsitektur, hasil sintesis, dan analisis performa.
