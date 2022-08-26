variable "project_id" {
    type = string
    description = "Project ID in which all resources will be deployed"
}

variable "region" {
    type        = string
    description = "Location in which all regional resources will be deployed"
}

variable "app_name" {
    type        = string
    description = "Name of intended deployed application; to be used as a prefix for certain resources"
}

variable "env1_name" {
    type        = string
    description = "Name of environment 1"
    default     = "dev"
}

variable "env2_name" {
    type        = string
    description = "Name of environment 2"
    default     = "qa"
}

variable "env3_name" {
    type        = string
    description = "Name of environment 3"
    default     = "prod"
}