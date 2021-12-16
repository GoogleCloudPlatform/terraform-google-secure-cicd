module "cloudbuild_private_pool" {
  source = "../../modules/gke-cloudbuild-private-pool"

  project_id             = var.project_id
  location               = var.primary_location
  deploy_branch_clusters = var.deploy_branch_clusters
}
