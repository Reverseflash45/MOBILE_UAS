# E-Ticketing Helpdesk App

Aplikasi mobile E-Ticketing Helpdesk untuk pelaporan, monitoring, dan penyelesaian masalah IT atau layanan lainnya. Proyek ini dikembangkan untuk memenuhi spesifikasi Tugas Praktikum DIV Teknik Informatika.

## 🚀 Tech Stack
* **Frontend:** Flutter
* **State Management:** Riverpod
* **Backend & Database:** Supabase (PostgreSQL, Authentication, Realtime)
* **Architecture:** Clean Architecture

## 📂 Kelengkapan Proyek
Repositori ini memuat seluruh requirement pengumpulan tugas:
1. **Source Code:** Berada pada direktori utama (khususnya di dalam folder `lib/`).
2. **File Installer (APK):** File `app-release.apk` berukuran ~50MB tersedia di direktori root untuk instalasi langsung pada perangkat Android.
3. **Export Database:** Skema relasi database Supabase tersedia di dalam folder `database/` dalam format `.sql`.

## 🔑 Akun Testing (Dummy)
Gunakan kredensial berikut untuk menguji aplikasi berdasarkan masing-masing *role*:

**1. Admin (Pengelola Sistem)**
* Email: admin@contoh.com
* Password: 12345678

**2. Helpdesk (Petugas Support)**
* Email: helpdesk001@contoh.com
* Password: 12345678

**3. Pengguna (Pelapor Tiket)**
* Email: user@contoh.com
* Password: password123

*(Catatan untuk Penguji: Kredensial di atas sudah terintegrasi dengan Supabase Auth)*

## ✨ Fitur Utama
Sistem ini membagi fungsionalitas berdasarkan tiga aktor utama (Admin, Helpdesk, dan Pengguna):
* **Multi-Role Dashboard:** Dasbor spesifik beserta widget statistik tiket (Open, Assign, In Progress, Closed) untuk masing-masing peran.
* **Manajemen Tiket:** Pembuatan tiket baru, penugasan (*assign*), pembaruan status, penutupan tiket, dan fitur komentar/diskusi real-time.
* **Tracking & Riwayat:** Pelacakan riwayat perjalanan tiket secara komprehensif.
* **Push Notifications:** Pemberitahuan otomatis (lokal) saat terdapat pembaruan status pada tiket menggunakan Supabase Realtime & Flutter Local Notifications.
* **Manajemen Pengguna:** Penambahan dan penonaktifan akun (khusus Admin).
* **Preferensi Aplikasi:** Dukungan *Dark/Light Mode* menggunakan shared_preferences.

## 🛠️ Cara Menjalankan Proyek Secara Lokal

1. Clone repositori ini:
   ```bash
   git clone [https://github.com/Reverseflash45/MOBILE_UAS.git](https://github.com/Reverseflash45/MOBILE_UAS.git)