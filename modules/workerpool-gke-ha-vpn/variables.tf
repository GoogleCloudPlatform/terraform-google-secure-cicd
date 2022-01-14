/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "vpn_router_name_prefix" {
  type        = string
  description = "Prefix for HA VPN router names"
  default     = ""
}

variable "location" {
  type        = string
  description = "Region for Cloud Build worker pool"
  default     = "us-central1"
}

variable "project_id" {
  type        = string
  description = "Project ID for Cloud Build"
}

variable "gke_project" {
  type        = string
  description = "Project ID of GKE VPC and cluster"
}

variable "gke_network" {
  type        = string
  description = "Name of GKE VPC"
}

variable "gke_location" {
  type        = string
  description = "Region of GKE subnet & cluster"
}

variable "gke_control_plane_cidrs" {
  type        = map(string)
  description = "map of GKE control plane CIDRs to name"
}

variable "workerpool_network" {
  type        = string
  description = "Self link for Cloud Build VPC"
}

variable "workerpool_range" {
  type        = string
  description = "Address range of Cloud Build Workerpool"
}

variable "gateway_1_asn" {
  type        = number
  description = "ASN for HA VPN gateway #1. You can use any private ASN (64512 through 65534, 4200000000 through 4294967294) that you are not using elsewhere in your network"
  default     = 65001
}

variable "gateway_2_asn" {
  type        = number
  description = "ASN for HA VPN gateway #2. You can use any private ASN (64512 through 65534, 4200000000 through 4294967294) that you are not using elsewhere in your network"
  default     = 65002
}

variable "bgp_range_1" {
  type        = string
  description = "BGP range for HA VPN tunnel 1"
  default     = "169.254.1.0/30"
}

variable "bgp_range_2" {
  type        = string
  description = "BGP range for HA VPN tunnel 1"
  default     = "169.254.2.0/30"
}
