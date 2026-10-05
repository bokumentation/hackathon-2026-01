# **PROPOSAL PESERTA HACKATHON CHIP 2026**

## Kategori: IC Chip Design & FPGA Implementation

# Identitas Tim

**Judul Ide Desain Chip:** SALARAS-RX: A Hardware-Enforced Secure Ingress Barrier for Manchester/RF Serial Links

**Nama Tim:** dinotice  
**Anggota Tim:**

* Ketua: Ibrahim Fauzi Rahman – Universitas Telkom – [\+62 857-2774-6841](https://wa.me/085727746841)  
* Anggota 1: Idris Syaifulloh – Universitas Telkom – [\+62 895-3309-78461](http://wa.me/+62895330978461)

**Dosen Pembimbing:** Dr. Setia Jul Ismail, S.T., M.T. – Universitas Telkom 

# 1\. Ringkasan Ide (Executive Summary)

**Masalah yang Diangkat:**  
*\[Jelaskan problem spesifik di industri/masyarakat yang memerlukan akselerasi hardware/perancangan IC\]*  
Penerima serial/RF ringan konvensional menguraikan bitstream yang tidak tepercaya langsung ke dalam shift register tanpa validasi lapis tautan yang memadai, memicu kerentanan pada *Finite State Machine* (FSM) yang rapuh (CWE-1245), de-sinkronisasi kendali/data akibat jitter atau *glitch* (CWE-1264), serta tidak diverifikasinya kecocokan CRC-24 (*Cyclic Redundancy Check*) pada baseline [⁠tt07-bep-decode](https://github.com/DusterTheFirst/tt07-bep-decode)⁠ (CWE-354).

**Solusi yang Ditawarkan:**  
*\[Jelaskan konsep arsitektur hardware/IP Core yang dirancang untuk mengatasi masalah\]*  
Untuk mengatasi keterbatasan baseline tersebut, SELARAS-RX menyisipkan pembatas perangkat keras (*hardware barrier*) antara dekoder Manchester dan register host:

- L1 memvalidasi timing Manchester dan legalitas FSM;  
- L2 memverifikasi kecocokan CRC-24;  
- L3 melakukan *gating* atomik pada full/latch enable dan membangkitkan fault. Data dan kendali dikomit bersamaan hanya ketika frame terbukti sah.

**Target Pengguna:**

* Perancang secure element dan smart card IC;  
* Integrator IP untuk sistem identitas digital serta;  
* Tim firmware yang membutuhkan jaminan integritas frame sebelum data masuk ke memori host.

**Implementasi pada DE10-Nano:**  
*\[Ringkasan pemanfaatan FPGA/SoC DE10-Nano, pemetaan ke FPGA fabric, dan interaksi HPS/FPGA\]*  
Prototyping awal dan verifikasi hardware-in-the-loop dilakukan menggunakan board FPGA DE10-Nano. RTL disintesis pada FPGA fabric, sementara Hard Processor System (HPS) bertindak sebagai generator bitstream Manchester untuk mensimulasikan transmisi RF bising, pengujian timing, dan respons fault.

**Kebaruan & Keunggulan:**  
*\[Tuliskan keungguan implementasi pada hardware FPGA / Chip dibanding pendekatan software/klasik\]*

- Menghadirkan verifikasi integritas sepenuhnya di jalur hardware, tanpa intervensi software pada saat frame masuk.  
- Menurunkan risiko frame korup/misaligned mencapai host, memberi deteksi yang terukur (detection rate, false-reject, latency), dan menyediakan boundary fail-closed untuk ingress secure element.

# 2\. Latar Belakang & Rumusan Masalah (Problem Statement)

**Latar Belakang: masih belum kuat**  
*\[Deskripsi pentingnya perancangan chip hardware accelerator / IP block ini.\]*  
\[Deskripsi pentingnya perancangan chip hardware accelerator / IP block ini.\]  
Receiver serial/RF ringan konvensional umumnya memparsing bitstream yang tidak tepercaya langsung ke dalam shift register. Mesin state (FSM) pemrosesan mereka sering kali mengabaikan penanganan illegal-state, timeout, dan validasi timing yang kokoh (CWE-1245). Selain itu, sinyal kendali seperti penanda full, bit counter, dan latch enable rentan mengalami desinkronisasi dari data shift register akibat glitch, jitter, tepi pulsa yang hilang, atau injeksi gangguan fisik (CWE-1264).   

Celah ini terwujud pada baseline yang diperluas dalam perancangan ini: tt07-bep-decode (dekoder Manchester Tiny Tapeout 7 atau TT07), secara arsitektural menerima medan CRC-24 (tail\_1..3) tetapi mengeksposnya langsung ke host tanpa pemeriksaan kecocokan pada RTL baseline. Akibatnya, frame data yang rusak atau tidak selaras dapat terlanjur di-latch sebagai data sah tanpa verifikasi integritas (CWE-354).

**Rumusan Masalah & Perancangan:**  
*\[Tuliskan gambaran umum tantangan teknis, batasan desain hardware, serta fokus perancangan yang ingin diselesaikan melalui arsitektur IC chip ini.\]*

1. Bagaimana merancang FSM parsing yang tahan illegal-state dan timeout, serta gerbang komit atomik yang mencegah de-sinkronisasi kontrol/data akibat glitch atau jitter (CWE-1245, CWE-1264)?  
2. Bagaimana memvalidasi nilai CRC-24 yang sudah ada di dalam frame tanpa mengubah format frame atau menambah buffer besar (CWE-354)?  
3. Bagaimana mencapai keduanya dalam batasan area 1-tile sky130 pada TT07 dengan latency terukur?

Untuk mengatasi keterbatasan baseline tersebut, SELARAS-RX menyisipkan pembatas perangkat keras (*hardware barrier*) antara dekoder Manchester dan register host:

- L1 memvalidasi timing Manchester dan legalitas FSM;  
- L2 memverifikasi kecocokan CRC-24;  
- L3 melakukan gating atomik pada full/latch enable dan membangkitkan fault. Data dan kendali dikomit bersamaan hanya ketika frame terbukti sah.

Data dan kendali dikomit secara bersamaan hanya ketika bingkai terbukti sah sehingga secara langsung memitigasi CWE-1264 dan CWE-1245 serta menutup celah validasi integritas (CWE-354) langsung pada tingkat silikon di atas modul ⁠tt07-bep-decode⁠.

# 3\. Proposed Chip Design

# 3.1 Solusi & Arsitektur Sistem

**\[ Diagram Blok Sistem \]**  
RF/Manchester → \[Manchester Decoder\] → L1 (FSM/Timing) → L2 (CRC-24) → L3 (Atomic Commit) → Host Register

- L1: Validates Manchester timing, enforces legal FSM transitions, timeout counter.  
- L2: Computes CRC-24 over frame and compares with tail\_1..3. No large buffer — streaming check.  
- L3: Single-cycle enable, synchronized latch, glitch-free gating. Fault output (sticky \+ interrupt).  
- Host interface: Simple register map (status, fault, data). No software intervention during frame ingress.

**\[ Rincian Modul RTL \]**


**\[ Estimasi Penggunaan Resource FPGA \]**

| Komponen Resource | Estimasi Penggunaan | Kapasitas DE10-Nano |
| :---: | ----- | ----- |
| Logic Elements / LUT | 1200 | 110,000 LEs / 41,910 ALMs |
| Registers / Flip-Flops (FF) | 800 | 415,000 |
| Block RAM (M10K) | 0-1 | 5,570 Kbits |
| DSP Blocks | 0 | 112 DSP |
| \[...\] |  |  |

**Perangkat Lunak & Tools Perancangan:**

* RTL: Verilog/SystemVerilog.  
* Simulation: Verilator, cocotb.  
* Synthesis: Yosys, OpenROAD (sky130).  
* FPGA: Intel Quartus Prime, Platform Designer.  
* Board: DE10-Nano (Cyclone V SoC).

*\[ Intel Quartus Prime, ModelSim / Verilator, Platform Designer (Qsys), Python/C. Lainnya \]*

# 

# 3.2 Rencana Pengujian

**\[ Simulasi RTL: \]** Penyusunan testbench otomatis, verifikasi fungsionalitas sinyal, skenario  
corner-case, serta analisis timing/latency.  
**\[ Uji Hardware Board FPGA DE10-Nano: \]** Prosedur sintesis, implementasi bitstream,  
verifikasi SignalTap Logic Analyzer, dan pengujian on-board real-time.  
**\[ Metrik Keberhasilan Target: Akurasi, latensi, efisiensi perfoma, dll \]**

# 

# 4\. Referensi

*\[ Tautkan diagram arsitektur tambahan, cuplikan/snippet kode RTL penting, grafik hasil simulasi, serta referensi jurnal/paper pendukung jika ada. \]*

- CWE Series  
- eKTP Spec  
- Real Insiden?

# 5\. Lampiran

\[ Tautkan diagram arsitektur tambahan, cuplikan/snippet kode RTL penting, grafik hasil simulasi, serta referensi jurnal/paper pendukung jika ada. \]

# Tim & Pembagian Peran

| Nama Anggota | Keahlian Utama | Tanggung Jawab & Peran |
| :---: | ----- | ----- |
| \[Nama Ketua\] |  |  |
| \[Nama Anggota 1\] |  |  |
| \[Nama Anggota 2\] |  |  |

# Luaran & Demo (Opsional)

**Demo Live:**  
\[ Pengujian langsung sistem pada board FPGA DE10-Nano secara real-time. \]  
**Video Demo:**  
\[ Video singkat durasi 3–5 menit yang menunjukkan fungsionalitas dan alur kerja hardware. \]  
**Repository Source Code: ​**  
\[ Kode RTL (Verilog/SystemVerilog/VHDL), script testbench, dan file bitstream (.sof/.rbf). \]  
**Laporan Teknis Singkat:**  
\[ Dokumentasi spesifikasi arsitektur, hasil sintesis, dan analisis performa.

# Rencana Bootcamp (3 Hari) (Opsional)

Jadwal & Target Eksekusi:

| Hari | Fokus Kegiatan | Target Deliverables |
| :---: | ----- | ----- |
| **Hari 1** |  |  |
| **Hari 2** |  |  |
| **Hari 3** |  |  |

