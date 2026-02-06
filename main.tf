terraform {
  backend "gcs" {
    bucket  = "nama-bucket-ta" # Ganti dengan nama bucket GCS yang unik
    prefix  = "terraform/state"    # Folder di dalam bucket untuk menyimpan file state
  }
}