# Analisis Prior-Art dan Positioning

Catatan positioning untuk klaim kebaruan proposal, berbasis penelusuran IP komersial dan literatur.
Referensi sumbernya ada di `../references/`.

**Kesimpulan: Klaim "belum ada blok hemat area yang menggabungkan autentikasi, kesegaran, dan commit atomik fail-closed tepat di batas ingress" pada dasarnya valid, tetapi rumusannya perlu dibuat lebih ketat.**

Berdasarkan hasil pencarian, memang belum ditemukan IP komersial yang persis memenuhi keempat kondisi tersebut sekaligus. Namun ada perlu diperhatikan: **KORD SCU** adalah kasus yang paling mendekati, meskipun ada perbedaan teknis yang signifikan dengan proposal Anda.

---

## Contoh Nyata yang Ada

**1. KORD SCU (Secure Channel Unit) - Paling Mendekati**

KORD adalah unit saluran aman dari penelitian akademik (arXiv, 2026), dengan tiga mekanisme yang diberlakukan pada batas ingress: antarmuka pesan tunggal, autentikasi fail-closed, dan jalur data khusus yang tidak mengeksekusi kode yang dimuat. SCU-nya mengimplementasikan AES-GCM per-pesan dan **fail-closed**: kegagalan autentikasi tidak menghasilkan dekripsi, tidak ada pengiriman fabric, dan tidak ada state engine yang dapat diamati. Perlindungan replay memerlukan pengirim untuk memelihara **counter monotonik**.

Tetapi KORD SCU adalah **AES-GCM level**, area jauh lebih besar dari SIMON32/64, dan merupakan komponen khusus sistem FSS, **bukan IP batas ingress yang dapat digunakan ulang secara umum**.

**2. CAST ASCON-F - Hanya Fungsi Tunggal**

CAST menyediakan IP Ascon AEAD + Hash, tetapi ini adalah **engine enkripsi terautentikasi dan hashing yang ringkas**, tidak termasuk manajemen nonce, perlindungan replay, atau mekanisme commit. Penelitian secara eksplisit menunjukkan bahwa Ascon "secara inheren tidak memiliki perlindungan replay, memerlukan manajemen nonce eksternal".

**3. KiviCore KiviPQC-KEM - Tidak Relevan**

Ini adalah IP key encapsulation ML-KEM, berfungsi sebagai **standalone hardware acceleration engine** untuk KeyGen, Encaps, Decaps, sama sekali tidak terkait dengan keamanan batas ingress.

**4. Tiempo TESIC - Terlalu Besar**

TESIC adalah **Secure Element IP** dengan sertifikasi CC EAL5+, berisi CPU, MPU, akselerator crypto, sensor keamanan, active shield, dsb.. Ini adalah produk tingkat SoC, jauh melampaui kebutuhan Anda akan "blok kecil dan hemat area".

---

## Mengapa Klaim Tersebut pada Dasarnya Valid

Kondisi inti klaim Anda adalah: **"hemat area" + "autentikasi + kesegaran + commit atomik" + "tepat di batas ingress"**.

Keempat kondisi ini secara simultan memang sangat jarang ditemukan di IP komersial:

1. **IP komersial cenderung modular**: CAST menjual Ascon, CAST menjual ML-KEM, tetapi tidak akan mengemas MAC + counter + gerbang commit menjadi satu produk. Integrator harus menggabungkannya sendiri.

2. **Mekanisme perlindungan batas ingress biasanya diselesaikan di tingkat protokol**: MACsec mendefinisikan perlindungan replay (menggunakan jendela PN), tetapi itu adalah **standar protokol**, bukan fitur produk dari inti IP tertentu.

3. **Titik persilangan hemat area + terintegrasi jarang dikomersialkan**: Desain tingkat Tiny Tapeout (<0.1 mm²) biasanya berasal dari akademik atau kompetisi, jarang dijadikan produk oleh vendor IP seperti CAST/KiviCore.

---

## Saran Revisi Rumusan

Klaim saat ini:
> "Belum ada blok hemat area yang menggabungkan autentikasi, kesegaran, dan commit atomik fail-closed tepat di batas ingress."

**Saran revisi:**
> "Dalam literatur dan katalog IP yang kami tinjau, kami belum menemukan blok IP komersial hemat area yang secara terintegrasi menggabungkan ketiga fungsi ini di batas ingress. IP yang tersedia umumnya berupa akselerator kriptografi tunggal (MAC, AEAD, KEM) yang memerlukan integrasi manual untuk mencapai sifat yang sama."

**Poin perubahan kunci:**
- Tambahkan "Dalam literatur dan katalog IP yang kami tinjau" -> batasi cakupan, hindari absolutisme
- Tambahkan "komersial" -> perjelas IP komersial, kecualikan prototipe akademik
- Tambahkan "yang memerlukan integrasi manual" -> perjelas perbedaannya adalah tingkat integrasi, bukan keberadaan fungsi

---

## Cara Menggunakan Poin Ini di Proposal

**Jangan jadikan ini sebagai selling point inti**, tetapi sebagai **diferensiasi latar belakang**:

> "IP kriptografi yang tersedia saat ini adalah akselerator tunggal. Untuk mendapatkan autentikasi, kesegaran, dan commit fail-closed, integrator harus merancang sendiri logika koordinasi antar-blok. TRI-ARGA menyediakan ketiganya dalam satu inti yang sudah diverifikasi secara formal, sehingga integrator dapat langsung menyisipkannya di batas ingress tanpa perlu merancang FSM koordinasi sendiri."

**Keuntungan perumusan ini:**
- Tidak menyangkal keberadaan IP yang ada (aman)
- Menekankan nilai Anda adalah **integrasi + verifikasi**, bukan "menciptakan fungsi baru" (jujur)
- Sesuai dengan konteks hackathon: Anda tidak membuat AES baru, Anda membuat **koordinator batas ingress**

---

## Ringkasan Satu Kalimat

**Klaim "belum ditemukan" pada dasarnya benar, tetapi perlu dibatasi menjadi "belum ditemukan di IP komersial sebagai blok batas ingress yang terintegrasi dan hemat area".** KORD SCU adalah preseden yang paling mendekati, tetapi merupakan prototipe penelitian tingkat AES-GCM, bukan produk komersial pada level SIMON32/64 Anda. Perhalus rumusannya, poin ini akan berubah dari "klaim yang mungkin dipertanyakan" menjadi "positioning diferensiasi yang wajar".
