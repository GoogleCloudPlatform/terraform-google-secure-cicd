/**
 * Copyright 2026 Google LLC
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

variable "vpc_name" {
  description = "The VPC name to be concat with `vpc-` prefix."
  type        = string
}

variable "project_id" {
  description = "The project to deploy in"
  type        = string
}

variable "shared_vpc_host" {
  description = "Makes this project a Shared VPC host if 'true' (default 'false')"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "Sub-networks to be created."
  type        = any
}

variable "secondary_ranges" {
  description = "Secondary ranges that will be used in some of the subnets."
  type        = any
  default     = {}
}

variable "ingress_rules" {
  description = "List of ingress rules. This will be ignored if variable 'rules' is non-empty."
  type        = any
  default     = []
}

variable "egress_rules" {
  description = "List of egress rules. This will be ignored if variable 'rules' is non-empty"
  type        = any
  default     = []
}
