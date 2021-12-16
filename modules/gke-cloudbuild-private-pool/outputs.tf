output "workerpool_id" {
  value = google_cloudbuild_worker_pool.pool.id
}

output "workerpool_range" {
  value = "${google_compute_global_address.worker_range.address}/${google_compute_global_address.worker_range.prefix_length}"
}

output "gke_networks" {
  value = local.gke_networks
}
