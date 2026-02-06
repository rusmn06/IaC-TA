# 1. Instance Template
# "Instance Template: Blueprint konfigurasi VM menggunakan Machine Type e2-micro" [cite: 319]
resource "google_compute_instance_template" "web_template" {
  name_prefix  = "web-server-template-"
  machine_type = "e2-micro"
  region       = "us-central1"

  # Konfigurasi Boot Disk (Debian 11)
  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  # Konfigurasi Jaringan
  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet_web.id
    
    # Access config agar VM mendapat IP Publik (untuk download Nginx)
    access_config {}
  }

  # Tags Firewall (Note*: Harus sama dengan firewall rule di Network Layer)
  tags = ["web-server"]

  # Startup Script
  # "Skrip Bash... menginstal Nginx... menampilkan $HOSTNAME"
  metadata_startup_script = <<-EOF
    #! /bin/bash
    apt-get update
    apt-get install -y nginx
    
    # Mengambil Hostname VM dari Metadata Server Google
    vm_hostname=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/hostname)
    
    # Membuat halaman index custom untuk memvisualisasikan Load Balancing
    echo "<h1>Web Server: $vm_hostname</h1>" > /var/www/html/index.html
    
    systemctl restart nginx
  EOF

  # Siklus hidup: Buat template baru dulu sebelum menghapus yang lama (mencegah error saat update)
  lifecycle {
    create_before_destroy = true
  }
}

# 2. Health Check (Autohealing)
resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10 # Toleransi gagal sebelum dianggap rusak

  http_health_check {
    port = "80"
    request_path = "/"
  }
}

# 3. Managed Instance Group (MIG) - Regional
resource "google_compute_region_instance_group_manager" "web_mig" {
  name                      = "web-server-mig"
  base_instance_name        = "web-server"
  region                    = "us-central1"
  distribution_policy_zones = ["us-central1-a", "us-central1-b", "us-central1-f"] # Multi-zone 

  version {
    instance_template = google_compute_instance_template.web_template.id
  }

  # Named Port (Note*: Agar Load Balancer tahu port mana yang dituju)
  named_port {
    name = "http"
    port = 80
  }

  # Kebijakan Autohealing (Self-healing)
  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300 # Waktu 5 menit untuk startup script selesai install Nginx
  }
}

# 4. Autoscaler
# Autoscaler akan secara otomatis menambah atau mengurangi jumlah instance
resource "google_compute_region_autoscaler" "web_autoscaler" {
  name   = "web-autoscaler"
  region = "us-central1"
  target = google_compute_region_instance_group_manager.web_mig.id

  autoscaling_policy {
    max_replicas    = 5  # Batas atas jumlah server
    min_replicas    = 1  # Batas bawah
    cooldown_period = 60 # Periode pendinginan untuk mencegah flapping [cite: 168]

    # Target CPU Utilization
    # Sesuai spesifikasi: "target penggunaan CPU rata-rata sebesar 60%" 
    cpu_utilization {
      target = 0.6
    }
  }
}