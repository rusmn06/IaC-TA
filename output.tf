output "load_balancer_ip" {
  description = "IP Publik Global untuk mengakses Web Server High Availability"
  value       = google_compute_global_forwarding_rule.web_forwarding_rule.ip_address
}

output "instance_group_link" {
  description = "Link ke Managed Instance Group untuk monitoring autoscaling"
  value       = google_compute_region_instance_group_manager.web_mig.self_link
}