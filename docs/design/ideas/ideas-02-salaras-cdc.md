# Ide-02: SALARAS-CDC

Trusted *Clock Domain Crossing* Datapath dengan Teknik SALARAS-RX

*Baseline*: `tt07_cdc_fifo` (`tt_um_pa1mantri_cdc_fifo`)
Area Fokus: 04 - Secure Communication (CDC, interface integrity)
Status: ide turunan yang memakai ulang teknik SALARAS-RX
Skor simulasi juri: 78.75 dari 100

## 1. Ringkasan Ide

Masalah yang diangkat adalah perpindahan data antar domain *clock* rawan terhadap korupsi dan meta-stability, dan *baseline* tidak memeriksa integritas data.
*Baseline* CDC FIFO memindahkan data 4 bit antar dua *clock* memakai pointer *gray code*, *dual-port RAM*, dan sinkronizer dua *flip-flop*, tetapi isi memori tidak diperiksa.
Solusi yang ditawarkan adalah SALARAS-CDC, yaitu *boundary* integritas dengan teknik SALARAS-RX yang menambahkan *parity* atau ECC pada *payload* dan pointer, pengecekan konsistensi status, serta *commit* *fail-closed*.

Chip yang dirancang menambahkan pengecekan integritas per word, pengecekan *parity* pada pointer gray, deteksi inkonsistensi empty dan full, dan *fault* lengket yang disinkronkan ke domain baca.
Target pengguna adalah perancang SoC aman yang memindahkan data identitas atau transaksi antara HPS dan FPGA, atau antar subsistem berclock berbeda.
Dampaknya adalah datapath CDC yang menolak data rusak dan memberi sinyal error yang dapat diandalkan.

## 2. Baseline: tt07_cdc_fifo

Yang tersedia pada *baseline*:
- FIFO asinkron dengan parameter lebar data dan lebar alamat.
- Pointer *gray code* dengan konversi biner ke gray dan sebaliknya.
- Sinkronizer dua *flip-flop* untuk melintasi domain *clock*.
- *Dual-port RAM* untuk penyimpanan, serta status `full` dan `empty`.

Yang kurang pada *baseline*:
- Tidak ada *parity* atau ECC pada *payload* di RAM, sehingga data rusak tidak terdeteksi.
- Tidak ada *parity* pada pointer gray, sehingga korupsi pointer sulit dideteksi.
- Tidak ada pengecekan konsistensi antara `full` dan `empty`.
- Tidak ada mekanisme *fail-closed* atau sinyal *fault*.
- Tidak ada pengujian integritas, hanya pengujian fungsional FIFO.

## 3. Penerapan Teknik SALARAS-RX

| Lapisan | Implementasi pada SALARAS-CDC |
| --- | --- |
| L1 | Cek konsistensi status handshake, cek keabsahan pointer, timeout, recovery |
| L2 | Parity atau ECC pada payload dan parity pada pointer gray, diperiksa per word |
| L3 | Gerbang valid data baca secara atomik, flush saat error, fault disinkronkan ke domain baca |

Perbedaan penting: karena ada dua *clock*, *commit* atomik dan sinyal *fault* harus aman secara CDC.

## 4. Integritas: Parity, ECC, CRC, dan MAC

*Parity* adalah bit pemeriksa paling murah, baik untuk mendeteksi satu bit error.
ECC dapat mendeteksi dan memperbaiki error, dengan biaya lebih tinggi.
CRC bersifat linear tanpa kunci, cocok untuk mendeteksi error beruntun pada blok data.
MAC bersifat berkunci dan melindungi dari pemalsuan, tetapi lebih mahal dan membutuhkan kunci.
Untuk datapath internal seperti FIFO, *parity* atau ECC lebih lazim, sedangkan MAC lebih relevan bila data melewati batas kepercayaan antar perangkat.

## 5. Perbandingan dengan SALARAS-RX

| Aspek | SALARAS-RX (tt07-bep-decode) | SALARAS-CDC |
| --- | --- | --- |
| Domain clock | Tunggal | Dua domain, perlu CDC aman |
| Sumber integritas | Field CRC sudah ada | Belum ada, ditambah parity atau ECC |
| Fokus | Integritas frame RF | Integritas lintas domain clock |
| Relevansi Peruri | Rendah, thermostat | Tinggi, datapath SoC identitas dan transaksi |
| Kompleksitas | Sedang | Sedang sampai tinggi karena CDC |
| Verifikasi | Capture nyata tersedia | Testbench dua clock perlu disusun |

Plus dari ide ini:
- Menyentuh langsung CDC dan interface integrity yang disebut Area 04.
- Sesuai dengan pemakaian HPS dan FPGA pada DE10-Nano.
- Menambahkan deteksi yang selama ini tidak ada pada *baseline*.

Minus dari ide ini:
- Multi-*clock* menambah kompleksitas verifikasi dan sinkronisasi.
- Integritas harus dibangun dari nol.
- Model ancaman *adversarial* tetap terbatas bila hanya memakai *parity* atau CRC.

## 6. Kelayakan dan Possibility to Create

Kelayakan teknis: tinggi sampai sedang, karena struktur FIFO sudah rapi dan modular.
Estimasi area: 1x1 sampai 1x2 *tile*, tergantung pilihan *parity*, ECC, atau CRC.
Alat sama dengan SALARAS-RX, ditambah *testbench* dua *clock* pada cocotb.
Waktu: dapat diselesaikan pada *bootcamp* dengan fokus pada pengecekan integritas dan gangguan CDC.
Risiko utama: kebenaran lintas domain *clock* dan kemungkinan false alarm bila sinkronisasi tidak rapi.

## 7. Simulasi Penjurian

| Kriteria | Bobot | Skor |
| --- | --- | --- |
| Relevansi Masalah | 15 | 84 |
| Kebaruan dan Keunggulan | 15 | 75 |
| Kualitas Teknis dan Arsitektur | 20 | 80 |
| Keamanan dan Threat Model | 20 | 78 |
| Kelayakan dan Verifikasi | 15 | 72 |
| Dampak dan Hilirisasi | 10 | 82 |
| Kepatuhan dan Kejelasan | 5 | 86 |
| Total tertimbang | 100 | 78.75 |

Pertanyaan kritis yang akan diajukan:
1. Bagaimana membuktikan tidak ada meta-stability pada jalur sinkronisasi baru?
2. Apakah *parity* cukup, atau perlu ECC untuk data identitas?
3. Bagaimana *fault* disinkronkan ke domain baca tanpa *glitch*?
4. Berapa *overhead* area dari pengecekan per word?

*Verdict*: ide kuat untuk irisan CDC, dengan catatan kompleksitas multi-*clock*.

## 8. Rekomendasi

- Gunakan *parity* terlebih dahulu, lalu pertimbangkan ECC bila area memungkinkan.
- Tambahkan penghitung error dan status kesehatan FIFO.
- Siapkan *testbench* dua *clock* dengan injeksi error terarah.

## 9. Glosarium

- CDC: perpindahan data antar domain *clock*.
- *Dual-port RAM*: memori dengan satu port tulis dan satu port baca.
- *Gray code*: pengkodean satu bit berubah, aman untuk lintas *clock*.
- Meta-stability: kondisi sinyal tidak stabil saat melintasi domain *clock*.
- *Parity*: bit pemeriksa jumlah bit satu.
- ECC: kode yang dapat memperbaiki error.
- Sinkronizer: rangkaian penstabil sinyal antar domain *clock*.

## 10. Pertanyaan Terbuka

- Apakah perlu proteksi khusus pada jalur pointer selain *parity*?
- Apakah model ancaman mencakup penyerang pada bus internal, atau hanya error acak?
