# Simulasi Penjurian: SALARAS-SERDES (CRC)

Dokumen: simulasi penjurian dan analisis kelemahan
Objek: `docs/proposal/salaras-serdes-crc-proposal.id.md`
*Baseline*: `TT_UM_SERDES` (`tt_um_serdes`)
Area Fokus: 04 - Secure Communication (secure *framing*, protocol security)
Tanggal: 4 Oktober 2026

## Ringkasan

SALARAS-SERDES memperoleh rata-rata *panel* 77,53 dari 100.
Proposal kuat pada relevansi, kelayakan, dan kepatuhan, tetapi lemah pada kebaruan dan pada keamanan berbasis CRC.
Dokumen ini menemukan satu kelemahan kritis, tiga kelemahan tinggi, dan beberapa kelemahan sedang yang harus diperbaiki sebelum *bootcamp*.

Kelemahan kritis utama: model ancaman menyebut penyerang aktif, padahal CRC tanpa kunci dapat dihitung ulang, sehingga klaim keamanan saat ini melebihi kemampuan mekanismenya (CWE-345).

## 1. Metodologi dan Rubrik

Simulasi melibatkan lima *persona* juri dengan latar berbeda.
Rubrik memakai tujuh kriteria dengan bobot berikut: Relevansi Masalah 15, Kebaruan dan Keunggulan 15, Kualitas Teknis dan Arsitektur 20, Keamanan dan *Threat Model* 20, Kelayakan Implementasi dan Verifikasi 15, Dampak dan Hilirisasi 10, serta Kepatuhan dan Kejelasan 5.
Skor tiap juri dihitung sebagai jumlah berbobot, lalu dirata-ratakan menjadi skor *panel*.

## 2. Panel Juri

Juri 1, pakar keamanan perangkat keras.
Fokus pada model ancaman, sifat CRC, dan klaim keamanan.

Juri 2, pakar RTL dan ASIC.
Fokus pada area, *timing*, dan kebenaran implementasi 8b/10b.

Juri 3, pakar sistem dan FPGA.
Fokus pada prototipe DE10-Nano, kecepatan, dan *loopback*.

Juri 4, juri produk dan hilirisasi.
Fokus pada relevansi Peruri, adopsi, dan pemisahan prototipe dan produk.

Juri 5, juri kompetisi dan kepatuhan.
Fokus pada struktur proposal, kelengkapan, dan aturan.

## 3. Rekapitulasi Skor

| Kriteria | Bobot | Keamanan | RTL/ASIC | Sistem/FPGA | Produk | Kompetisi |
| --- | --- | --- | --- | --- | --- | --- |
| Relevansi Masalah | 15 | 85 | 85 | 85 | 82 | 88 |
| Kebaruan dan Keunggulan | 15 | 70 | 72 | 72 | 68 | 75 |
| Kualitas Teknis dan Arsitektur | 20 | 78 | 84 | 82 | 75 | 82 |
| Keamanan dan Threat Model | 20 | 58 | 75 | 75 | 72 | 78 |
| Kelayakan dan Verifikasi | 15 | 72 | 80 | 80 | 76 | 82 |
| Dampak dan Hilirisasi | 10 | 75 | 75 | 76 | 84 | 78 |
| Kepatuhan dan Kejelasan | 5 | 85 | 86 | 86 | 82 | 86 |
| Total tertimbang | 100 | 73.0 | 79.15 | 78.85 | 75.8 | 80.85 |

Rata-rata *panel*: 77,53 dari 100.
Rata-rata per kriteria: Relevansi 85,0; Kebaruan 71,4; Teknis 80,2; Keamanan 71,6; Kelayakan 78,0; Dampak 77,6; Kepatuhan 85,0.

Kebaruan dan keamanan adalah dua kriteria dengan skor terendah, dan keduanya saling berkaitan.

## 4. Pertanyaan Kritis per Juri

Juri keamanan:
1. Apa yang terjadi bila penyerang mengubah *payload* lalu menghitung ulang CRC?
2. Mengapa memakai CRC, bukan MAC, pada data identitas dan pembayaran?
3. Apakah CRC-24 melindungi field CRC itu sendiri, atau hanya *payload*?

Juri RTL dan ASIC:
1. Bagaimana *K-code* dan penyelarasan dijamin benar tanpa *running disparity* penuh?
2. Berapa area hasil sintesis sebenarnya, dan apakah tetap 1x1 *tile*?
3. Apakah modifikasi *decoder* untuk kode tidak sah masih termasuk *boundary*, atau sudah menyentuh *baseline*?

Juri sistem dan FPGA:
1. *Baseline* berjalan pada *clock* 100 Hz; bagaimana ini merepresentasikan tautan serial nyata?
2. Apakah *loopback* on-chip menguji jitter, skew, dan kehilangan bit pada tautan nyata?
3. Bagaimana *latency* 1 sampai 3 siklus diukur dan dibuktikan?

Juri produk:
1. Apa nilai jual bila CRC adalah teknik standar yang sudah umum?
2. Apakah tanpa MAC, klaim keamanan untuk identitas dan pembayaran cukup?
3. Bagaimana jalur adopsi dari prototipe ke produk?

Juri kompetisi:
1. Apakah setiap klaim metrik punya test case yang dapat ditelusuri?
2. Apakah set *fault injection* didefinisikan secara eksplisit?
3. Apakah cakupan CWE dinyatakan jujur termasuk batas CWE-345?

## 5. Analisis Kelemahan

### 5.1 Kelemahan Kritis

K1. Model ancaman tidak selaras dengan mekanisme CRC.
Proposal menyatakan penyerang atau gangguan dapat mengubah bit, tetapi CRC tanpa kunci dapat dihitung ulang oleh penyerang, sehingga tidak melindungi dari pemalsuan (CWE-345).
Skor keamanan juri 1 turun menjadi 58 karena ketidaksesuaian ini.
Perbaikan P0: nyatakan ruang lingkup keamanan sebagai integritas terhadap error acak dan *fault injection*, bukan terhadap penyerang aktif, atau tambahkan MAC pada lingkup bila ingin mengklaim keamanan *adversarial*.

### 5.2 Kelemahan Tinggi

T1. Verifikasi tanpa *golden vector* independen.
Berbeda dari SALARAS-RX yang memakai data capture nyata, SerDes tidak memiliki vektor emas, sehingga verifikasi bergantung pada *testbench* yang dibuat sendiri dan berisiko menguji asumsi sendiri.
Perbaikan P0: buat vektor uji independen, bandingkan dengan tabel 8b/10b referensi, dan tambahkan simulasi *gate-level* setelah sintesis.

T2. Justifikasi metrik *detection* rate belum lengkap.
Target 99,9 persen benar sebagai angka konservatif, tetapi cakupan set *fault* harus didefinisikan: CRC-24 mendeteksi seluruh error satu bit dan *burst* sampai 24 bit, namun *insertion*, *deletion*, dan *timing* *fault* tidak dijamin.
Perbaikan P0: tetapkan set *fault* eksplisit dan sebutkan batas deteksi untuk tiap jenis.

T3. Kompleksitas *K-code*, penyelarasan, dan *running disparity*.
*Baseline* tidak memiliki *running disparity* dan *K-code*, padahal *framing* yang benar bergantung pada keduanya.
Bila implementasi tidak hati-hati, penyelarasan dapat salah dan justru menimbulkan *false lock*.
Perbaikan P1: definisikan *K-code* yang dipakai, sederhanakan penyelarasan awal, dan uji *false lock* secara khusus.

T4. Kecepatan dan realisme tautan.
*Baseline* berjalan pada *clock* 100 Hz, jauh dari tautan serial nyata, sehingga klaim tautan aman hanya berlaku pada level fungsional.
Perbaikan P1: nyatakan batas ini dan tambahkan analisis *worst-case* *timing* pada frekuensi target.

### 5.3 Kelemahan Sedang

S1. Estimasi area optimistis.
Klaim kurang dari 60 FF mengabaikan deteksi *K-code*, *framing* FSM, dan penghitung error yang bisa menambah puluhan FF.
Risiko pergeseran ke 1x2 *tile*.
Perbaikan P1: beri rentang area dan siapkan rencana *fallback* 1x2.

S2. *Overhead* dan *latency*.
*Frame* 120 bit dengan CRC 24 bit berarti *overhead* sekitar 20 persen, dan *latency* 1 sampai 3 siklus belum dibuktikan.
Perbaikan P1: sertakan perhitungan *overhead* dan *timeline* siklus *commit*.

S3. Polinomial dan *seed* CRC belum ditentukan.
Pemilihan CRC-24 belum menyebut polinomial, inisialisasi, dan urutan bit.
Perbaikan P1: tetapkan dan dokumentasikan parameter CRC.

S4. *Scope creep* pada *decoder*.
Menandai kode 10b tidak sah menyentuh *decoder* *baseline*, bukan hanya *boundary*.
Perbaikan P2: pisahkan perubahan *baseline* dan *boundary*, atau bungkus pada lapisan L1.

S5. Kebaruan terbatas.
CRC dan *framing* adalah teknik standar.
Nilai jual utama terletak pada *commit* atomik *fail-closed* dan portofolio CWE.
Perbaikan P2: tonjolkan kebaruan pada *boundary* dan *fail-closed*, bukan pada CRC itu sendiri.

### 5.4 Kelemahan Rendah

R1. Cakupan CWE belum sepenuhnya jujur pada satu sudut, yaitu CWE-345 hanya dicatat sebagai batas.
Perbaikan P2: beri pernyataan batas yang eksplisit di Ringkasan Ide.
R2. CWE-20 hanya menandai, tidak mencegah.
Perbaikan P2: jelaskan dampak penandaan pada *commit*.
R3. Belum ada metrik *throughput* dan area final.
Perbaikan P2: lengkapi setelah sintesis.

## 6. Kelemahan yang Paling Menentukan

Dua hal paling menentukan penilaian:
- Ketidaksesuaian antara model ancaman dan CRC (K1), yang menurunkan skor keamanan.
- Tidak adanya *golden vector* independen (T1), yang menurunkan keyakinan verifikasi.

Keduanya dapat dijawab tanpa mengubah arsitektur, yaitu dengan memperjelas ruang lingkup dan menyiapkan verifikasi yang dapat diaudit.

## 7. Rekomendasi Perbaikan

P0, wajib sebelum kurasi:
- Perjelas ruang lingkup keamanan: CRC untuk error dan *fault*, MAC untuk *adversarial* sebagai future work.
- Siapkan vektor uji independen dan rencana *gate-level* simulation.
- Definisikan set *fault injection* secara eksplisit beserta batas deteksinya.

P1, penting:
- Tetapkan *K-code* dan strategi penyelarasan beserta uji *false lock*.
- Beri rentang area dan rencana *fallback* 1x2.
- Dokumentasikan parameter CRC dan perhitungan *overhead* serta *latency*.
- Nyatakan batas kecepatan *clock* pada prototipe.

P2, nilai tambah:
- Tonjolkan kebaruan pada *fail-closed* *boundary* dan portofolio CWE.
- Pisahkan perubahan *baseline* dan *boundary* secara jelas.
- Lengkapi metrik *throughput* dan area setelah sintesis.

## 8. Verdict

Kualitas proposal berada pada kategori layak dengan skor 77,53 dari 100.
Proposal berpotensi melaju ke *bootcamp* bila tiga hal dikerjakan: memperjelas ruang lingkup keamanan, menyiapkan verifikasi yang dapat diaudit, dan menjustifikasi metrik secara eksplisit.
Tanpa perbaikan keamanan, risiko pertanyaan keras dari juri keamanan tetap tinggi, karena skor keamanan juri tersebut hanya 58.

## 9. Lampiran

### Lampiran A. Bobot Rubrik

| Kriteria | Bobot |
| --- | --- |
| Relevansi Masalah | 15 |
| Kebaruan dan Keunggulan | 15 |
| Kualitas Teknis dan Arsitektur | 20 |
| Keamanan dan Threat Model | 20 |
| Kelayakan dan Verifikasi | 15 |
| Dampak dan Hilirisasi | 10 |
| Kepatuhan dan Kejelasan | 5 |
| Total | 100 |

### Lampiran B. Ringkasan Kelemahan

| Kode | Kelemahan | Tingkat | Perbaikan |
| --- | --- | --- | --- |
| K1 | Model ancaman tidak selaras dengan CRC | Kritis | Perjelas lingkup atau tambah MAC |
| T1 | Tanpa golden vector independen | Tinggi | Vektor uji independen dan gate-level |
| T2 | Justifikasi detection rate belum lengkap | Tinggi | Definisikan set fault dan batas |
| T3 | K-code, alignment, dan disparity | Tinggi | Tetapkan K-code dan uji false lock |
| T4 | Kecepatan dan realisme tautan | Tinggi | Nyatakan batas dan analisis timing |
| S1 | Estimasi area optimistis | Sedang | Rentang area dan fallback 1x2 |
| S2 | Overhead dan latency | Sedang | Perhitungan overhead dan commit |
| S3 | Parameter CRC belum ditentukan | Sedang | Dokumentasikan polinomial dan seed |
| S4 | Scope creep pada decoder | Sedang | Pisahkan baseline dan boundary |
| S5 | Kebaruan terbatas | Sedang | Tonjolkan fail-closed boundary |
| R1 | Batas CWE-345 belum eksplisit | Rendah | Pernyataan batas di Ringkasan |
| R2 | CWE-20 hanya menandai | Rendah | Jelaskan dampak pada commit |
| R3 | Metrik throughput dan area | Rendah | Lengkapi setelah sintesis |
