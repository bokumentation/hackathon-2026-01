# Template Proposal Peserta Hackathon Chip 2026

Judul: PROPOSAL PESERTA HACKATHON CHIP 2026

Kategori: IC Chip Design & FPGA Implementation

## Identitas Tim

Judul Ide Desain Chip: [ ... ]

Nama Tim: [ … ]

Anggota Tim (2–4 orang):

- Ketua: [Nama Ketua] – [Institusi/Universitas] – [Email/HP]
- Anggota 1: [Nama Anggota] – [Institusi/Universitas] – [Email/HP]
- Anggota 2: [Nama Anggota] – [Institusi/Universitas] – [Email/HP]

Dosen Pembimbing: [Nama Dosen & Gelar] – [Institusi]

## 1. Ringkasan Ide (Executive Summary)

Masalah yang Diangkat:

[Jelaskan problem spesifik di industri/masyarakat yang memerlukan akselerasi *hardware*/perancangan IC]

Solusi yang Ditawarkan:

[Jelaskan konsep arsitektur *hardware*/*IP Core* yang dirancang untuk mengatasi masalah]

Implementasi pada DE10-Nano:

[Ringkasan pemanfaatan FPGA/SoC DE10-Nano, pemetaan ke FPGA *fabric*, dan interaksi HPS/FPGA]

Kebaruan & Keunggulan:

[Tuliskan keungguan implementasi pada *hardware* FPGA / Chip dibanding pendekatan *software*/klasik]

## 2. Latar Belakang & Rumusan Masalah (Problem Statement)

Latar Belakang:

[Deskripsi pentingnya perancangan chip *hardware accelerator* / *IP block* ini.]

Rumusan Masalah & Perancangan:

[Tuliskan gambaran umum tantangan teknis, batasan desain *hardware*, serta fokus perancangan yang ingin diselesaikan melalui arsitektur IC chip ini.]

## 3. Proposed Chip Design

### 3.1 Solusi & Arsitektur Sistem

[ Diagram Blok Sistem ]

[ Rincian Modul RTL ]

[ Estimasi Penggunaan Resource FPGA ]

| Komponen Resource | Estimasi Penggunaan | Kapasitas DE10-Nano |
| --- | --- | --- |
| Logic Elements / LUT | [...] | 110,000 LEs / 41,910 ALMs |
| Registers / Flip-Flops (FF) | [...] | 415,000 |
| Block RAM (M10K) | [...] | 5,570 Kbits |
| DSP Blocks | [...] | 112 DSP |
| [...] | | |

Perangkat Lunak & Tools Perancangan:

[ Intel Quartus Prime, ModelSim / Verilator, Platform Designer (Qsys), Python/C. Lainnya ]

### 3.2 Rencana Pengujian

Simulasi RTL:

Penyusunan *testbench* otomatis, verifikasi fungsionalitas sinyal, skenario *corner-case*, serta analisis *timing*/*latency*.

Uji Hardware Board FPGA DE10-Nano:

Prosedur sintesis, implementasi *bitstream*, verifikasi SignalTap Logic Analyzer, dan pengujian *on-board real-time*.

Metrik Keberhasilan Target:

Akurasi, latensi, efisiensi perfoma, dll.

## 4. Referensi

[ Tautkan diagram arsitektur tambahan, cuplikan/*snippet* kode RTL penting, grafik hasil simulasi, serta referensi jurnal/paper pendukung jika ada. ]

## 5. Lampiran

[ Tautkan diagram arsitektur tambahan, cuplikan/*snippet* kode RTL penting, grafik hasil simulasi, serta referensi jurnal/paper pendukung jika ada. ]

### Tim & Pembagian Peran

| Nama Anggota | Keahlian Utama | Tanggung Jawab & Peran |
| --- | --- | --- |
| [Nama Ketua] | [...] | [...] |
| [Nama Anggota 1] | [...] | [...] |
| [Nama Anggota 2] | [...] | [...] |

### Luaran & Demo (Opsional)

Demo Live:

[ Pengujian langsung sistem pada *board* FPGA DE10-Nano secara *real-time*. ]

Video Demo:

[ Video singkat durasi 3–5 menit yang menunjukkan fungsionalitas dan alur kerja *hardware*. ]

Repository Source Code:

[ Kode RTL (Verilog/SystemVerilog/VHDL), *script testbench*, dan file *bitstream* (.sof/.rbf). ]

Laporan Teknis Singkat:

[ Dokumentasi spesifikasi arsitektur, hasil sintesis, dan analisis performa.

### Rencana Bootcamp (3 Hari) (Opsional)

Jadwal & Target Eksekusi:

| Hari | Fokus Kegiatan | Target Deliverables |
| --- | --- | --- |
| Hari 1 | [...] | [...] |
| Hari 2 | [...] | [...] |
| Hari 3 | [...] | [...] |

## Catatan Konversi

1. Dokumen sumber berupa kerangka isian peserta sehingga seluruh penanda *placeholder* seperti `[ ... ]` dan `[...]` dipertahankan apa adanya agar tetap dapat diisi.
2. Bagian 3.2 Rencana Pengujian berlanjut ke halaman 3 dengan dua butir tambahan, yaitu Uji Hardware Board FPGA DE10-Nano dan Metrik Keberhasilan Target.
3. Judul tanpa nomor setelah bagian 5 Lampiran, yaitu Tim & Pembagian Peran, Luaran & Demo (Opsional), dan Rencana Bootcamp (3 Hari) (Opsional), ditampilkan sebagai subbagian lampiran sesuai penjelasan pada Buku Panduan Peserta.
4. Kesalahan tulis pada dokumen sumber, yaitu "keungguan" dan "perfoma", serta tanda `]` penutup yang hilang pada akhir Laporan Teknis Singkat, dipertahankan agar isi sesuai dokumen asli.
5. Dokumen sumber tidak memuat gambar, tautan hiperteks, maupun catatan kaki, sehingga tidak ada lampiran tambahan berupa berkas citra atau tabel tautan.
6. Nomor halaman: bagian 1 sampai 3.1 berada pada halaman 1 dan 2, bagian 3.2 dan 4 serta 5 berada pada halaman 2 dan 3, sedangkan Rencana Bootcamp berada pada halaman 4.
