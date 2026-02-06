# 1. VPC (Virtual Private Cloud)
resource "google_compute_network" "vpc_network" {
  name                    = "vpc-ta-iac"
  auto_create_subnetworks = false
  mtu                     = 1460
}

# 2. Subnet
resource "google_compute_subnetwork" "subnet_web" {
  name          = "subnet-web-us-central1"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id
}

# 3. Firewall Rule: Health Check
resource "google_compute_firewall" "allow_lb_health_check" {
  name    = "allow-lb-health-check"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Rentang IP Google Cloud Load Balancer untuk memeriksa kesehatan server
  source_ranges = [
    "130.211.0.0/22", 
    "35.191.0.0/16"
  ]

  # Target tags memastikan aturan ini hanya berlaku untuk instance web server
  target_tags = ["web-server"]
}

# 4. Firewall Rule: HTTP Traffic
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Mengizinkan akses (internet)
  source_ranges = ["0.0.0.0/0"]
  
  target_tags = ["web-server"]
}

# Firewall Rule: SSH via IAP / Opsional
resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "allow-ssh-iap"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Rentang IP Identity-Aware Proxy (IAP) Google
  source_ranges = ["35.235.240.0/20"]
  
  target_tags = ["web-server"]
}