# Simulasi Penjurian TRI-ARGA

Dokumen ini adalah simulasi penjurian internal untuk proposal TRI-ARGA pada PERURI Chip Hackathon 2026, Area 04 Secure Communication.

Simulasi disusun dari kondisi nyata repositori dan proposal saat ini, bukan dari klaim yang belum diukur.

## Tujuan dan Metode

Tujuan simulasi adalah memperkirakan penilaian panel, menemukan celah sebelum kurasi, dan menyiapkan jawaban atas pertanyaan kritis.

Rubrik resmi tidak dipublikasikan oleh penyelenggara.
Bobot dan kriteria di bawah disusun sebagai asumsi yang masuk akal dari lima struktur proposal dan aturan teknis pada `docs/competition/`.

Panel disusun dari dua profil penjuri yang kemungkinan terlibat, ditambah tiga peran generik untuk menutup tujuh kriteria.
Profil penjuri berasal dari data publik dan bersifat inferensi, bukan penetapan resmi.

Sumber kebenaran yang dipakai: `src/`, `test/`, `synth/formal/`, `sim/RESULTS.md`, `synth/area.md`, `docs/design/quartus-report.md`, dan `docs/proposal/proposal.id.md`.

## Panel Penjuri

| Kode | Peran | Sudut pandang |
| --- | --- | --- |
| J1 | Dr. Adi Saputra (inferensi) | Teknis, keamanan, DevSecOps, desain chip |
| J2 | Ahsan Mubariz (inferensi) | Produk, identitas digital, Agile, dampak |
| J3 | Ahli kriptografi perangkat keras | Pilihan cipher, batas keamanan, manajemen kunci |
| J4 | Juri hilirisasi produk | Nilai pengguna, adopsi, kemitraan, biaya integrasi |
| J5 | Juri metodologi dan verifikasi | Kualitas bukti, konsistensi klaim, reproduksibilitas |

J1 dan J2 mewakili dua sumbu yang saling melengkapi: kedalaman teknis-keamanan dan kerangka produk-identitas.
J3 sampai J5 mengisi celah yang tidak selalu muncul dari profil publik.

## Rubrik dan Bobot

| Kriteria | Bobot |
| --- | --- |
| Relevansi masalah | 15 |
| Kebaruan dan keunggulan | 15 |
| Kualitas teknis dan arsitektur | 20 |
| Keamanan dan *threat model* | 20 |
| Kelayakan dan verifikasi | 15 |
| Dampak dan hilirisasi | 10 |
| Kepatuhan dan kejelasan | 5 |

## Matriks Skor

Setiap sel adalah skor 0 sampai 100 untuk kriteria tersebut.

| Kriteria (bobot) | J1 | J2 | J3 | J4 | J5 | Rata-rata |
| --- | --- | --- | --- | --- | --- | --- |
| Relevansi masalah (15) | 88 | 90 | 85 | 86 | 87 | 87,2 |
| Kebaruan dan keunggulan (15) | 80 | 82 | 78 | 84 | 80 | 80,8 |
| Kualitas teknis dan arsitektur (20) | 85 | 80 | 84 | 78 | 83 | 82,0 |
| Keamanan dan *threat model* (20) | 82 | 80 | 80 | 76 | 82 | 80,0 |
| Kelayakan dan verifikasi (15) | 84 | 78 | 82 | 80 | 83 | 81,4 |
| Dampak dan hilirisasi (10) | 78 | 86 | 76 | 85 | 80 | 81,0 |
| Kepatuhan dan kejelasan (5) | 76 | 80 | 78 | 82 | 74 | 78,0 |
| Total terbobot | 82,8 | 82,1 | 81,1 | 80,9 | 82,2 | 81,8 |

Rata-rata panel sekitar 81,8 dari 100.
Sebaran skor sempit, artinya tidak ada kriteria yang sangat lemah, tetapi juga belum ada yang sangat menonjol.

## Catatan Kualitatif per Juri

### J1, teknis dan keamanan

Yang dipuji: arsitektur tiga lapis yang jelas, pilihan SIMON-32/64 yang hemat area, CBC-MAC panjang tetap, dan bukti formal yang kini seluruhnya lulus.

Yang dipersoalkan: tag 32 bit memberi peluang forgery sekitar 2 pangkat -32, batas *birthday* blok 32 bit menuntut rotasi kunci, dan manajemen kunci masih diserahkan ke *host*.

Pertanyaan yang akan diajukan: mengapa SIMON dan bukan Ascon, bagaimana kunci diprovisi, dan apakah klaim *fail-closed* benar-benar terverifikasi untuk modul inti, bukan hanya versi lampiran RF.

Catatan penting: komposisi bukti formal masih mencampur inti dan lampiran RF.
Tiga job (`l1_framing`, `l2_integrity`, `l3_commit`) memverifikasi RTL lampiran RF, bukan modul inti yang diklaim.
Ini perlu disampaikan apa adanya.

### J2, produk dan identitas

Yang dipuji: relevansi langsung ke kebutuhan identitas dan pembayaran Peruri, serta narasi batas kepercayaan yang mudah dipahami.

Yang dipersoalkan: belum ada jalur integrasi konkret ke INApas atau Peruri ID, dan belum ada standar yang dirujuk untuk format *frame*.

Pertanyaan yang akan diajukan: siapa pengguna akhirnya, apa nilai terukurnya, dan berapa biaya integrasi serta operasionalnya, termasuk rotasi kunci.

### J3, kriptografi perangkat keras

Yang dipuji: kesadaran akan batas CBC-MAC panjang tetap dan peluang forgery, serta kesediaan mengganti cipher di balik antarmuka blok.

Yang dipersoalkan: tidak ada bukti keamanan kriptografis, tidak ada klaim kerahasiaan, dan CBC-MAC dengan kunci tetap bukan *authenticated encryption*.

Pertanyaan yang akan diajukan: mengapa bukan CMAC atau AEAD, dan bagaimana perilaku setelah reset terhadap *replay* lintas siklus daya.

### J4, hilirisasi

Yang dipuji: biaya area di bawah 0,08 milimeter persegi dan daya inti kecil, sehingga cocok untuk perangkat terbatas.

Yang dipersoalkan: belum ada demonstrasi pada *front-end* resmi Area 04, baik SerDes TT07 maupun CDC FIFO, dan belum ada *bitstream* serta bukti *on-board*.

Pertanyaan yang akan diajukan: kapan integrasi ke *baseline* resmi dilakukan dan apa bukti *end-to-end*-nya.

### J5, metodologi dan verifikasi

Yang dipuji: simulasi *cocotb* yang terukur, bukti formal yang kini lulus, dan CI yang menjaga lint, sintesis, serta pengujian.

Yang dipersoalkan: angka ASIC yang ditampilkan berasal dari revisi sebelum perbaikan *wrapper*, sehingga belum mencerminkan desain saat ini.
Panjang proposal juga melampaui batas enam halaman di luar sampul, daftar pustaka, dan lampiran.

Pertanyaan yang akan diajukan: kapan Aksi GDS dijalankan ulang untuk revisi saat ini dan bagaimana klaim angka diperbarui.

## Temuan Utama

Kekuatan:

- RTL inti lengkap dan konsisten: pemuat serial L1, autentikasi SIMON CBC-MAC L2, dan *commit* atomik *fail-closed* L3.
- Bukti simulasi terukur: 128 dari 128 *bit flip* ditolak, nol *false reject* dari 20 *frame* bersih, latensi ujung ke ujung 108 siklus.
- Bukti formal tujuh job lulus pada pohon saat ini.
- Sintesis FPGA DE10-Nano terukur: 242 ALM, 654 *flip-flop*, Fmax 136,37 MHz.
- Lampiran RF diposisikan jujur sebagai bukti kelas kerentanan, bukan jalur integritas yang diklaim selesai.

Keterbatasan dan risiko:

- Angka ASIC masih revisi lama. Aksi GDS harus dijalankan ulang untuk *wrapper* saat ini.
- Proposal melebihi batas enam halaman untuk bagian inti.
- Klaim penutupan CWE-20 belum didukung validasi *framing* di inti; pemuat hanya menggeser bit.
- Tier B dan Tier C belum dibangun, sehingga klaim tautan serial aman belum dapat diajukan.
- Manajemen kunci, *counter* lintas siklus daya, dan ketahanan kanal samping berada di luar cakupan.
- Sebagian bukti formal masih mencakup lampiran RF, bukan modul inti.

## Pertanyaan Kritis dan Jawaban

| Pertanyaan | Jawaban singkat | Bukti |
| --- | --- | --- |
| Mengapa SIMON dan bukan Ascon | Datapath kecil yang dapat diserialkan muat di *tile* 2x2; antarmuka blok dapat diganti ke SIMON-64/128 atau Ascon dengan area lebih besar | `docs/design/trade-study.md`, proposal bagian 3.2 |
| Batas forgery dan *birthday* | Sekitar 2 pangkat -32 per percobaan; rotasi kunci di bawah batas *birthday* blok 32 bit | proposal bagian 3.2, Lampiran G |
| Bagaimana kunci ditangani | Dimuat sekali dari jalur *host* terpercaya, terkunci sampai reset, tidak melewati tautan | `src/l1_serial_loader.v`, Lampiran H |
| Apakah RTL dapat disintesis dan bersih | Pemeriksaan sintesis Yosys dan lint Verilator berjalan di CI | `make lint`, `make synth-check` |
| Apakah bukti formal nyata | Tujuh job lulus; sebagian mencakup lampiran RF dan harus disampaikan apa adanya | `synth/formal/`, README |
| Bagaimana angka ASIC | Revisi lama; Aksi GDS perlu dijalankan ulang untuk desain saat ini | `synth/area.md`, README |
| Bagaimana integrasi ke produk Peruri | Inti duduk di belakang *front-end* serial dan hanya mengomit *frame* terverifikasi; *host* menyediakan kunci dan kebijakan *counter* | proposal bagian 3.1 dan 3.2 |
| Bagaimana dengan *field* integritas RF | Tidak terdokumentasi dan belum dipecahkan, tetap sebagai bukti masalah | `sim/RESULTS.md`, `tools/README.md` |

## Verdict

Panel menilai proposal layak melaju dengan syarat.
Rata-rata 81,8 menempatkan proposal pada jalur kuat untuk seleksi, dengan syarat catatan berikut dikerjakan:

1. Jalankan Aksi GDS untuk revisi saat ini dan perbarui angka ASIC, atau tandai jelas sebagai revisi lama.
2. Rapikan panjang proposal agar inti tidak melebihi enam halaman.
3. Perbaiki pelabelan scope bukti formal antara inti dan lampiran RF, dan hentikan klaim penutupan CWE-20 tanpa validasi *framing*.
4. Siapkan narasi integrasi ke identitas Peruri dan rencana Tier B pada *bootcamp*.

Tanpa perbaikan tersebut, skor tertahan pada kisaran rendah delapan puluhan.

## Catatan dan Batasan

Rubrik dan bobot bersifat asumsi, bukan ketentuan resmi.
Identitas dan prioritas J1 dan J2 adalah inferensi dari profil publik, bukan konfirmasi.
Skor bersifat perkiraan internal dan tidak menggantikan penilaian resmi penyelenggara.
