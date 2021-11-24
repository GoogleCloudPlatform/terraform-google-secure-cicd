variable "project_id" {
  type        = string
  description = "Project ID for Cloud Build Private Pool VPC"
}

variable "private_pool_vpc_name" {
  type        = string
  description = "Set the name of the private pool VPC"
  default     = "cloudbuild-private-pool-vpc"
}
