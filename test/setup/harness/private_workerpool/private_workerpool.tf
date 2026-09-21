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

module "private_workerpool" {
  source                    = "../../modules/private_workerpool"
  network_name              = "priv-workerpool"
  workerpool_machine_type   = var.workerpool_machine_type
  workpool_region           = var.workpool_region
  project_id_standalone     = var.project_id_standalone
  org_id                    = var.org_id
  billing_account           = var.billing_account
  folder_id                 = var.folder_id
  project_number_standalone = var.project_number_standalone
}
