variable "project_id" {
    type        = string
    description = "Project ID for Cloud Build Private Pool VPC"
}

variable "private_pool_vpc_name" {
    type        = string
    description = "Set the name of the private pool VPC"
    default     = "cloudbuild-private-pool-vpc"
}

variable "worker_pool_name" {
    type        = string
    description = "Name of Cloud Build Worker Pool"
    default     = "cloudbuild-private-worker-pool"
}

variable "location" {
    type        = string
    description = "Region for Cloud Build worker pool"
    default     = "us-central1"
}

variable "machine_type" {
    type        = string
    description = "Machine type for Cloud Build worker pool"
    default     = "e2-standard-4"
}

variable "deploy_branch_clusters" {
  type = map(object({
    cluster      = string
    project_id   = string
    location     = string
    attestations = list(string)
    next_env     = string
  }))
  description = "mapping of branch names to cluster deployments"
  default     = {}
}
