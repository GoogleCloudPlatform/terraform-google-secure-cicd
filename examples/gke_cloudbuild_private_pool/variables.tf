variable "project_id" {
  type        = string
  description = "Project ID for CICD Pipeline Project"
}

variable "primary_location" {
  type        = string
  description = "Default region for resources"
}

variable "deploy_branch_clusters" {
  type = map(object({
    cluster               = string
    network               = string
    project_id            = string
    location              = string
    required_attestations = list(string)
    env_attestation       = string
    next_env              = string
  }))
  description = "mapping of branch names to cluster deployments"
  default     = {}
}