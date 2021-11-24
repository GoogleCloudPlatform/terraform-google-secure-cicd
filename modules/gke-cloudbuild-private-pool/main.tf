# module "private_pool_vpc" {
#   source       = "terraform-google-modules/network/google"
#   version      = "~> 3.2.0"
#   project_id   = var.project_id
#   network_name = var.private_pool_vpc_name
#   mtu          = 1460

#   subnets = []
# }

# Networking config
resource "google_project_service" "servicenetworking" {
  project            = var.project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_network" "private_pool_vpc" {
  name                    = var.private_pool_vpc_name
  auto_create_subnetworks = false
  depends_on              = [google_project_service.servicenetworking]
}

resource "google_compute_global_address" "worker_range" {
  name          = "worker-pool-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_pool_vpc.id
}

resource "google_service_networking_connection" "worker_pool_connection" {
  network                 = google_compute_network.private_pool_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.worker_range.name]
  depends_on              = [google_project_service.servicenetworking]
}

# Cloud Build Worker Pool
resource "google_cloudbuild_worker_pool" "pool" {
  name     = var.worker_pool_name
  location = var.location
  worker_config {
    disk_size_gb = 100
    machine_type = var.machine_type
    no_external_ip = false
  }
  network_config {
    peered_network = google_compute_network.private_pool_vpc.id
  }
  depends_on = [google_service_networking_connection.worker_pool_connection]
}

data "google_container_cluster" "gke_cluster" {
    for_each = var.deploy_branch_clusters
    project  = each.value.project_id
    name     = each.value.cluster
    location = each.value.location
}

# Network 1 = private pool vpc
# Network 2 = GKE VPC
# HA VPN
module "vpn_ha-1" {
  source     = "terraform-google-modules/vpn/google//modules/vpn_ha"
  version    = "~> 1.3.0"
  project_id = var.project_id
  region     = var.location
  network    = google_compute_network.private_pool_vpc.self_link
  name       = "cloudbuild-to-gke"
  peer_gcp_gateway = module.vpn_ha-2.self_link
  router_asn = 64514
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
      }
      bgp_peer_options  = null
      bgp_session_range = "169.254.1.2/30"
      ike_version       = 2
      vpn_gateway_interface = 0
      peer_external_gateway_interface = null
      shared_secret     = ""
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_peer_options  = null
      bgp_session_range = "169.254.2.2/30"
      ike_version       = 2
      vpn_gateway_interface = 1
      peer_external_gateway_interface = null
      shared_secret     = ""
    }
  }
}

module "vpn_ha-2" {
  source     = "terraform-google-modules/vpn/google//modules/vpn_ha"
  version    = "~> 1.3.0"
  project_id = var.project_id
  region     = var.location
  network    = "https://www.googleapis.com/compute/v1/projects/<PROJECT_ID>/global/networks/local-network" ## TODO: GKE network self_link
  name       = "gke-to-cloudbuild"
  router_asn = 64513
  peer_gcp_gateway = module.vpn_ha-1.self_link
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
      }
      bgp_peer_options  = null
      bgp_session_range = "169.254.1.1/30"
      ike_version       = 2
      vpn_gateway_interface = 0
      peer_external_gateway_interface = null
      shared_secret     = module.vpn_ha-1.random_secret
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64514
      }
      bgp_peer_options  = null
      bgp_session_range = "169.254.2.1/30"
      ike_version       = 2
      vpn_gateway_interface = 1
      peer_external_gateway_interface = null
      shared_secret     = module.vpn_ha-1.random_secret
    }
  }
}