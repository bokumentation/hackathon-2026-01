# Ikhtisar Ide TRI-ARGA untuk Area 04 Secure Communication

Dokumen: kumpulan ide turunan berbasis teknik TRI-ARGA
Area Fokus: 04 - Secure Communication
*Baseline* resmi: `tt07-bep-decode`, `tt07_cdc_fifo`, `TT_UM_SERDES`
Konteks: PERURI Chip Hackathon 2026
Tanggal: 4 Oktober 2026

## Ringkasan

Dokumen ini mengumpulkan beberapa ide desain yang semuanya memakai satu teknik yang sama, yaitu *boundary* verifikasi integritas TRI-ARGA.
Perbedaannya terletak pada *baseline* yang dipakai dan jenis integritas yang dibangun.
Ide-01 sampai Ide-05 menggunakan *baseline* SerDes dan CDC FIFO yang disebut pada laman resmi Area 04, sehingga lebih dekat dengan kebutuhan Peruri pada komunikasi aman untuk identitas dan pembayaran.
Ide-00 adalah dokumen ini yang berisi ikhtisar, perbandingan, primer CRC dan MAC, serta glosarium.

## Dari TRI-ARGA ke ide turunan

TRI-ARGA memperkenalkan tiga lapis *boundary* yang bersifat generik.
Lapisan pertama memvalidasi framing dan legalitas mesin status.
Lapisan kedua menghitung dan memeriksa integritas secara *streaming*.
Lapisan ketiga melakukan *commit* atomik yang *fail-closed* dan menaikkan *fault* yang lengket.
Teknik ini tidak terikat pada Manchester.
Pada *baseline* yang tidak memiliki field integritas, lapisan kedua berubah peran dari sekadar memeriksa menjadi membangun dan memeriksa integritas.
Dengan cara itu, teknik TRI-ARGA dapat dipakai ulang pada SerDes maupun CDC FIFO.

## Primer: Integritas, CRC, dan MAC

### Mengapa integritas penting

Data yang berpindah pada jalur komunikasi dapat berubah karena noise, jitter, atau gangguan fisik.
Tanpa pemeriksaan, data yang rusak dapat diterima sebagai data yang sah.
Kontrol integritas bertugas mendeteksi perubahan tersebut sebelum data dipakai.

### CRC (Cyclic Redundancy Check)

CRC adalah nilai pemeriksa yang dihitung dengan pembagian polinomial atas medan GF(2).
CRC bekerja sangat baik untuk mendeteksi error acak dan error beruntun, serta murah di *hardware* karena hanya memakai register geser dan gerbang XOR (LFSR).
CRC bersifat linear dan tanpa kunci.
Karena tanpa kunci, CRC dapat dihitung ulang oleh siapa pun.
Akibatnya CRC mendeteksi kerusakan tidak sengaja, tetapi tidak melindungi dari penyerang aktif yang sengaja mengubah data lalu menghitung ulang CRC.
Contoh pemakaian CRC adalah Ethernet, USB, penyimpanan data, dan banyak protokol *frame*.
Contoh umum adalah CRC-24 dengan polinomial seperti 0x864CFB (OPENPGP) atau 0x5D6DCB (FLEXRAY).

### MAC (Message Authentication Code)

MAC adalah nilai pemeriksa yang dihitung memakai kunci rahasia.
MAC bersifat kriptografis, sehingga pihak tanpa kunci tidak dapat memalsukan nilai yang valid.
Contoh MAC adalah HMAC yang berbasis fungsi *hash*, dan CMAC yang berbasis block *cipher*.
MAC dipakai pada secure messaging seperti ISO/IEC 7816 dan pada protokol aman seperti TLS.
Harganya adalah kebutuhan manajemen kunci dan logika tambahan, sehingga lebih mahal daripada CRC.

### Perbandingan CRC dan MAC

| Aspek | CRC | MAC |
| --- | --- | --- |
| Kunci rahasia | Tidak perlu | Perlu |
| Deteksi error acak | Sangat baik | Baik |
| Ketahanan terhadap penyerang aktif | Tidak | Ya |
| Sifat matematis | Linear | Non-linear (kriptografis) |
| Biaya hardware | Rendah (LFSR) | Sedang sampai tinggi |
| Manajemen kunci | Tidak ada | Perlu |
| Contoh pemakaian | Ethernet, USB, storage | ISO 7816 secure messaging, TLS |

### Kapan memakai yang mana

Pakai CRC bila tujuan utama adalah mendeteksi kerusakan acak pada lapis transport, dengan biaya sekecil mungkin.
Pakai MAC bila model ancaman mencakup penyerang aktif yang dapat menyuntik atau memodifikasi *frame*.
Untuk konteks Peruri pada identitas dan pembayaran, MAC lebih tepat karena melindungi dari pemalsuan, sedangkan CRC hanya memperbaiki kualitas data.

## Teknik TRI-ARGA

| Lapisan | Fungsi | Peran saat baseline tidak punya integritas |
| --- | --- | --- |
| L1 | Validasi framing dan legalitas FSM, timeout, recovery | Menambah framing, alignment, atau pengecekan status handshake |
| L2 | Periksa integritas secara streaming | Membangun sekaligus memeriksa CRC atau MAC |
| L3 | Commit atomik, fail-closed, fault lengket | Menahan commit saat integritas gagal |

## Daftar Ide

| Ide | Judul | Baseline | Irisan Area 04 | Integritas | Area | Kesulitan | Skor Juri |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 01 | TRI-ARGA-SERDES | TT_UM_SERDES | secure framing, protocol security | MAC (fallback CRC) | 1x1 sampai 1x2 | Sedang | 82.6 |
| 02 | TRI-ARGA-CDC | tt07_cdc_fifo | CDC, interface integrity | parity atau ECC | 1x1 sampai 1x2 | Sedang-tinggi | 78.75 |
| 03 | TRI-ARGA-BRIDGE | SerDes + CDC FIFO | end-to-end secure ingress | MAC + ECC | 1x2 | Tinggi | 82.6 |
| 04 | LINK-GUARD | TT_UM_SERDES | protocol security, anti-tamper | CRC atau disparitas | 1x1 | Sedang | 78.4 |
| 05 | DISPARITY-GUARD | TT_UM_SERDES | secure framing, PHY hardening | CRC | 1x1 | Sedang | 77.0 |
| - | TRI-ARGA (acuan) | tt07-bep-decode | secure framing, interface integrity | CRC (verifikasi) | 1x1 | Sedang | 76.05 |

## Glosarium

- *Alignment*: proses menyelaraskan batas word pada aliran serial.
- *Baseline*: desain dasar yang disediakan penyelenggara untuk dikembangkan.
- CDC (*Clock Domain Crossing*): perpindahan data antara dua domain *clock* berbeda.
- *Checksum*: nilai ringkas untuk mendeteksi perubahan data.
- *Commit*: tindakan menetapkan data dan kendali sebagai sah dan siap dipakai.
- CRC (*Cyclic Redundancy Check*): nilai pemeriksa linear tanpa kunci untuk mendeteksi error.
- *Disparity*: selisih jumlah bit satu dan nol pada kode serial, dipakai pada 8b/10b.
- ECC (*Error Correcting Code*): kode yang dapat mendeteksi dan memperbaiki error.
- *Fail-closed*: kegagalan verifikasi menahan data, bukan meloloskannya.
- *Fault*: penanda kegagalan verifikasi yang dapat dilihat *host*.
- FIFO (*First In First Out*): *buffer* antrean data.
- FSM (*Finite State Machine*): mesin status pengendali.
- *Gray code*: pengkodean yang hanya mengubah satu bit antar nilai berurutan, aman untuk CDC.
- LFSR (Linear Feedback Shift Register): register geser umpan balik linear, mesin CRC.
- MAC (*Message Authentication Code*): nilai pemeriksa berkunci yang tahan pemalsuan.
- *Parity*: bit pemeriksa sederhana dari jumlah bit satu.
- SerDes (*Serializer*/*Deserializer*): konverter data paralel ke serial dan sebaliknya.
- *Sticky*: sifat penanda yang bertahan sampai dihapus secara eksplisit.
- *Word lock*: status saat penerima yakin berada pada batas word yang benar.

## Cara memilih ide

Ide-01 paling tepat bila fokus pada komunikasi serial aman untuk terminal identitas dan pembayaran.
Ide-02 paling tepat bila fokus pada integritas lintas domain *clock* pada SoC.
Ide-03 paling lengkap tetapi paling besar area.
Ide-04 dan Ide-05 bersifat pelengkap untuk pemantauan dan penguatan lapis fisik.

## Referensi

- Laman resmi Tiny Tapeout 07 untuk `tt_um_serdes` dan `tt_um_pa1mantri_cdc_fifo`.
- Repository `Santeep/TT_UM_SERDES` dan `Pa1mantri/tt07_cdc_fifo`.
- *Proposal* TRI-ARGA, `docs/proposal/proposal.id.md`.
- Simulasi penjurian, `docs/judging/simulasi-penjurian.id.md`.
