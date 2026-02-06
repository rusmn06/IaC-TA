# Implementasi IaC Web Server High Availability (GCP + Terraform)

*Repositori ini berisi kode Infrastructure as Code (IaC) untuk Tugas Akhir (TA) dengan judul:*

## "Implementasi Infrastructure as Code (IaC) untuk Web Server High Availability dengan Google Cloud Load Balancing dan Autoscaling Berbasis Terraform"

*Dokumen ini disusun sebagai panduan operasional untuk menjalankan kode Terraform dalam membangun infrastruktur yang tangguh (resilient) dan mampu memulihkan diri secara otomatis (self-healing).*

### Struktur Folder & File

Terraform akan membaca semua file .tf di folder ini. Berikut adalah fungsi dari masing-masing file yang telah dibuat:

- main.tf: Konfigurasi utama untuk provider Google Cloud dan pengaturan Remote Backend (GCS) guna menjamin konsistensi state.

- network.tf: Mengatur lapisan jaringan (VPC, Subnet, dan Aturan Firewall).

- compute.tf: Mengatur lapisan komputasi (Instance Template, Managed Instance Group/MIG, Health Check, dan Autoscaler).

- loadbalancer.tf: Mengatur lapisan distribusi (Global HTTP Load Balancer, Backend Service, dan Forwarding Rule).

- outputs.tf: Menyediakan informasi penting setelah proses deployment selesai, seperti IP Publik Load Balancer.

### Langkah 1: Persiapan (Prerequisites)

Sebelum mengeksekusi kode, pastikan lingkungan perizinan dan kredit sudah siap:

- GCP Account: Miliki akun Google Cloud dengan sisa kredit (Free Trial) yang cukup.

- Terraform CLI: Sudah terinstal di laptop (Minimal versi 1.5+).

- Google Cloud SDK (gcloud): Sudah terinstal untuk keperluan autentikasi.

- Siapkan satu bucket unik Google Cloud Storage sebagai remote backend untuk menyimpan status Terraform.

**Autentikasi ke Google Cloud**

Buka terminal/CMD di folder proyek ini, lalu jalankan perintah:

#### 1. Login dan Setup Proyek

```
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```
#### 2. Buat Bucket GCS untuk Remote Backend

`gcloud storage buckets create gs://nama-bucket-ta --location=us-central1`

### Langkah 2: Inisialisasi & Validasi

Jalankan perintah ini untuk menyiapkan folder kerja Terraform:

#### Mengunduh provider Google Cloud
`terraform init`

#### Memastikan tidak ada kesalahan penulisan dalam kode
`terraform validate`


Pastikan muncul pesan: "Success! The configuration is valid."

### Langkah 3: Eksekusi Deployment

#### Simulasi (Plan), Melihat sumber daya apa saja yang akan dibuat tanpa benar-benar membuatnya di cloud.

`terraform plan`


#### Eksekusi (Apply), Membangun infrastruktur di Google Cloud.

`terraform apply`


Ketik yes saat diminta konfirmasi.

### Langkah 4: Verifikasi & Pengujian (Demo Sidang)

Setelah terraform apply selesai, ikuti langkah ini untuk verifikasi:

#### Dapatkan IP Publik, Lihat bagian Outputs di terminal atau ketik:

`terraform output load_balancer_ip`


#### Akses via Browser, Buka http://<IP_ADDRESS_OUTPUT>.

Catatan: Tunggu 5-10 menit setelah proses selesai karena Global Load Balancer memerlukan waktu untuk propagasi.

**Uji Load Balancing, Refresh halaman browser. Jika teks "Web Server: web-server-xxxx" berubah nama host-nya, berarti Load Balancer berhasil bekerja.**

Cek Konsol GCP:
Buka Compute Engine > Instance Groups untuk melihat Autoscaler dan kesehatan instans secara visual.

### Langkah 5: Pembersihan (Cleanup)

Sangat Penting! Agar tagihan/kredit GCP tidak terus berjalan, hapus semua sumber daya setelah selesai digunakan:

`terraform destroy`


Ketik yes untuk konfirmasi penghapusan total.

### Tips Troubleshooting

*Error 404/502: Biasanya karena Load Balancer belum siap sepenuhnya. Tunggu beberapa menit lagi.*

*Quota Exceeded: Jika muncul error ini, kurangi max_replicas pada file compute.tf menjadi 2 atau 3 untuk menyesuaikan batasan akun Free Tier.*