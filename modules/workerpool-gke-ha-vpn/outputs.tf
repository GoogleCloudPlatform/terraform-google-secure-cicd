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

output "vpn_gateway_cloudbuild" {
  value = module.vpn_ha_1.name
}

output "vpn_gateway_gke" {
  value = module.vpn_ha_2.name
}

output "vpn_tunnel_cloudbuild_names" {
  value = module.vpn_ha_1.tunnel_names
}

output "vpn_tunnel_gke_names" {
  value = module.vpn_ha_2.tunnel_names
}

output "vpn_router_cloudbuild_names" {
  value = module.vpn_ha_1.router_names
}

output "vpn_router_gke_names" {
  value = module.vpn_ha_2.router_names
}