# Ide-01: TRI-ARGA-SERDES

Secure Framed Serial Link dengan Teknik TRI-ARGA

*Baseline*: `TT_UM_SERDES` (`tt_um_serdes`)
Area Fokus: 04 - Secure Communication (secure framing, protocol security)
Status: ide turunan yang memakai ulang teknik TRI-ARGA
Skor simulasi juri: 82.6 dari 100

## 1. Ringkasan Ide

Masalah yang diangkat adalah tautan serial pada terminal aman sering mengirim byte tanpa framing dan tanpa integritas.
*Baseline* SerDes hanya mengubah data paralel ke serial memakai 8b/10b sederhana, tanpa batas *frame*, tanpa penyelarasan, dan tanpa nilai integritas.
Akibatnya penerima tidak dapat memastikan batas data, tidak dapat mendeteksi kode 10b yang tidak sah, dan tidak dapat menolak *frame* yang berubah.
Solusi yang ditawarkan adalah TRI-ARGA-SERDES, yaitu *boundary* yang memakai teknik TRI-ARGA pada tautan serial.

Chip yang dirancang menambahkan tiga hal pada *baseline*: framing dengan penanda awal *frame*, penyelarasan word dengan status lock, dan integritas MAC atau CRC, ditambah *commit* *fail-closed*.
Target pengguna adalah perancang terminal pembaca identitas, *smart card*, dan perangkat pembayaran yang memakai tautan serial internal atau eksternal.
Dampaknya adalah tautan serial yang menolak *frame* yang tidak sah dan memberi sinyal *fault* yang terukur.

## 2. Baseline: tt_um_serdes

Yang tersedia pada *baseline*:
- *Encoder* 8b/10b berbasis tabel dan *decoder* 10b/8b berbasis tabel.
- PISO 10 bit pada sisi kirim dan SIPO 10 bit pada sisi terima.
- *Latch* 8 bit dan 10 bit yang dikendalikan `data_en`.
- *Serializer* dan *deserializer* berada pada satu chip, sehingga *loopback* on-chip memungkinkan.

Yang kurang pada *baseline*:
- Tidak ada pengaturan *running disparity*, sehingga pengkodean bukan 8b/10b penuh.
- Tidak ada *K-code* atau penanda koma, sehingga tidak ada penyelarasan word.
- Tidak ada batas *frame* dan tidak ada nilai integritas.
- *Decoder* memakai cabang default yang memetakan kode 10b tidak dikenal menjadi nol, sehingga error tidak dilaporkan.
- Tidak ada sinyal lock, tidak ada penghitung error, dan tidak ada mekanisme *fail-closed*.

## 3. Penerapan Teknik TRI-ARGA

| Lapisan | Implementasi pada TRI-ARGA-SERDES |
| --- | --- |
| L1 | Deteksi penanda awal frame, penyelarasan berbasis K-code, status lock, timeout, dan recovery |
| L2 | Hitung dan periksa MAC atau CRC atas frame secara streaming memakai LFSR atau blok MAC |
| L3 | Gerbang valid dan latch data secara atomik, fail-closed, fault lengket ke host |

Karena *serializer* dan *deserializer* berada pada satu chip, pengujian integritas *end-to-end* dapat dilakukan dengan *loopback* internal.

## 4. Integritas: CRC atau MAC

CRC adalah nilai pemeriksa linear tanpa kunci yang murah di *hardware* dan baik untuk mendeteksi error acak.
MAC adalah nilai pemeriksa berkunci yang bersifat kriptografis dan tahan terhadap pemalsuan oleh penyerang.
Untuk terminal identitas dan pembayaran, model ancaman mencakup penyerang aktif, sehingga MAC lebih tepat.
Rekomendasi adalah MAC sebagai opsi utama dan CRC sebagai opsi ringan, dengan catatan biaya area dan kebutuhan manajemen kunci.

## 5. Perbandingan dengan TRI-ARGA

| Aspek | TRI-ARGA (tt07-bep-decode) | TRI-ARGA-SERDES |
| --- | --- | --- |
| Baseline | Decoder Manchester thermostat | SerDes 8b/10b |
| Sumber integritas | Field CRC sudah ada, tinggal diverifikasi | Belum ada, harus dibangun |
| Keamanan terhadap penyerang aktif | Lemah, CRC dapat dihitung ulang | Kuat bila memakai MAC |
| Framing | Sudah ada dari protokol Manchester | Harus ditambahkan |
| Relevansi Peruri | Rendah, berbasis thermostat | Tinggi, tautan serial terminal |
| Portabilitas teknik | Acuan | Teknik L1/L2/L3 dipakai ulang |
| Kematangan pengujian | Data capture nyata tersedia | Perlu testbench baru |

Plus dari ide ini:
- Relevan langsung dengan kebutuhan komunikasi aman Peruri.
- Memperbaiki kelemahan utama TRI-ARGA, yaitu CRC bukan kontrol kriptografis.
- Framing dan penanganan error adalah kontribusi nyata, bukan sekadar verifikasi.

Minus dari ide ini:
- Harus membangun integritas dan framing dari nol.
- Area lebih besar daripada sekadar memverifikasi field yang ada.
- Tidak ada data capture nyata, sehingga verifikasi bergantung pada *testbench* yang dibuat sendiri.

## 6. Kelayakan dan Possibility to Create

Kelayakan teknis: tinggi, karena *baseline* sudah menyediakan *encoder*, *decoder*, dan *loopback*.
Estimasi area: 1x1 sampai 1x2 *tile*, tergantung pilihan MAC atau CRC dan kedalaman *buffer*.
Alat yang dipakai sama dengan TRI-ARGA: Verilog, cocotb, Verilator, Yosys, OpenLane, dan Quartus.
Waktu: pemulihan parameter dan integrasi dapat diselesaikan pada Hari 1 dan Hari 2 *bootcamp*.
Risiko utama: implementasi MAC ringan menambah area dan membutuhkan manajemen kunci sederhana.

## 7. Simulasi Penjurian

| Kriteria | Bobot | Skor |
| --- | --- | --- |
| Relevansi Masalah | 15 | 88 |
| Kebaruan dan Keunggulan | 15 | 78 |
| Kualitas Teknis dan Arsitektur | 20 | 82 |
| Keamanan dan Threat Model | 20 | 85 |
| Kelayakan dan Verifikasi | 15 | 76 |
| Dampak dan Hilirisasi | 10 | 85 |
| Kepatuhan dan Kejelasan | 5 | 88 |
| Total tertimbang | 100 | 82.6 |

Pertanyaan kritis yang akan diajukan:
1. Jenis MAC apa yang dipakai dan bagaimana kunci dikelola pada chip sekecil ini?
2. Bagaimana penyelarasan word dijamin tanpa *K-code* penuh?
3. Berapa area tambahan dan apakah masih muat 1x1 *tile*?
4. Bagaimana membuktikan deteksi terhadap pemalsuan, bukan hanya error acak?

*Verdict*: ide paling kuat untuk Area 04 dan paling relevan bagi Peruri.

## 8. Rekomendasi

- Mulai dari CRC untuk prototipe, lalu tingkatkan ke MAC bila area memungkinkan.
- Tambahkan status lock dan penghitung error sebagai observabilitas.
- Siapkan *loopback* on-chip untuk verifikasi *end-to-end*.

## 9. Glosarium

- 8b/10b: pengkodean 8 bit menjadi 10 bit untuk keseimbangan DC dan deteksi error.
- *Frame*: satuan data dengan batas awal dan akhir yang jelas.
- *K-code*: kode kontrol khusus pada 8b/10b.
- MAC: nilai pemeriksa berkunci yang tahan pemalsuan.
- CRC: nilai pemeriksa linear tanpa kunci.
- *Loopback*: pengujian dengan mengembalikan keluaran ke masukan pada chip yang sama.
- *Word lock*: status saat penerima berada pada batas word yang benar.

## 10. Pertanyaan Terbuka

- Jenis MAC ringan apa yang paling hemat area untuk 1 *tile*?
- Apakah kunci dapat ditanam pada chip atau dikirim *host* saat runtime?
