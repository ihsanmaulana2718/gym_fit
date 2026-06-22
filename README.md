# 🏋️ Gym Fit

Aplikasi manajemen gym berbasis **Flutter** dengan backend **Supabase**, dikembangkan sebagai tugas kuliah oleh **Kelompok 6** Program Studi Teknik Informatika, Universitas Pamulang. Aplikasi ini bersifat **demo** dengan fitur pembayaran simulasi tanpa uang asli.

🔗 **Repository:** [https://github.com/ihsanmaulana2718/gym_fit](https://github.com/ihsanmaulana2718/gym_fit)

---

## 📖 Tentang Aplikasi

Gym Fit adalah aplikasi mobile yang memudahkan pengelolaan operasional gym secara digital. Member dapat melihat status keanggotaan, membeli paket membership (simulasi demo), melakukan check-in kehadiran, dan mendaftar kelas. Admin dapat mengelola seluruh data member, paket membership, dan kelas yang tersedia melalui dashboard khusus.

Semua data disimpan secara _real-time_ di Supabase (PostgreSQL cloud), sehingga perubahan yang dilakukan admin langsung terasa oleh member tanpa perlu memuat ulang aplikasi secara manual.

---

## 👥 Anggota Kelompok 6

| No. | Nama |
|-----|------|
| 1 | Wisnu Saputra |
| 2 | M. Bimo Tri Nugroho |
| 3 | M. Ilham |
| 4 | M. Fahmi |
| 5 | Ragil Fadhilah |
| 6 | Ihsan Maulana |

---

## 🛠️ Tech Stack

| Teknologi | Peran |
|-----------|-------|
| **Flutter** (Dart) | Framework aplikasi mobile lintas platform |
| **Supabase** (PostgreSQL) | Backend sekaligus database cloud |
| **Supabase Auth** | Autentikasi pengguna berbasis email dan password |
| **supabase_flutter** `^2.15.0` | Library resmi Supabase untuk Flutter |
| **GitHub** | Penyimpanan dan pengelolaan kode sumber |

---

## 🏗️ Arsitektur Aplikasi

Gym Fit menggunakan arsitektur **Flutter → Supabase langsung** tanpa backend perantara. Aplikasi Flutter berkomunikasi secara langsung dengan layanan Supabase melalui library `supabase_flutter`, meliputi:

- **Supabase Auth** — untuk proses login, register, dan logout.
- **Supabase Database (PostgreSQL)** — untuk operasi CRUD semua tabel data.
- **REST API Supabase** — sebagai transport data antara aplikasi dan database.

```
┌─────────────────────┐          HTTPS          ┌──────────────────────┐
│   Aplikasi Flutter  │  ─────────────────────► │  Supabase Cloud      │
│  (Android / iOS)    │  ◄───────────────────── │  Auth + PostgreSQL   │
└─────────────────────┘                          └──────────────────────┘
```

Tidak ada server atau API buatan sendiri. Semua logika bisnis dieksekusi di sisi Flutter, dan Supabase berfungsi murni sebagai lapisan data.

---

## 👤 Role Pengguna

| Role | Hak Akses |
|------|-----------|
| **Member** | Melihat status membership aktif · Melihat daftar paket dan membeli paket (simulasi demo) · Membatalkan langganan aktif · Check-in kehadiran dan melihat riwayat kehadiran (hanya jika berlangganan) · Melihat dan mendaftar kelas (hanya jika berlangganan) |
| **Admin** | Melihat seluruh daftar pengguna, mengubah role, dan menghapus member beserta seluruh datanya · Menambah, mengedit, dan menghapus paket membership · Menambah, mengedit, menghapus kelas, serta melihat peserta dan sisa slot tiap kelas |

Role baru yang mendaftar secara default adalah **member**. Admin dapat mengubah role pengguna mana pun melalui tab Member di dashboard admin.

---

## ✨ Fitur Lengkap

### 🔐 Autentikasi

- **Register** — Pengguna baru mengisi nama lengkap, email, dan password. Akun langsung tercatat di tabel `users` dengan role `member`.
- **Login** — Autentikasi menggunakan email dan password via Supabase Auth.
- **Logout** — Sesi dihapus dan pengguna diarahkan kembali ke halaman login.
- **Routing otomatis berdasarkan role** — Setelah login, `HomeScreen` membaca kolom `role` dari tabel `users` dan mengarahkan ke `MemberDashboard` (role `member`) atau `AdminDashboard` (role `admin`) secara otomatis.

---

### 🧑 Dashboard Member

Dashboard member memiliki tiga tab navigasi di bagian bawah layar.

#### Tab 1 — 🏠 Beranda

- **Kartu Status Membership** — Menampilkan nama paket aktif dan tanggal berakhir membership. Jika belum ada membership aktif, ditampilkan teks "Belum punya membership aktif". Data diambil dengan mengurutkan berdasarkan `tanggal_berakhir` menurun lalu mengambil yang pertama, sehingga aman jika terdapat lebih dari satu baris aktif.
- **Daftar Paket Membership** — Menampilkan seluruh paket yang tersedia beserta nama, durasi (hari), dan harga dalam format Rupiah.
- **Tombol "Beli Paket"** — Setiap kartu paket memiliki tombol ini. Alur pembelian:
  1. Dialog konfirmasi muncul menampilkan nama paket, harga, dan keterangan bahwa ini **pembayaran simulasi demo**.
  2. Jika pengguna menekan **"Ya, Beli"**, tiga langkah dijalankan secara berurutan:
     - Semua membership aktif pengguna diubah statusnya menjadi `nonaktif`.
     - Satu baris membership baru dimasukkan dengan `status = 'aktif'`, `tanggal_mulai` = hari ini, dan `tanggal_berakhir` = hari ini + durasi paket (format `yyyy-MM-dd`).
     - Satu baris transaksi dimasukkan ke tabel `payments` dengan `jumlah` (bilangan bulat sesuai harga) dan `status = 'lunas'`.
  3. SnackBar hijau muncul: _"Pembayaran berhasil (demo), membership aktif"_.
  4. Kartu Status Membership langsung diperbarui menampilkan paket yang baru dibeli.
  5. Jika terjadi kesalahan, ditampilkan SnackBar merah dengan pesan error.
- **Tombol "Batalkan Langganan"** — Jika member sedang berlangganan, kartu Status Membership menampilkan tombol merah ini. Setelah konfirmasi dialog, seluruh membership aktif milik member diubah statusnya menjadi `nonaktif`, SnackBar _"Langganan dibatalkan"_ ditampilkan, dan tampilan kembali ke kondisi belum berlangganan. Tab Kelas dan Tab Absensi pun otomatis terkunci kembali.
- Data dapat diperbarui dengan **tarik ke bawah** (_pull-to-refresh_).

#### Tab 2 — 📋 Absensi

- **Akses terkunci tanpa membership aktif** — Tab ini hanya dapat dibuka jika member memiliki membership aktif. Jika belum berlangganan, seluruh isi tab digantikan oleh tampilan ikon gembok dan pesan _"Kamu perlu berlangganan paket dulu untuk mengakses fitur ini"_; tombol check-in maupun riwayat kehadiran tidak ditampilkan sama sekali.
- **Tombol "Check-in Sekarang"** — Mencatat satu baris kehadiran ke tabel `attendances` dengan `waktu_checkin` diisi otomatis oleh database.
- **Riwayat Kehadiran** — Daftar seluruh waktu check-in pengguna, diurutkan dari yang paling baru, dalam format `DD/MM/YYYY HH:MM`.
- Data dapat diperbarui dengan **tarik ke bawah** (_pull-to-refresh_).

#### Tab 3 — 🏃 Kelas

- **Akses terkunci tanpa membership aktif** — Tab ini hanya dapat dibuka jika member memiliki membership aktif. Jika belum berlangganan, seluruh isi tab digantikan oleh tampilan ikon gembok dan pesan _"Kamu perlu berlangganan paket dulu untuk mengakses fitur ini"_; daftar kelas dan tombol daftar tidak ditampilkan sama sekali.
- **Daftar Kelas** — Menampilkan seluruh kelas yang ada beserta nama, jadwal, dan kapasitas (terisi / kuota).
- **Tombol Daftar** — Mendaftarkan pengguna ke kelas yang dipilih. Tombol berubah tampilan menjadi:
  - **"Sudah Terdaftar"** (abu-abu, nonaktif) — jika pengguna sudah pernah mendaftar kelas ini.
  - **"Penuh"** (merah, nonaktif) — jika kuota kelas sudah habis.
- Data dapat diperbarui dengan **tarik ke bawah** (_pull-to-refresh_).

---

### 🔧 Dashboard Admin

Dashboard admin memiliki tiga tab navigasi di bagian bawah layar.

#### Tab 1 — 👥 Member

- Menampilkan daftar semua pengguna terdaftar beserta nama, email, dan role saat ini.
- Tombol **"Ubah Role"** pada setiap kartu pengguna membuka dialog untuk memilih role baru (`member` atau `admin`). Perubahan langsung tersimpan ke database.
- Ikon 🗑️ **(hapus)** pada setiap kartu pengguna untuk menghapus member secara permanen. Sebelum menghapus, ditampilkan dialog konfirmasi yang menyebutkan nama pengguna dan peringatan bahwa seluruh data terkait — `payments`, `memberships`, `attendances`, `class_bookings` — juga akan dihapus secara berurutan sebelum baris `users` dihapus. Admin tidak dapat menghapus akun dirinya sendiri; jika dicoba, ditampilkan SnackBar _"Tidak bisa menghapus akun sendiri"_.

#### Tab 2 — 🎫 Paket

- Menampilkan daftar seluruh paket membership beserta nama, durasi, dan harga.
- Tombol **"Tambah Paket"** membuka form dialog dengan validasi input untuk menambahkan paket baru (nama, durasi dalam hari, dan harga).
- Ikon ✏️ **(edit)** untuk memperbarui data paket yang sudah ada.
- Ikon 🗑️ **(hapus)** dengan dialog konfirmasi untuk menghapus paket secara permanen.

#### Tab 3 — 🏋️ Kelas

- Menampilkan daftar seluruh kelas beserta nama, jadwal, informasi **Terisi X / Y** (jumlah peserta yang sudah mendaftar / kuota), dan **Sisa Z slot** (tidak pernah negatif, minimal 0).
- Tombol **"Tambah Kelas"** membuka form dialog dengan validasi input untuk menambahkan kelas baru (nama, jadwal, dan kuota).
- Tombol **"Lihat Peserta (X)"** pada setiap kartu kelas membuka dialog yang menampilkan daftar nama member yang mendaftar kelas tersebut. Jika belum ada yang mendaftar, ditampilkan teks _"Belum ada peserta"_.
- Ikon ✏️ **(edit)** untuk memperbarui data kelas, termasuk menambah atau mengurangi kuota slot.
- Ikon 🗑️ **(hapus)** dengan dialog konfirmasi untuk menghapus kelas secara permanen.

---

## 🗄️ Struktur Database Supabase

| Tabel | Kolom Utama |
|-------|-------------|
| `users` | `id` (UUID, FK ke auth.users) · `nama` · `email` · `role` (`member` / `admin`) |
| `membership_plans` | `id` (UUID) · `nama` · `durasi_hari` (integer) · `harga` (integer) |
| `memberships` | `id` (UUID) · `user_id` (FK users) · `plan_id` (FK membership_plans) · `tanggal_mulai` (date) · `tanggal_berakhir` (date) · `status` (`aktif` / `nonaktif`) |
| `attendances` | `id` (UUID) · `user_id` (FK users) · `waktu_checkin` (timestamptz, default `now()`) |
| `classes` | `id` (UUID) · `nama` · `jadwal` · `kuota` (integer) |
| `class_bookings` | `id` (UUID) · `class_id` (FK classes) · `user_id` (FK users) |
| `payments` | `id` (UUID) · `user_id` (FK users) · `plan_id` (FK membership_plans) · `jumlah` (integer) · `status` (`lunas`) |

---

## 📁 Struktur File Utama

```
gym_fit/
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml       # Izin internet & konfigurasi app Android
├── lib/
│   ├── main.dart                     # Entry point: inisialisasi Supabase & AuthGate
│   ├── secrets.dart                  # 🔒 Kunci Supabase (TIDAK di-commit ke GitHub)
│   ├── secrets.example.dart          # Template kosong untuk kunci Supabase
│   └── screens/
│       ├── login_screen.dart         # Halaman login
│       ├── register_screen.dart      # Halaman registrasi akun baru
│       ├── home_screen.dart          # Router: cek role lalu arahkan ke dashboard
│       ├── member_dashboard.dart     # Dashboard member (Beranda, Absensi, Kelas)
│       └── admin_dashboard.dart      # Dashboard admin (Member, Paket, Kelas)
├── pubspec.yaml                      # Dependensi Flutter
└── README.md                         # Dokumentasi proyek ini
```

---

## 🚀 Cara Menjalankan (Development)

### Prasyarat

- Flutter SDK (Dart SDK `^3.12.2`)
- Android Studio atau VS Code dengan ekstensi Flutter
- Akun Supabase dan project yang sudah dikonfigurasi dengan tabel-tabel di atas

### Langkah-langkah

```bash
# 1. Clone repository
git clone https://github.com/ihsanmaulana2718/gym_fit.git
cd gym_fit

# 2. Salin template kunci Supabase
cp lib/secrets.example.dart lib/secrets.dart
```

Buka file `lib/secrets.dart` dan isi nilai berikut dengan kunci dari project Supabase Anda (Settings → API):

```dart
// lib/secrets.dart  — JANGAN di-commit ke GitHub
const String supabaseUrl = 'https://xxxx.supabase.co';
const String supabaseAnonKey = 'eyJ...';
```

```bash
# 3. Install dependensi
flutter pub get

# 4. Jalankan aplikasi (pastikan emulator atau perangkat sudah terhubung)
flutter run
```

---

## 📦 Cara Build APK (Release)

```bash
flutter build apk --release
```

File APK siap install tersedia di:

```
build/app/outputs/flutter-apk/app-release.apk
```

APK ini dapat langsung diinstal di perangkat Android dengan mengaktifkan opsi **"Instal dari sumber tidak dikenal"** di pengaturan keamanan perangkat.

---

## 📱 Panduan Penggunaan Aplikasi

### Untuk Member

1. Buka aplikasi → ketuk **"Belum punya akun? Daftar di sini"**.
2. Isi nama lengkap, email, dan password → ketuk **"Daftar"**.
3. Login dengan email dan password yang telah didaftarkan.
4. Di tab **Beranda**: lihat status membership dan daftar paket. Ketuk **"Beli Paket"** untuk membeli paket secara simulasi demo, lalu konfirmasi dengan menekan **"Ya, Beli"**. Jika ingin membatalkan langganan yang aktif, ketuk **"Batalkan Langganan"** pada kartu status membership dan konfirmasi dialog.
5. Di tab **Absensi** _(hanya tersedia setelah berlangganan)_: ketuk **"Check-in Sekarang"** setiap kali datang ke gym untuk mencatat kehadiran. Riwayat check-in ditampilkan di bawahnya.
6. Di tab **Kelas** _(hanya tersedia setelah berlangganan)_: lihat jadwal kelas yang tersedia beserta sisa kuota, lalu ketuk **"Daftar"** untuk memesan tempat.

### Untuk Admin

1. Login menggunakan akun yang sudah diubah rolenya menjadi `admin`.
2. Di tab **Member**: lihat semua pengguna terdaftar. Ketuk **"Ubah Role"** untuk mengganti role pengguna antara `member` dan `admin`. Ketuk ikon 🗑️ untuk menghapus member beserta seluruh datanya secara permanen (dengan konfirmasi terlebih dahulu).
3. Di tab **Paket**: kelola paket membership — tambah paket baru, edit nama/durasi/harga, atau hapus paket.
4. Di tab **Kelas**: kelola kelas — tambah kelas baru, edit jadwal/kuota (termasuk menambah atau mengurangi slot), atau hapus kelas. Ketuk **"Lihat Peserta"** untuk melihat daftar nama member yang mendaftar di kelas tersebut.

### Cara Membuat Akun Admin Pertama

Karena semua akun yang mendaftar otomatis menjadi `member`, akun admin pertama harus dibuat secara manual:

1. Daftarkan akun seperti biasa melalui aplikasi.
2. Buka **Supabase Dashboard** → Table Editor → tabel `users`.
3. Temukan baris dengan email yang ingin dijadikan admin → ubah kolom `role` dari `member` menjadi `admin`.
4. Login ulang dengan akun tersebut → aplikasi akan otomatis menampilkan dashboard admin.

Selanjutnya, admin dapat mengubah role akun lain langsung dari dalam aplikasi tanpa perlu mengakses Supabase Dashboard lagi.

---

## ⚠️ Catatan Penting

| Hal | Keterangan |
|-----|------------|
| 💳 **Pembayaran simulasi** | Fitur "Beli Paket" adalah **demo** tanpa transaksi uang asli. Data transaksi tercatat di tabel `payments` hanya untuk keperluan simulasi akademik. |
| 🔒 **File `secrets.dart`** | File ini berisi kunci Supabase dan **tidak ikut di-commit ke GitHub** (sudah masuk `.gitignore`). Gunakan `secrets.example.dart` sebagai template, isi kunci Anda sendiri, lalu simpan sebagai `secrets.dart`. |
| 🛡️ **Row Level Security (RLS)** | RLS Supabase **dinonaktifkan** pada semua tabel untuk mempermudah keperluan demo dan pengembangan. Pada aplikasi produksi nyata, RLS wajib diaktifkan dan dikonfigurasi dengan benar. |
| 🎓 **Tujuan** | Proyek ini murni untuk tugas kuliah Kelompok 6 Teknik Informatika Universitas Pamulang dan tidak dimaksudkan untuk digunakan dalam lingkungan produksi. |
