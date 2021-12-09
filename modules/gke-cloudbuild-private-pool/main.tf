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
  project                 = var.project_id
  auto_create_subnetworks = false
  depends_on              = [google_project_service.servicenetworking]
}

resource "google_compute_global_address" "worker_range" {
  name          = "worker-pool-range"
  project       = var.project_id
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
  project  = var.project_id
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

locals {
  gke_networks = distinct([
    for env in var.deploy_branch_clusters : {
      network    = env.network
      location   = env.location
      project_id = env.project_id
    }
  ])
}

# HA VPN
module "vpn_ha-1" {
  count = length(local.gke_networks)

  source     = "terraform-google-modules/vpn/google//modules/vpn_ha"
  version    = "~> 1.3.0"
  project_id = var.project_id
  region     = var.location
  network    = google_compute_network.private_pool_vpc.self_link
  name       = "cloudbuild-to-${local.gke_networks[count.index].network}"
  peer_gcp_gateway = "https://compute.googleapis.com/compute/v1/projects/${local.gke_networks[count.index].project_id}/regions/${local.gke_networks[count.index].location}/vpnGateways/${local.gke_networks[count.index].network}-to-cloudbuild"
  #peer_gcp_gateway = module.vpn_ha-2[count.index].self_link
  router_asn = 65001+(count.index*2)
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.${1+(count.index*2)}.2"
        asn     = 65002+(count.index*2)
      }
      bgp_peer_options  = null
      bgp_session_range = "169.254.${1+(count.index*2)}.1/30"
      ike_version       = 2
      vpn_gateway_interface = 0
      peer_external_gateway_interface = null
      shared_secret     = ""
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.${2+(count.index*2)}.2"
        asn     = 65002+(count.index*2)
      }
      bgp_peer_options  = null
      bgp_session_range = "169.254.${2+(count.index*2)}.1/30"
      ike_version       = 2
      vpn_gateway_interface = 1
      peer_external_gateway_interface = null
      shared_secret     = ""
    }
  }
}

module "vpn_ha-2" {
  count = length(local.gke_networks)

  source     = "terraform-google-modules/vpn/google//modules/vpn_ha"
  version    = "~> 1.3.0"
  project_id = local.gke_networks[count.index].project_id
  region     = local.gke_networks[count.index].location
  network    = local.gke_networks[count.index].network 
  name       = "${local.gke_networks[count.index].network}-to-cloudbuild"
  router_asn = 65002+(count.index*2)
  peer_gcp_gateway = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/regions/${var.location}/vpnGateways/cloudbuild-to-${local.gke_networks[count.index].network}"
  #peer_gcp_gateway = module.vpn_ha-1[count.index].self_link
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.${1+(count.index*2)}.1"
        asn     = 65001+(count.index*2)
      }
      bgp_peer_options  = null
      bgp_session_range = "169.254.${1+(count.index*2)}.2/30"
      ike_version       = 2
      vpn_gateway_interface = 0
      peer_external_gateway_interface = null
      shared_secret     = module.vpn_ha-1[count.index].random_secret
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.${2+(count.index*2)}.1"
        asn     = 65001+(count.index*2)
      }
      bgp_peer_options  = null
      bgp_session_range = "169.254.${2+(count.index*2)}.2/30"
      ike_version       = 2
      vpn_gateway_interface = 1
      peer_external_gateway_interface = null
      shared_secret     = module.vpn_ha-1[count.index].random_secret
    }
  }
}