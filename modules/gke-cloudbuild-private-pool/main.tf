# (https://cloud.google.com/architecture/accessing-private-gke-clusters-with-cloud-build-private-pools#creating_two_networks_in_your_own_project)
module "private-pool-vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 3.2.0"
  project_id   = var.project_id
  network_name = var.private_pool_vpc_name
  mtu          = 1460

  subnets = []
}

