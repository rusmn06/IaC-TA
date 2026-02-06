# 1. Backend Service
# Backend Service: Mengelola distribusi trafik ke MIG"
resource "google_compute_backend_service" "web_backend_service" {
  name                  = "web-backend-service"
  protocol              = "HTTP"
  port_name             = "http" # Harus cocok dengan named_port di MIG
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 10

  # Menghubungkan Load Balancer ke Managed Instance Group (MIG)
  backend {
    group           = google_compute_region_instance_group_manager.web_mig.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  # Menggunakan kembali Health Check yang dibuat di compute.tf
  health_checks = [google_compute_health_check.autohealing.id]
}

# 2. URL Map
# Berfungsi sebagai polisi lalu lintas yang mengarahkan request URL ke Backend Service yang tepat.
resource "google_compute_url_map" "web_url_map" {
  name            = "web-url-map"
  default_service = google_compute_backend_service.web_backend_service.id
}

# 3. Target HTTP Proxy
# Menerima request dari Forwarding Rule dan meneruskannya ke URL Map.
resource "google_compute_target_http_proxy" "web_http_proxy" {
  name    = "web-http-proxy"
  url_map = google_compute_url_map.web_url_map.id
}

# 4. Global Forwarding Rule (Frontend)
# Bertindak sebagai gerbang tunggal (frontend) dengan IP Publik Global"
resource "google_compute_global_forwarding_rule" "web_forwarding_rule" {
  name       = "web-forwarding-rule"
  target     = google_compute_target_http_proxy.web_http_proxy.id
  port_range = "80"
  ip_protocol = "TCP"
}