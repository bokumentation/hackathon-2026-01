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
| Relevansi masalah (15) | 89 | 90 | 86 | 87 | 88 | 88,0 |
| Kebaruan dan keunggulan (15) | 84 | 85 | 82 | 86 | 84 | 84,2 |
| Kualitas teknis dan arsitektur (20) | 89 | 84 | 88 | 83 | 88 | 86,4 |
| Keamanan dan *threat model* (20) | 86 | 83 | 84 | 80 | 86 | 83,8 |
| Kelayakan dan verifikasi (15) | 88 | 82 | 86 | 84 | 88 | 85,6 |
| Dampak dan hilirisasi (10) | 80 | 87 | 78 | 86 | 82 | 82,6 |
| Kepatuhan dan kejelasan (5) | 84 | 86 | 84 | 87 | 84 | 85,0 |
| Total terbobot | 86,5 | 85,5 | 85,0 | 84,4 | 86,2 | 85,5 |

Rata-rata panel sekitar 85,5 dari 100.
Kenaikan dari audit sebelumnya berasal dari proposal yang kini konsisten dengan bukti, inti yang muat enam halaman, angka ASIC dan FPGA yang mutakhir, serta tautan serial Tier B yang sudah dibangun.

## Catatan Kualitatif per Juri

### J1, teknis dan keamanan

Yang dipuji: arsitektur tiga lapis yang jelas, pilihan SIMON-32/64 yang hemat area, CBC-MAC panjang tetap, bukti formal yang seluruhnya lulus, dan tautan serial 8b/10b Tier B dengan *word lock*.

Yang dipersoalkan: tag 32 bit memberi peluang forgery sekitar 2 pangkat -32, batas *birthday* blok 32 bit menuntut rotasi kunci, dan manajemen kunci masih diserahkan ke *host*.

Pertanyaan yang akan diajukan: mengapa SIMON dan bukan Ascon, bagaimana kunci diprovisi, dan bagaimana perilaku *replay* lintas siklus daya.

### J2, produk dan identitas

Yang dipuji: relevansi langsung ke kebutuhan identitas dan pembayaran Peruri, serta narasi batas kepercayaan yang mudah dipahami.

Yang dipersoalkan: belum ada jalur integrasi konkret ke INApas atau Peruri ID, dan belum ada standar yang dirujuk untuk format *frame*.

Pertanyaan yang akan diajukan: siapa pengguna akhirnya, apa nilai terukurnya, dan berapa biaya integrasi serta operasionalnya, termasuk rotasi kunci.

### J3, kriptografi perangkat keras

Yang dipuji: kesadaran akan batas CBC-MAC panjang tetap dan peluang forgery, serta kesediaan mengganti cipher di balik antarmuka blok.

Yang dipersoalkan: tidak ada bukti keamanan kriptografis, tidak ada klaim kerahasiaan, dan CBC-MAC dengan kunci tetap bukan *authenticated encryption*.

Pertanyaan yang akan diajukan: mengapa bukan CMAC atau AEAD, dan bagaimana perilaku setelah reset terhadap *replay* lintas siklus daya.

### J4, hilirisasi

Yang dipuji: biaya area di bawah 0,08 milimeter persegi dan daya inti kecil, sehingga cocok untuk perangkat terbatas; tautan serial Tier B menyentuh langsung *front-end* resmi Area 04.

Yang dipersoalkan: demonstrasi on-board dan *bitstream* masih menunggu *bootcamp*, sehingga belum ada bukti *end-to-end* pada papan.

Pertanyaan yang akan diajukan: kapan integrasi *on-board* dilakukan dan apa bukti *end-to-end*-nya.

### J5, metodologi dan verifikasi

Yang dipuji: simulasi *cocotb* yang terukur, sembilan bukti formal yang lulus, sintesis Quartus yang nyata, dan CI yang menjaga lint, sintesis, serta pengujian.

Yang dipersoalkan: angka daya FPGA masih estimasi *vector-less*, dan hasil tautan serial masih simulasi, bukan pengukuran on-board.

Pertanyaan yang akan diajukan: kapan pengukuran *on-board* dan daya nyata diambil.

## Temuan Utama

Kekuatan:

- RTL inti lengkap dan konsisten: pemuat serial L1, autentikasi SIMON CBC-MAC L2, dan *commit* atomik *fail-closed* L3, ditambah tautan serial 8b/10b Tier B.
- Bukti simulasi terukur: 128 dari 128 *bit flip* ditolak, nol *false reject* dari 20 *frame* bersih, latensi ujung ke ujung 108 siklus, dan *loopback* tautan yang menolak forgery, replay, serta *line error*.
- Bukti formal sembilan job lulus pada pohon saat ini, memisahkan inti, Tier B, dan lampiran RF.
- Sintesis FPGA DE10-Nano terukur untuk pembungkus *loopback* Tier B: 421 ALM, 1029 *flip-flop*, Fmax 97,9 MHz, 426,2 mW.
- Proposal kini muat enam halaman untuk bagian inti dan angkanya konsisten dengan bukti.
- Lampiran RF diposisikan jujur sebagai bukti kelas kerentanan, bukan jalur integritas yang diklaim selesai.

Keterbatasan dan risiko:

- Hasil tautan serial masih simulasi; pengukuran on-board menunggu *bootcamp*.
- Daya FPGA masih estimasi *vector-less*.
- Tier C dan CDC belum dibangun, sehingga klaim CDC belum diajukan.
- Manajemen kunci, *counter* lintas siklus daya, dan ketahanan kanal samping berada di luar cakupan.
- Sebagian bukti formal masih mencakup lampiran RF, bukan modul inti, dan ini disampaikan apa adanya.

## Pertanyaan Kritis dan Jawaban

| Pertanyaan | Jawaban singkat | Bukti |
| --- | --- | --- |
| Mengapa SIMON dan bukan Ascon | Datapath kecil yang dapat diserialkan muat di *tile* 2x2; antarmuka blok dapat diganti ke SIMON-64/128 atau Ascon dengan area lebih besar | `docs/design/trade-study.md`, proposal bagian 3.2 |
| Batas forgery dan *birthday* | Sekitar 2 pangkat -32 per percobaan; rotasi kunci di bawah batas *birthday* blok 32 bit | proposal bagian 3.2, Lampiran G |
| Bagaimana kunci ditangani | Dimuat sekali dari jalur *host* terpercaya, terkunci sampai reset, tidak melewati tautan | `src/l1_serial_loader.v`, Lampiran H |
| Apakah RTL dapat disintesis dan bersih | Pemeriksaan sintesis Yosys dan lint Verilator berjalan di CI | `make lint`, `make synth-check` |
| Apakah bukti formal nyata | Sembilan job lulus; lima inti, satu Tier B, tiga lampiran RF | `synth/formal/`, `README.md` |
| Bagaimana angka ASIC | Signoff saat ini: inti 2511 sel, 2,10 mW; tautan 3220 sel, 3,61 mW, 2 pelanggaran antena | `synth/area.md` |
| Bagaimana integrasi ke produk Peruri | Inti duduk di belakang *front-end* serial dan hanya mengomit *frame* terverifikasi; *host* menyediakan kunci dan kebijakan *counter* | proposal bagian 3.1 dan 3.2 |
| Bagaimana dengan *field* integritas RF | Tidak terdokumentasi dan belum dipecahkan, tetap sebagai bukti masalah | `sim/RESULTS.md`, `tools/README.md` |

## Verdict

Panel menilai proposal siap melaju.
Rata-rata 85,5 menempatkan proposal pada jalur kuat untuk seleksi, dengan catatan berikut:

1. Siapkan demonstrasi on-board dan *bitstream* pada *bootcamp* untuk melengkapi bukti *end-to-end*.
2. Ukur daya FPGA secara nyata untuk menggantikan estimasi *vector-less*.
3. Siapkan narasi integrasi ke identitas Peruri dan format *frame* yang dapat dipetakan ke tumpukan identitas.

Tanpa perbaikan tersebut, skor tertahan pada kisaran pertengahan delapan puluhan.

## Catatan dan Batasan

Rubrik dan bobot bersifat asumsi, bukan ketentuan resmi.
Identitas dan prioritas J1 dan J2 adalah inferensi dari profil publik, bukan konfirmasi.
Skor bersifat perkiraan internal dan tidak menggantikan penilaian resmi penyelenggara.
