# Anggaran Keamanan dan Perbandingan Integritas

Lampiran pendukung penjurian untuk proposal.
Dokumen ini menjelaskan mengapa dipilih MAC berkunci ditambah counter, dan bagaimana lebar tag memengaruhi keamanan, area, dan latensi.

## Anggaran keamanan tag

MAC pada desain ini memakai SIMON-32/64 dengan CBC-MAC panjang tetap.
Peluang forgery untuk satu percobaan adalah 2^-t dengan t adalah lebar tag.
Pada laju sekitar 460 ribu frame per detik (108 siklus per frame pada 50 MHz), waktu yang dibutuhkan penyerang daring untuk menebak tag adalah 2^t dibagi laju tersebut.

| Lebar tag | Peluang per percobaan | Perkiraan waktu pada 460 rb frame/detik | Area | Tambahan latensi |
| --- | --- | --- | --- | --- |
| 32 bit (dipakai) | 2^-32 sekitar 2,3 x 10^-10 | sekitar 2,6 jam | dasar 1280 sel | dasar 108 siklus |
| 48 bit | 3,6 x 10^-15 | sekitar 19 tahun | tambah satu blok MAC | sekitar 33 siklus |
| 64 bit | 5,4 x 10^-20 | sekitar 1,3 juta tahun | tambah satu sampai dua blok, atau cipher berblok 64 bit | sekitar 33 sampai 66 siklus |

Catatan: angka waktu adalah perhitungan dari laju frame, bukan hasil pengukuran serangan.
Tag 32 bit bersifat memadai untuk prototipe dan hemat area, tetapi untuk identitas atau pembayaran bervolume tinggi, tag 64 bit layak dipertimbangkan.
Perluasan ke 64 bit adalah penambahan satu blok dan tercermin pada anggaran area serta latensi di atas.

## Perbandingan CRC, MAC, dan MAC ditambah counter

| Aspek | CRC tanpa kunci | MAC berkunci | MAC ditambah counter (dipakai) |
| --- | --- | --- | --- |
| Deteksi error acak | ya | ya | ya |
| Ketahanan forgery (CWE-345) | tidak, linear dan dapat dihitung ulang | ya | ya |
| Ketahanan replay (CWE-294) | tidak | tidak | ya, counter harus lebih besar |
| Kebutuhan kunci | tidak | ya | ya |
| State tambahan | tidak | tidak | counter 32 bit |
| Latensi (terukur) | 73 siklus untuk LFSR streaming 72 bit | sekitar 107 siklus | 107 siklus, ujung ke ujung 108 siklus |
| Area | kecil (LFSR 24 bit) | menambah SIMON | menambah SIMON dan counter |

Ringkasan: CRC mendeteksi error tetapi tidak menahan penyerang aktif; MAC menahan forgery tetapi masih dapat diulang; hanya MAC ditambah counter yang menutup forgery dan replay sekaligus.
Karena itu desain ini memilih MAC ditambah counter, dengan commit atomik fail-closed sebagai lapis ketiga.

## Justifikasi pilihan

- MAC berkunci dipilih karena ancaman utama pada batas ingress adalah penyerang aktif yang dapat menghitung ulang checksum tanpa kunci.
- Counter dipilih karena replay adalah serangan nyata pada tautan tersimpan dan diputar ulang.
- Fail-closed dipilih karena kegagalan verifikasi harus menahan data, bukan meloloskannya.
- SIMON-32/64 dipilih karena kecil dan cocok untuk perangkat hemat area, dengan ronde terserialisasi satu ronde per siklus.

## Catatan batas

- Tidak ada bukti kriptografis penuh; ini prototipe dengan peluang forgery terukur sekitar 2^-32 untuk tag 32 bit.
- Tidak ada provisi kunci, ketahanan replay lintas siklus daya, atau ketahanan kanal samping (di luar cakupan).
- Angka area dan latensi tag 48 dan 64 bit adalah estimasi, bukan hasil sintesis.
