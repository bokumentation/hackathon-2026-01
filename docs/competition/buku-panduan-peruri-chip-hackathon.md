# Buku Panduan Peserta PERURI Chip Hackathon 2026

Konversi dokumen Buku Panduan Peserta PERURI Chip Hackathon 2026 ke dalam format markdown.

| Atribut | Keterangan |
| --- | --- |
| Judul dokumen | Buku Panduan Peserta |
| Subjudul dokumen | Hackathon Desain Chip & Semikonduktor |
| Nama acara | PERURI Chip Hackathon 2026 |
| Berkas sumber | docs/Buku-Panduan-PERURI-Chip-Hackathon.pdf |
| URL sumber | https://summit.peruri.co.id/docs/Buku-Panduan-PERURI-Chip-Hackathon.pdf |
| Laman terkait | https://summit.peruri.co.id/hackathon |
| Jumlah halaman | 4 |
| Ukuran halaman | A4 (595 x 842 pt) |
| Produsen berkas | iLovePDF |
| Tanggal modifikasi berkas | 22 September 2026 |
| Tanggal akses | 27 September 2026 |

## Daftar Isi

1. [Halaman Sampul](#halaman-sampul)
2. [Ringkasan Kompetisi](#ringkasan-kompetisi)
3. [Syarat Kepesertaan](#syarat-kepesertaan)
4. [Jadwal Kegiatan](#jadwal-kegiatan)
5. [Topik Desain](#topik-desain)
6. [Referensi dan Baseline Teknis](#referensi-dan-baseline-teknis)
7. [Ketentuan Proposal](#ketentuan-proposal)
8. [Aturan Teknis Tambahan](#aturan-teknis-tambahan)
9. [Tautan dalam Dokumen](#tautan-dalam-dokumen)

## Halaman Sampul

PERURI Chip Hackathon 2026

Buku Panduan Peserta

Kaki halaman: summit.peruri.co.id/hackathon

## Ringkasan Kompetisi

Judul bagian: Buku Panduan Peserta

Subjudul: Hackathon Desain Chip & Semikonduktor

Kompetisi ini menantang Anda merancang chip atau IP semikonduktor dari tahap ide, desain teknis, hingga simulasi prototipe. Anda tidak perlu memulai dari nol. Penyelenggara menyediakan desain dasar (*baseline*) agar Anda bisa langsung berfokus pada inovasi fitur, optimasi, dan keamanan perangkat keras.

## Syarat Kepesertaan

| Aspek | Ketentuan |
| --- | --- |
| Status | Mahasiswa aktif jenjang D3, D4, dan S1 perguruan tinggi di seluruh Indonesia |
| Tim | Anda dapat mendaftar dalam tim yang terdiri dari maksimal empat orang serta satu orang dosen pembimbing |

## Jadwal Kegiatan

Berikut adalah alur tahapan yang harus Anda ikuti sepanjang *hackathon*. Tanggal di bawah adalah tenggat waktu maksimal untuk setiap fase.

| Event | Tanggal | Tahapan | Keterangan |
| --- | --- | --- | --- |
| Event. [01] | 23 Sept - 8 Okt 2026 | Registrasi *Hackathon* | Publikasi, *Roadshow*, dan Pembukaan Registrasi resmi. |
| Event. [02] | 8 Oktober 2026 | Akhir Registrasi *Hackathon* | Penutupan masa pendaftaran tim secara serentak. |
| Event. [03] | 8 Oktober 2026 | Batas Pengumpulan Proposal | Pengumpulan proposal sebagai kurasi tahap pertama. |
| Event. [04] | 13 Oktober 2026 | Pengumuman Top 5 | Pengumuman 5 tim finalis yang akan mengikuti *Bootcamp*. |
| Event. [05] | 18 - 20 Oktober 2026 | *Bootcamp* Top 5 | Karantina intensif, *mentoring*, dan penyaringan Top 3. |
| Event. [06] | 21 - 22 Oktober 2026 | *Summit* & Award | Panggung final, presentasi, dan pengumuman pemenang. |

Catatan tata letak: pada dokumen PDF kartu jadwal disusun dalam dua baris, yaitu Event 01 sampai 03 pada baris pertama dan Event 04 sampai 06 pada baris kedua yang tercetak dari kanan ke kiri. Urutan tabel di atas mengikuti kode Event.

## Topik Desain

Pilih satu dari empat area fokus berikut untuk proyek tim Anda.

| Nomor | Area Fokus | Deskripsi | *Reference baseline* |
| --- | --- | --- | --- |
| 01 | *Secure Identity & Security Element Chip* | Pengembangan *secure element*/*identity-oriented function* dengan fokus *authentication*, *integrity*, *key handling*, dan *anti-tamper*. | Peruri chip design, TT07 SHA-256, ECC, PUF |
| 02 | *Hardware Cryptography Accelerator* | Mengembangkan blok kriptografi kecil dan hemat area yang dapat diintegrasikan ke *baseline*. | TT07 SHA-256, *Other Crypto Designs* |
| 03 | AI / *Edge Accelerator* | Menambahkan *accelerator* untuk MAC, *small neural network*, *vector/compute workload*, atau *edge inference*. | TT07 Iterative MAC, TinyTPU, *Mini AIE references* |
| 04 | *Secure Communication* | Meningkatkan *serial/parallel communication*, CDC, *protocol security*, *secure framing*, atau *interface integrity*. | TT07 SerDes, CDC FIFO |

## Referensi dan Baseline Teknis

Gunakan referensi berikut untuk mempercepat perancangan Anda.

1. Tiny Tapeout 7: rujukan untuk gerbang logika, UART, automasi pengujian, hingga arsitektur dasar seperti CPU/RISC-V dan kriptografi (https://tinytapeout.com/digital_design/).
2. Peruri Chip Design: datasheet *baseline* resmi yang bisa Anda optimasi atau integrasikan dengan blok buatan Anda (https://chip.peruri.co.id/datasheet.pdf).
3. Panduan FPGA DE1-Nano - Cyclone V, dengan tautan Spesifikasi dan Manual Guide menuju https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=167&No=1046&PartNo=1#contents

## Ketentuan Proposal

Proposal Anda adalah tiket masuk kompetisi. Dokumen wajib disusun secara berurutan menggunakan 5 struktur berikut.

1. Ringkasan Ide / Executive Summary: menjelaskan masalah, solusi, chip yang dirancang, target pengguna, dan dampak.
2. Latar Belakang & Rumusan Masalah / Problem Statement: menjelaskan mengapa chip diperlukan, masalah yang hendak diselesaikan, dan *gap* terhadap solusi yang tersedia.
3. Proposed Chip Design: menjelaskan arsitektur chip (*chip architecture*), fungsi utama, diagram blok (*block diagram*), input/output, arsitektur pemrosesan, arsitektur memori, antarmuka (*interface*), komunikasi, dan pertimbangan konsumsi daya. Menjelaskan arsitektur, pendekatan RTL, ISA (jika relevan), IP yang digunakan, strategi verifikasi, strategi simulasi, target FPGA/ASIC, dan target *technology node* (jika relevan). Pengujian untuk *design* chip yang dapat dilakukan untuk memastikan *design*-nya berjalan sesuai arsitektur.
4. Referensi: referensi dari *design* chip yang dipakai.
5. Lampiran: lampiran file berubah rencana saat *bootcamp* 3 hari, identitas personal tim, pembagian peran dalam tim, dan informasi lainnya.

## Aturan Teknis Tambahan

1. Anda diizinkan menggunakan *tools* seperti Altera Quartus, OpenROAD, Yosys, Verilator, cocotb, dan SkyWater Open PDK.
2. Desain keamanan (pada bagian Security Design) harus menjadi fondasi awal rancangan Anda (*security-by-design*), bukan sekadar fitur tempelan di akhir.

## Tautan dalam Dokumen

| Teks pada dokumen | URL |
| --- | --- |
| tinytapeout.com/digital_design (Tiny Tapeout 7) | https://tinytapeout.com/digital_design/ |
| chip.peruri.co.id/datasheet.pdf (Peruri Chip Design) | https://chip.peruri.co.id/datasheet.pdf |
| Spesifikasi (Panduan FPGA DE1-Nano - Cyclone V) | https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=167&No=1046&PartNo=1#contents |
| Manual Guide (Panduan FPGA DE1-Nano - Cyclone V) | https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=167&No=1046&PartNo=1#contents |

Kaki halaman setiap halaman dokumen memuat alamat laman: summit.peruri.co.id/hackathon
