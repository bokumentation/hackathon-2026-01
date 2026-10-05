# Sepuluh Pertanyaan Tersulit dan Jawaban Model

Persiapan penjurian untuk proposal.
Jawaban harus singkat, jujur, dan mengacu ke bukti yang ada.

## 1. Berapa peluang forgery, dan mengapa tag 32 bit?

Peluang forgery untuk satu percobaan adalah 2^-32, sekitar 2,3 x 10^-10.
Pada laju sekitar 460 ribu frame per detik, penyerang daring memerlukan sekitar 2,6 jam untuk satu tebakan yang diharapkan berhasil.
Angka ini memadai untuk prototipe dan hemat area.
Untuk identitas atau pembayaran bervolume tinggi, lebar tag dapat dinaikkan ke 48 atau 64 bit dengan tambahan satu blok MAC dan sekitar 33 sampai 66 siklus latensi.

## 2. Bagaimana Anda mencegah replay lintas siklus daya atau antar perangkat klon?

Counter kesegaran memaksa counter berikutnya lebih besar dari yang terakhir diterima, sehingga replay frame lama ditolak selama sesi.
Replay lintas siklus daya memerlukan state non-volatil dan dinyatakan di luar cakupan.
Pencegahan perangkat klon bergantung pada provisi kunci, yang juga di luar cakupan dan dinyatakan terbuka.

## 3. Dari mana kunci berasal dan bagaimana dilindungi?

Kunci dimuat ke register oleh host sebelum operasi, tanpa kunci keras di RTL.
Provisi dan penyimpanan kunci yang aman berada di luar cakupan; yang ditunjukkan adalah mekanisme verifikasi MAC berkunci dan penolakan kunci salah.

## 4. Mengapa SIMON, bukan AES, ASCON, atau PRESENT?

SIMON-32/64 sangat kecil dan cocok untuk perangkat hemat area serta target Tiny Tapeout.
Ronde diserialisasi satu ronde per siklus, sehingga area rendah dengan latensi terukur.
Alternatif seperti AES lebih besar; ASCON dan PRESENT juga layak, tetapi SIMON dipilih karena ukuran dan ketersediaan referensi.

## 5. Berapa latensi ujung ke ujung dan throughput, dan apakah memenuhi anggaran tautan?

Latensi terukur adalah 108 siklus dari awal frame ke host_full: 107 siklus untuk MAC dan kesegaran, ditambah satu siklus commit.
Pada 50 MHz, ini sekitar 2,16 mikrodetik per frame, atau sekitar 460 ribu frame per detik.
Angka per tahap tersedia dan dapat dibandingkan dengan anggaran tautan.

## 6. Bagaimana Anda melintasi dua domain clock dan bagaimana Anda tahu itu aman?

Tier A berjalan pada satu clock; lintas domain adalah Tier C dengan FIFO CDC yang dipakai apa adanya dan bersertifikat lewat pengujian dan, bila perlu, pembuktian formal.
Klaim lintas domain belum dibuat sampai Tier C dibangun.

## 7. Apa yang terjadi bila penyerang melakukan jamming atau memaksa fault terus-menerus?

Setiap kegagalan menahan host_full dan menaikkan fault lengket.
Serangan denial of service dapat menahan frame yang sah; kebijakan pembatasan laju fault adalah pengembangan lanjutan yang layak.
Desain tetap aman karena fail-closed, meski ketersediaan dapat terganggu.

## 8. Tunjukkan frame nyata di perangkat nyata yang ditolak.

Jalur RF pada lampiran menunjukkan baseline menerima payload korup (CWE-354), dan batas autentikasi menolak frame serupa dalam simulasi.
Demo perangkat nyata untuk tautan baru menyusul pada Tier B dengan DE10-Nano dan logic analyzer.

## 9. Berapa area dan timing yang sebenarnya, bukan proksi?

Lampiran RF memiliki hasil sky130 nyata: tile 1x2, 0,0363 mm persegi, WNS 0,00, daya tipikal 1,21 mW.
Untuk tautan baru, area masih estimasi Yosys (1280 sel, 500 flip-flop); hasil OpenLane dan Quartus menyusul.

## 10. Apa yang membuat ini Area 04 Secure Communication, bukan Area 02 kriptografi?

Fokusnya adalah batas ingress pada tautan serial/RF: framing, integritas antarmuka, dan commit atomik, bukan akselerator kriptografi.
MAC dan counter adalah sarana untuk mengamankan komunikasi, dan tautan serial serta CDC adalah target pada Tier B dan Tier C.

## Catatan batas yang harus disebutkan

- Tidak ada bukti kriptografis penuh; ini prototipe dengan bukti terukur.
- Tidak ada provisi kunci, ketahanan replay lintas siklus daya, atau ketahanan kanal samping.
- Tidak ada hasil tautan serial atau CDC sampai Tier B dan Tier C dibangun.
- Tidak ada angka area atau timing nyata untuk tautan baru sampai sintesis dijalankan.
